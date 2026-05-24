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
                            
                            Text(AppTexts.widgetGuideHeaderTitle)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            Text(AppTexts.widgetGuideHeaderDesc)
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
                                title: AppTexts.widgetGuideStep1Title,
                                description: AppTexts.widgetGuideStep1Desc
                            )
                            
                            stepCard(
                                number: 2,
                                icon: "plus",
                                title: AppTexts.widgetGuideStep2Title,
                                description: AppTexts.widgetGuideStep2Desc
                            )
                            
                            stepCard(
                                number: 3,
                                icon: "magnifyingglass",
                                title: AppTexts.widgetGuideStep3Title,
                                description: AppTexts.widgetGuideStep3Desc
                            )
                            
                            stepCard(
                                number: 4,
                                icon: "square.on.square.intersection.dashed",
                                title: AppTexts.widgetGuideStep4Title,
                                description: AppTexts.widgetGuideStep4Desc
                            )
                            
                            stepCard(
                                number: 5,
                                icon: "checkmark.circle.fill",
                                title: AppTexts.widgetGuideStep5Title,
                                description: AppTexts.widgetGuideStep5Desc
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // コラム・Tips (ふせん風)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text(AppTexts.widgetGuideTroubleTitle)
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                            }
                            
                            Text(AppTexts.widgetGuideTroubleDesc)
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
            .navigationTitle(AppTexts.widgetGuideTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTexts.closeBtnText) {
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
