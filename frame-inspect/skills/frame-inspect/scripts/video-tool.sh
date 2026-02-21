#!/bin/bash
# video-tool.sh - 動画のフレーム抽出・レンダリング・仕様チェックの統一ツール
#
# Usage:
#   video-tool.sh info   <video>                      動画情報を表示
#   video-tool.sh check  <video> [--spec KEY=VAL ...]  仕様チェック
#   video-tool.sh frames <video> <outdir> [--fps N]    フレーム抽出
#   video-tool.sh still  <dir> <outdir> [--frame N]    Remotion still
#   video-tool.sh render <dir> <output> [--comp ID]    Remotion render
#   video-tool.sh gif    <video> <output> [--fps N]    GIF 作成

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  info   <video>                       Show video info (resolution, fps, duration, codec)
  check  <video> [--spec KEY=VAL ...]  Verify video specs (e.g. --spec width=886 height=1920 fps=30)
  frames <video> <outdir> [--fps N]    Extract frames from video (default: 1 fps)
  still  <dir> <outdir> [--frame N]    Extract frame from Remotion project
  render <dir> <output> [--comp ID]    Render Remotion project to MP4
  gif    <video> <output> [--fps N]    Create preview GIF from video

Options:
  --fps N       Frames per second for extraction (default: 1)
  --frame N     Frame number for remotion still (default: 0)
  --comp ID     Composition ID for Remotion (default: auto-detect)
  --spec K=V    Expected spec for check command (width, height, fps, codec, max_duration, max_size_mb)
EOF
  exit 1
}

# --- info ---
cmd_info() {
  local video="$1"
  if [ ! -f "$video" ]; then
    echo -e "${RED}Error: File not found: $video${NC}" >&2
    exit 1
  fi

  echo -e "${CYAN}=== Video Info ===${NC}"
  echo -e "${CYAN}File:${NC} $video"
  echo -e "${CYAN}Size:${NC} $(du -h "$video" | cut -f1)"
  echo ""

  ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,r_frame_rate,codec_name,duration,nb_frames \
    -show_entries format=duration,size,format_name \
    -of default=noprint_wrappers=1 "$video"
}

# --- check ---
cmd_check() {
  local video="$1"
  shift
  if [ ! -f "$video" ]; then
    echo -e "${RED}Error: File not found: $video${NC}" >&2
    exit 1
  fi

  # Parse specs
  declare -A specs
  while [ $# -gt 0 ]; do
    case "$1" in
      --spec)
        shift
        local key="${1%%=*}"
        local val="${1#*=}"
        specs["$key"]="$val"
        shift
        ;;
      *) shift ;;
    esac
  done

  # Get actual values
  local actual_width actual_height actual_fps actual_codec actual_duration actual_size
  actual_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$video")
  actual_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$video")
  actual_fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$video")
  actual_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$video")
  actual_duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")
  actual_size=$(stat -f%z "$video" 2>/dev/null || stat --printf="%s" "$video" 2>/dev/null)

  # Convert fps fraction to integer
  local fps_num
  fps_num=$(echo "$actual_fps" | awk -F/ '{if ($2) printf "%d", $1/$2; else print $1}')

  local all_pass=true

  echo -e "${CYAN}=== Spec Check ===${NC}"
  echo ""

  # Check each spec
  check_val() {
    local label="$1" actual="$2" expected="$3" op="${4:-eq}"
    if [ "$op" = "eq" ]; then
      if [ "$actual" = "$expected" ]; then
        echo -e "  ${GREEN}OK${NC}  $label: $actual (expected: $expected)"
      else
        echo -e "  ${RED}NG${NC}  $label: $actual (expected: $expected)"
        all_pass=false
      fi
    elif [ "$op" = "le" ]; then
      if awk "BEGIN{exit !($actual <= $expected)}"; then
        echo -e "  ${GREEN}OK${NC}  $label: $actual (<= $expected)"
      else
        echo -e "  ${RED}NG${NC}  $label: $actual (expected <= $expected)"
        all_pass=false
      fi
    fi
  }

  [ -n "${specs[width]:-}" ]         && check_val "Width"    "$actual_width"  "${specs[width]}"
  [ -n "${specs[height]:-}" ]        && check_val "Height"   "$actual_height" "${specs[height]}"
  [ -n "${specs[fps]:-}" ]           && check_val "FPS"      "$fps_num"       "${specs[fps]}"
  [ -n "${specs[codec]:-}" ]         && check_val "Codec"    "$actual_codec"  "${specs[codec]}"
  [ -n "${specs[max_duration]:-}" ]  && check_val "Duration" "${actual_duration%.*}" "${specs[max_duration]}" "le"

  if [ -n "${specs[max_size_mb]:-}" ]; then
    local size_mb
    size_mb=$(awk "BEGIN{printf \"%.1f\", $actual_size / 1048576}")
    check_val "Size(MB)" "$size_mb" "${specs[max_size_mb]}" "le"
  fi

  # If no specs given, just print info
  if [ ${#specs[@]} -eq 0 ]; then
    echo -e "  Width:    $actual_width"
    echo -e "  Height:   $actual_height"
    echo -e "  FPS:      $fps_num ($actual_fps)"
    echo -e "  Codec:    $actual_codec"
    echo -e "  Duration: ${actual_duration}s"
    echo -e "  Size:     $(awk "BEGIN{printf \"%.1f\", $actual_size / 1048576}")MB"
    echo ""
    echo -e "${YELLOW}No --spec given. Pass --spec KEY=VAL to verify.${NC}"
  fi

  echo ""
  if $all_pass; then
    echo -e "${GREEN}Result: ALL PASSED${NC}"
  else
    echo -e "${RED}Result: FAILED${NC}"
    exit 1
  fi
}

# --- frames ---
cmd_frames() {
  local video="$1"
  local outdir="$2"
  shift 2

  local fps=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --fps) fps="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ ! -f "$video" ]; then
    echo -e "${RED}Error: File not found: $video${NC}" >&2
    exit 1
  fi

  mkdir -p "$outdir"
  echo -e "${CYAN}Extracting frames at ${fps} fps...${NC}"
  ffmpeg -i "$video" -vf "fps=$fps" "$outdir/frame_%03d.png" -y 2>&1 | tail -3

  local count
  count=$(ls "$outdir"/frame_*.png 2>/dev/null | wc -l | tr -d ' ')
  echo -e "${GREEN}Extracted $count frames to $outdir/${NC}"
  ls "$outdir"/frame_*.png
}

# --- still ---
cmd_still() {
  local dir="$1"
  local outdir="$2"
  shift 2

  local frame=0
  local comp=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --frame) frame="$2"; shift 2 ;;
      --comp) comp="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ ! -d "$dir" ]; then
    echo -e "${RED}Error: Directory not found: $dir${NC}" >&2
    exit 1
  fi

  # Auto-detect composition ID
  if [ -z "$comp" ]; then
    comp=$(grep -o 'id="[^"]*"' "$dir/src/Root.tsx" 2>/dev/null | head -1 | sed 's/id="//;s/"//')
    if [ -z "$comp" ]; then
      echo -e "${RED}Error: Cannot detect composition ID. Use --comp ID${NC}" >&2
      exit 1
    fi
    echo -e "${CYAN}Detected composition: $comp${NC}"
  fi

  # Install deps if needed
  if [ ! -d "$dir/node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    (cd "$dir" && npm install --silent)
  fi

  mkdir -p "$outdir"
  local outfile="$outdir/frame_$(printf '%03d' "$frame").png"
  echo -e "${CYAN}Extracting frame $frame...${NC}"
  (cd "$dir" && npx remotion still "$comp" "$outfile" --frame="$frame" 2>&1 | tail -3)
  echo -e "${GREEN}Output: $outfile${NC}"
}

# --- render ---
cmd_render() {
  local dir="$1"
  local output="$2"
  shift 2

  local comp=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --comp) comp="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ ! -d "$dir" ]; then
    echo -e "${RED}Error: Directory not found: $dir${NC}" >&2
    exit 1
  fi

  # Auto-detect composition ID
  if [ -z "$comp" ]; then
    comp=$(grep -o 'id="[^"]*"' "$dir/src/Root.tsx" 2>/dev/null | head -1 | sed 's/id="//;s/"//')
    if [ -z "$comp" ]; then
      echo -e "${RED}Error: Cannot detect composition ID. Use --comp ID${NC}" >&2
      exit 1
    fi
    echo -e "${CYAN}Detected composition: $comp${NC}"
  fi

  # Install deps if needed
  if [ ! -d "$dir/node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    (cd "$dir" && npm install --silent)
  fi

  echo -e "${CYAN}Rendering $comp to $output...${NC}"
  (cd "$dir" && npx remotion render "$comp" "$output" 2>&1 | tail -10)

  if [ -f "$output" ]; then
    local size
    size=$(du -h "$output" | cut -f1)
    echo -e "${GREEN}Rendered: $output ($size)${NC}"
  else
    # output might be relative to dir
    local full="$dir/$output"
    if [ -f "$full" ]; then
      local size
      size=$(du -h "$full" | cut -f1)
      echo -e "${GREEN}Rendered: $full ($size)${NC}"
    else
      echo -e "${RED}Render may have failed. Check output.${NC}" >&2
      exit 1
    fi
  fi
}

# --- gif ---
cmd_gif() {
  local video="$1"
  local output="$2"
  shift 2

  local fps=5
  while [ $# -gt 0 ]; do
    case "$1" in
      --fps) fps="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ ! -f "$video" ]; then
    echo -e "${RED}Error: File not found: $video${NC}" >&2
    exit 1
  fi

  echo -e "${CYAN}Creating GIF (${fps} fps)...${NC}"
  ffmpeg -i "$video" -vf "fps=$fps,scale=320:-1:flags=lanczos" "$output" -y 2>&1 | tail -3
  local size
  size=$(du -h "$output" | cut -f1)
  echo -e "${GREEN}Output: $output ($size)${NC}"
}

# --- main ---
if [ $# -lt 1 ]; then
  usage
fi

command="$1"
shift

case "$command" in
  info)   [ $# -lt 1 ] && usage; cmd_info "$@" ;;
  check)  [ $# -lt 1 ] && usage; cmd_check "$@" ;;
  frames) [ $# -lt 2 ] && usage; cmd_frames "$@" ;;
  still)  [ $# -lt 2 ] && usage; cmd_still "$@" ;;
  render) [ $# -lt 2 ] && usage; cmd_render "$@" ;;
  gif)    [ $# -lt 2 ] && usage; cmd_gif "$@" ;;
  *)      echo -e "${RED}Unknown command: $command${NC}"; usage ;;
esac
