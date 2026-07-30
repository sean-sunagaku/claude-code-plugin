import SwiftUI

enum MockupVariant: String, CaseIterable, Identifiable {
    case primary = "案A"
    case alternative = "案B"

    var id: Self { self }
}

enum MockupScenario: String, CaseIterable, Identifiable {
    case standard = "通常"
    case empty = "空"
    case longContent = "長文"

    var id: Self { self }
}

struct MockupGalleryView: View {
    @State private var variant: MockupVariant = .primary
    @State private var scenario: MockupScenario = .standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                controls
                Divider()
                mockup
            }
            .navigationTitle("UIモック")
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("UI案", selection: $variant) {
                ForEach(MockupVariant.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)

            Picker("状態", selection: $scenario) {
                ForEach(MockupScenario.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
    }

    @ViewBuilder
    private var mockup: some View {
        switch (variant, scenario) {
        case (_, .empty):
            ContentUnavailableView(
                "まだ項目がありません",
                systemImage: "square.stack.3d.up.slash",
                description: Text("主要アクションから最初の項目を追加できます。")
            )
        case (.primary, _):
            List {
                Label("案Aの主要コンテンツ", systemImage: "rectangle.grid.1x2")
                Text(scenario == .longContent
                     ? "長い文言や大きな文字サイズでも、情報の優先順位と主要操作が崩れないか確認します。"
                     : "具体的な利用場面が分かる内容に置き換えてください。")
            }
        case (.alternative, _):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("案Bの主要コンテンツ", systemImage: "rectangle.grid.2x2")
                        .font(.headline)
                    Text(scenario == .longContent
                         ? "比較案では一度に一つの設計判断だけを変え、どちらが目的に合うか操作して確かめます。"
                         : "案Aと同じデータと状態で比較してください。")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }
}

#Preview("Mockup Gallery") {
    MockupGalleryView()
}
