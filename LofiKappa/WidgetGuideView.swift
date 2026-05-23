import SwiftUI

struct WidgetGuideView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // アナログ手帖の背景ライティングテクスチャを適用
                TimeLightingBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー部
                        VStack(spacing: 8) {
                            Image(systemName: "square.text.square.fill")
                                .font(.system(size: 54))
                                .foregroundColor(Theme.Colors.primaryBlue)
                                .shadow(color: Theme.Colors.primaryBlue.opacity(0.2), radius: 8, x: 0, y: 4)
                                .padding(.top, 12)
                            
                            Text("ホーム画面にウィジェットを追加しよう")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            Text("カッパをホーム画面に配置して、アプリを開かずに簡単に水分を補給できるようになります。")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 16)
                        
                        HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.12))
                            .frame(width: 160)
                        
                        // ステップリスト
                        VStack(spacing: 16) {
                            stepCard(
                                number: 1,
                                icon: "touchid",
                                title: "ホーム画面を長押し",
                                description: "ホーム画面の空いている場所（アプリアイコンやウィジェットがないスペース）を、アイコンが揺れ始めるまで長押しします。"
                            )
                            
                            stepCard(
                                number: 2,
                                icon: "plus",
                                title: "「＋」ボタンをタップ",
                                description: "画面の左上（または右上）に表示される「＋」追加ボタンをタップして、ウィジェットギャラリーを開きます。"
                            )
                            
                            stepCard(
                                number: 3,
                                icon: "magnifyingglass",
                                title: "「LofiKappa」を検索",
                                description: "ウィジェットギャラリーの上部検索バーで「LofiKappa」と入力するか、アプリ一覧から見つけてタップします。"
                            )
                            
                            stepCard(
                                number: 4,
                                icon: "square.on.square.intersection.dashed",
                                title: "サイズを選んで追加",
                                description: "お好みのウィジェットサイズ（小・中）を選択し、下部の「ウィジェットを追加」ボタンをタップします。"
                            )
                            
                            stepCard(
                                number: 5,
                                icon: "checkmark.circle.fill",
                                title: "配置の完了と給水操作",
                                description: "ホーム画面にウィジェットが配置されたら、完了ボタンを押します。ウィジェット上の給水ボタンをタップするだけで、すぐに今日の記録へ反映されます！"
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // コラム・Tips (ふせん風)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("うまく同期されない時は？")
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                            }
                            
                            Text("ウィジェットの追加直後や、日付が変わったタイミングなどでデータが表示されない場合は、一度アプリを起動して水分を補給してみてください。自動的にデータが同期・更新されます。")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(18)
                        .background(Color.yellow.opacity(colorScheme == .dark ? 0.08 : 0.1))
                        .cornerRadius(16)
                        .handDrawnBorder(color: Color.yellow.opacity(0.3), cornerRadius: 16)
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("ウィジェット設定ガイド")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(Theme.Colors.primaryBlue)
                }
            }
        }
    }
    
    // ステップを表示するカード
    @ViewBuilder
    private func stepCard(number: Int, icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // ステップ番号バッジ
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryBlue)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(.white)
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(Theme.Colors.primaryBlue)
                    
                    Text(title)
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                }
                
                Text(description)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.Colors.card(for: colorScheme))
        .cornerRadius(16)
        .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.16), cornerRadius: 16)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 6, x: 0, y: 2)
    }
}
