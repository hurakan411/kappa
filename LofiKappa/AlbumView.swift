import SwiftUI
import SwiftData

struct AlbumView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \KappaCollection.dateUnlocked, order: .forward) private var kappas: [KappaCollection]
    @ObservedObject private var languageManager = LanguageManager.shared
    @Binding var selectedTab: Int
    @State private var animatedIndexLimit = -1
    
    // 重複したカッパ種を排除したユニークなリスト
    private var uniqueKappas: [KappaCollection] {
        var seenBaseIds = Set<String>()
        var result = [KappaCollection]()
        for kappa in kappas {
            let baseId = kappa.id.components(separatedBy: "_").first ?? "gamer"
            if !seenBaseIds.contains(baseId) {
                seenBaseIds.insert(baseId)
                result.append(kappa)
            }
        }
        return result
    }
    
    // 2列のグリッド用に行単位に分割したデータ
    private var kappaRows: [[(offset: Int, element: KappaCollection)]] {
        let enumerated = Array(uniqueKappas.enumerated())
        var rows = [[(offset: Int, element: KappaCollection)]]()
        for i in stride(from: 0, to: enumerated.count, by: 2) {
            var row = [(offset: Int, element: KappaCollection)]()
            row.append(enumerated[i])
            if i + 1 < enumerated.count {
                row.append(enumerated[i + 1])
            }
            rows.append(row)
        }
        return rows
    }
    
    var body: some View {
        let _ = languageManager.selectedLanguage // 言語変更を検知してコンテンツを再描画
        NavigationView {
            ZStack {
                // 手帳の背景テクスチャを統一
                TimeLightingBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // コレクション数バッジ（クラフト紙風ラベル）
                        HStack {
                            Text(AppTexts.albumCollectedKappas)
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                            Spacer()
                            Text(AppTexts.albumSpeciesCountText(uniqueKappas.count))
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
                        if uniqueKappas.isEmpty {
                            VStack(spacing: 20) {
                                Spacer(minLength: 60)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 64))
                                    .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.15))
                                Text(AppTexts.albumEmptyTitle)
                                    .font(.system(.headline, design: .rounded).bold())
                                    .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.4))
                                Text(AppTexts.albumEmptyDetail)
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
                            VStack(spacing: 20) {
                                ForEach(0..<kappaRows.count, id: \.self) { rowIndex in
                                    HStack(spacing: 16) {
                                        ForEach(kappaRows[rowIndex], id: \.element.id) { cell in
                                            let isAnimated = cell.offset <= animatedIndexLimit
                                            NavigationLink(destination: KappaDetailView(kappa: cell.element)) {
                                                KappaCard(kappa: cell.element, colorScheme: colorScheme)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .frame(maxWidth: .infinity)
                                            .offset(y: isAnimated ? 0 : -350)
                                            .scaleEffect(isAnimated ? 1.0 : 0.85)
                                            .rotationEffect(.degrees(isAnimated ? 0 : (cell.offset % 2 == 0 ? -4 : 4)))
                                            .opacity(isAnimated ? 1.0 : 0.0)
                                        }
                                        if kappaRows[rowIndex].count < 2 {
                                            Spacer()
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
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
            .onAppear {
                triggerSequentialAnimation()
            }
            .onDisappear {
                animatedIndexLimit = -1
            }
            .onChange(of: selectedTab) { newValue in
                if newValue == 1 {
                    triggerSequentialAnimation()
                } else {
                    animatedIndexLimit = -1
                }
            }
        }
    }
    
    private func triggerSequentialAnimation() {
        animatedIndexLimit = -1
        let count = uniqueKappas.count
        for index in 0..<count {
            // 各セルごとに0.12秒ずつの段階的な時差を持たせて個別にスプリングアニメーションを実行します
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 + Double(index) * 0.12) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                    animatedIndexLimit = index
                }
            }
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
        KappaData.find(by: baseId)?.numberOfStages ?? 5
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
                Text(KappaData.find(by: baseId)?.name ?? kappa.title)
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
                    
                    Text(AppTexts.albumUndiscovered)
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
    
    @State private var selectedStage: Int
    
    init(kappa: KappaCollection) {
        self.kappa = kappa
        let base = kappa.id.components(separatedBy: "_").first ?? "gamer"
        let max = KappaData.find(by: base)?.numberOfStages ?? 5
        _selectedStage = State(initialValue: max)
    }
    
    var baseId: String {
        kappa.id.components(separatedBy: "_").first ?? "gamer"
    }
    
    var maxStage: Int {
        KappaData.find(by: baseId)?.numberOfStages ?? 5
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
                VStack(spacing: 24) {
                    // スワイプ可能な画像カルーセル（背景ボックスや完了スタンプなし）
                    ZStack {
                        TabView(selection: $selectedStage) {
                            ForEach(1...maxStage, id: \.self) { stage in
                                KappaImageView(kappaId: baseId, stage: stage)
                                    .frame(width: 360, height: 360)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .tag(stage)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 380)
                    }
                    .padding(.top, 20)
                    
                    // 手書き風区切り線
                    HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.15))
                        .padding(.horizontal, 40)
                    
                    // 詳細テキスト（観察ノート、背景ボックスなし）
                    VStack(spacing: 16) {
                        // ステージ名（スワイプしたステージに応じて動的に変更）
                        Text(stageName(for: selectedStage))
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(Theme.Colors.primaryBlue)
                        
                        Text(KappaData.find(by: baseId)?.name ?? kappa.title)
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                            .multilineTextAlignment(.center)
                        
                        Text(KappaData.find(by: baseId)?.description ?? kappa.kappaDescription)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 24)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(KappaData.find(by: baseId)?.name ?? kappa.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // ステージに応じた表示名を取得するヘルパー
    private func stageName(for stage: Int) -> String {
        if baseId == "gamer" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_gamer_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_gamer_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_gamer_3", defaultValue: "Stage 3: ベビー期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_gamer_4", defaultValue: "Stage 4: ゲーマーベビー期")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_gamer_5", defaultValue: "Stage 5: ゲーマーチャイルド期")
            case 6: return LanguageManager.shared.localizedString(forKey: "stage_gamer_6", defaultValue: "Stage 6: ゲーマーアダルト期")
            default: return LanguageManager.shared.localizedString(forKey: "stage_gamer_7", defaultValue: "Stage 7: ゲーマープロ期（最終形態）")
            }
        } else if baseId == "odango" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_odango_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_odango_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_odango_3", defaultValue: "Stage 3: 幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_odango_4", defaultValue: "Stage 4: 成長期（おだんごベビー）")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_odango_5", defaultValue: "Stage 5: 成長期（おだんごチャイルド）")
            default: return LanguageManager.shared.localizedString(forKey: "stage_odango_6", defaultValue: "Stage 6: 成体期（おだんごかっぱ最終形態）")
            }
        } else if baseId == "kingyo" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_kingyo_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_kingyo_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_kingyo_3", defaultValue: "Stage 3: 幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_kingyo_4", defaultValue: "Stage 4: 成長期（金魚ベビー）")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_kingyo_5", defaultValue: "Stage 5: 成長期（金魚チャイルド）")
            default: return LanguageManager.shared.localizedString(forKey: "stage_kingyo_6", defaultValue: "Stage 6: 成体期（金魚カッパ最終形態）")
            }
        } else {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_default_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_default_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_default_3", defaultValue: "Stage 3: 幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_default_4", defaultValue: "Stage 4: 成長期")
            default: return LanguageManager.shared.localizedString(forKey: "stage_default_5", defaultValue: "Stage 5: 成体期（最終形態）")
            }
        }
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

