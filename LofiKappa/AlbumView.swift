import SwiftUI
import SwiftData

struct AlbumView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \KappaCollection.dateUnlocked, order: .forward) private var kappas: [KappaCollection]
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 手帳の背景テクスチャを統一
                TimeLightingBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // コレクション数バッジ（クラフト紙風ラベル）
                        HStack {
                            Text("収集したかっぱ")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                            Spacer()
                            Text("\(kappas.count) 種")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Theme.Colors.primaryBlue)
                                .cornerRadius(20)
                                .handDrawnBorder(color: .white.opacity(0.3), cornerRadius: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // コレクションシェルフ風グリッド
                        if kappas.isEmpty {
                            VStack(spacing: 20) {
                                Spacer(minLength: 60)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 64))
                                    .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.15))
                                Text("まだかっぱを発見していません。")
                                    .font(.system(.headline, design: .rounded).bold())
                                    .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.4))
                                Text("ホーム画面で水分を記録し、お皿を水で満たしてかっぱを完全に成長させると、ここに思い出として登録されます。")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.3))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                                    .padding(.horizontal, 40)
                                Spacer(minLength: 60)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(kappas, id: \.id) { collection in
                                    NavigationLink(destination: KappaDetailView(kappa: collection)) {
                                        KappaCard(kappa: collection, colorScheme: colorScheme)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle(AppTexts.albumTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - KappaCard

struct KappaCard: View {
    let kappa: KappaCollection
    let colorScheme: ColorScheme
    
    var baseId: String {
        kappa.id.components(separatedBy: "_").first ?? "gamer"
    }
    
    var maxStage: Int {
        baseId == "gamer" ? 7 : 5
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // イラストエリア（スクラップ写真風）
            ZStack {
                LinearGradient(
                    colors: [Theme.Colors.lightBlue.opacity(0.18), Theme.Colors.primaryBlue.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                KappaImageView(kappaId: baseId, stage: maxStage)
                    .padding(14)
            }
            .frame(height: 165)
            .background(Theme.Colors.card(for: colorScheme))
            
            HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.12))
            
            // 名前エリア
            HStack {
                Text(kappa.title)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Theme.Colors.card(for: colorScheme))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.2), cornerRadius: 16)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - KappaCardDummy (未解放のシルエットカード)

struct KappaCardDummy: View {
    let kappa: KappaData
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.Colors.card(for: colorScheme).opacity(0.4)
                
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.12))
                    
                    Text("未発見")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.2))
                }
            }
            .frame(height: 165)
            
            HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.08))
            
            HStack {
                Text("???")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.15))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Theme.Colors.card(for: colorScheme).opacity(0.4))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.text(for: colorScheme).opacity(0.08), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
        )
    }
}

// MARK: - KappaDetailView

struct KappaDetailView: View {
    let kappa: KappaCollection
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var baseId: String {
        kappa.id.components(separatedBy: "_").first ?? "gamer"
    }
    
    var maxStage: Int {
        baseId == "gamer" ? 7 : 5
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: kappa.dateUnlocked)
    }
    
    var body: some View {
        ZStack {
            TimeLightingBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    // メインの観察スケッチボード
                    VStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            // スケッチ写真風コンテナ
                            ZStack {
                                LinearGradient(
                                    colors: [Theme.Colors.lightBlue.opacity(0.25), Theme.Colors.primaryBlue.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(height: 240)
                                
                                KappaImageView(kappaId: baseId, stage: maxStage)
                                    .frame(width: 190, height: 190)
                                    .padding(.vertical, 24)
                            }
                            
                            // 完了インクスタンプ
                            HatchedStamp(dateStr: formattedDate)
                                .padding(16)
                                .offset(x: 10, y: -10)
                        }
                        
                        HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.15))
                        
                        // 詳細テキスト（観察ノート）
                        VStack(spacing: 20) {
                            Text(kappa.title)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            Text(kappa.kappaDescription)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .padding(.horizontal, 10)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(24)
                        .background(Theme.Colors.card(for: colorScheme))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.25), cornerRadius: 24)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 14, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(kappa.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Decoration Helpers

struct HatchedStamp: View {
    let dateStr: String
    var body: some View {
        VStack(spacing: 3) {
            Text("孵化完了")
                .font(.system(size: 9, weight: .bold, design: .rounded))
            Text(dateStr)
                .font(.system(size: 8, design: .rounded))
        }
        .foregroundColor(Color(hex: "F87171").opacity(0.8)) // かすれた朱色インク
        .padding(8)
        .background(
            Circle()
                .stroke(Color(hex: "F87171").opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
        )
        .rotationEffect(.degrees(15))
    }
}

// MARK: - RoundedCorner helper

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

