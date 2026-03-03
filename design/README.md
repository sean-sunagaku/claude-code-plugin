# Design

UI/UXデザイン・ロゴ作成・デザインバリエーション生成

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **ui-review** [Beta] | `/ui-review` | 5つの専門エージェント（UXデザイナー・ビジュアルデザイナー・アクセシビリティ専門家・モバイルUI専門家・コピーデザイナー）がチームでUIを添削・改善するスキル。Pencil(.pen)で画面デザインを作成・修正しながらリアルタイムで議論する |
| **logo-design** [Beta] | `/logo-design` | 6つの専門エージェント（ブランド戦略・ロゴデザイン・カラー/タイポ・トレンド調査・競合分析・コンテキスト管理）がチームで相互フィードバックしながらロゴを作成・議論するスキル。Pencil(.pen)で複数バリエーションを作成しSVGアイコンも出力する |
| **ui-variations** [Beta] | `/ui-variations` | 5つの異なるUIデザインバリエーションを並列エージェントチームで生成し、Pencilで比較するスキル。各デザイナーがMCP経由でPencilに直接構築。3人チーム x5の並列実行。 |
| **pencil-replicator** | `/pencil-replicator` |  Chrome で表示中の Web 画面を Pencil (.pen) ファイルに高精度で再現する Agent Team スキル。 3つの専門エージェント（screen-analyzer, design-builder, quality-reviewer）が 分析→構築→品質検証のサイクルを回し、忠実な画面再現を実現する。 Use when: Pencil で再現して、画面を Pencil に写して、Chrome を Pencil にコピー、 pencil-replicate、デザインをキャプチャ、UI を Pencil に |

### ui-review [Beta]

5つの専門エージェント（UXデザイナー・ビジュアルデザイナー・アクセシビリティ専門家・モバイルUI専門家・コピーデザイナー）がチームでUIを添削・改善するスキル。Pencil(.pen)で画面デザインを作成・修正しながらリアルタイムで議論する

5つの専門エージェントが Pencil でデザインを見ながら議論し、UIを添削・改善する。

```
/ui-review
```

### logo-design [Beta]

6つの専門エージェント（ブランド戦略・ロゴデザイン・カラー/タイポ・トレンド調査・競合分析・コンテキスト管理）がチームで相互フィードバックしながらロゴを作成・議論するスキル。Pencil(.pen)で複数バリエーションを作成しSVGアイコンも出力する

6つの専門エージェントがチームで相互フィードバックしながら議論し、Pencil でロゴを作成する。

```
/logo-design
```

### ui-variations [Beta]

5つの異なるUIデザインバリエーションを並列エージェントチームで生成し、Pencilで比較するスキル。各デザイナーがMCP経由でPencilに直接構築。3人チーム x5の並列実行。

5つの異なるスタイル方向で同一画面のUIバリエーションを**並列生成**し、Pencilで横並び比較する。

```
/ui-variations
```

### pencil-replicator

 Chrome で表示中の Web 画面を Pencil (.pen) ファイルに高精度で再現する Agent Team スキル。 3つの専門エージェント（screen-analyzer, design-builder, quality-reviewer）が 分析→構築→品質検証のサイクルを回し、忠実な画面再現を実現する。 Use when: Pencil で再現して、画面を Pencil に写して、Chrome を Pencil にコピー、 pencil-replicate、デザインをキャプチャ、UI を Pencil に

Chrome で表示中の Web 画面を Pencil (.pen) ファイルに高精度で再現する Agent Team スキル。

```
/pencil-replicator
```

---

[< Back to top](../README.md)
