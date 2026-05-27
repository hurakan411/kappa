import SwiftUI
import SwiftData

struct AlbumView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \KappaCollection.dateUnlocked, order: .forward) private var kappas: [KappaCollection]
    @ObservedObject private var languageManager = LanguageManager.shared
    @Binding var selectedTab: Int
    @State private var animatedIndexLimit = -1
    
    enum AlbumViewMode: String, CaseIterable {
        case grid
        case honeycomb
    }
    
    @State private var viewMode: AlbumViewMode = .grid
    @State private var selectedKappa: KappaCollection? = nil
    @State private var zoomScale: CGFloat = 0.95
    @State private var gestureZoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var gestureDragOffset: CGSize = .zero
    
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
    
    // インデックスに応じた中心スパイラルハニカムピクセルオフセット座標の計算
    private func honeycombOffset(for index: Int) -> CGPoint {
        // スパイラル順のハニカム相対グリッド座標 (col, row)
        // フラットトップ（上が平ら）の六角形用レイアウト。中心(0,0)からRing 1、Ring 2...と螺旋状に並べる
        let gridCoordinates: [(col: Double, row: Double)] = [
            (0.0, 0.0),    // 中心 (Ring 0)
            
            // Ring 1 (6個)
            (0.0, -1.0),   // 上
            (0.866, -0.5),  // 右上
            (0.866, 0.5),   // 右下
            (0.0, 1.0),    // 下
            (-0.866, 0.5),  // 左下
            (-0.866, -0.5), // 左上
            
            // Ring 2 (12個)
            (0.0, -2.0),   // 上外
            (0.866, -1.5),
            (1.732, -1.0),  // 右上外
            (1.732, 0.0),   // 右外
            (1.732, 1.0),   // 右下外
            (0.866, 1.5),
            (0.0, 2.0),    // 下外
            (-0.866, 1.5),
            (-1.732, 1.0),  // 左下外
            (-1.732, 0.0),  // 左外
            (-1.732, -1.0), // 左上外
            (-0.866, -1.5),
            
            // Ring 3 (18個) - 将来の追加・あふれ防止のために追加
            (0.0, -3.0),
            (0.866, -2.5),
            (1.732, -2.0),
            (2.598, -1.5),
            (2.598, -0.5),
            (2.598, 0.5),
            (2.598, 1.5),
            (1.732, 2.0),
            (0.866, 2.5),
            (0.0, 3.0),
            (-0.866, 2.5),
            (-1.732, 2.0),
            (-2.598, 1.5),
            (-2.598, 0.5),
            (-2.598, -0.5),
            (-2.598, -1.5),
            (-1.732, -2.0),
            (-0.866, -2.5)
        ]
        
        guard index < gridCoordinates.count else { return .zero }
        let coord = gridCoordinates[index]
        
        // フラットトップ六角形の中心間距離（96pt）をステップサイズとして設定
        let stepX: CGFloat = 96.0
        let stepY: CGFloat = 96.0
        
        let px = CGFloat(coord.col) * stepX
        let py = CGFloat(coord.row) * stepY
        return CGPoint(x: px, y: py)
    }
    
    private var panAndZoomGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                gestureDragOffset = value.translation
            }
            .onEnded { value in
                let newWidth = dragOffset.width + value.translation.width
                let newHeight = dragOffset.height + value.translation.height
                
                // 動かせる可動域を横±260、縦±300に設定して、見失わないようにします
                let limitX: CGFloat = 260.0
                let limitY: CGFloat = 300.0
                // 確定値の更新とジェスチャ一時値のリセットを同一アニメーション内で行い、
                // スナップバック（一瞬元の縮尺に戻る現象）を完全に防止します。
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    dragOffset = CGSize(
                        width: max(-limitX, min(newWidth, limitX)),
                        height: max(-limitY, min(newHeight, limitY))
                    )
                    gestureDragOffset = .zero
                }
            }
            .simultaneously(with:
                MagnifyGesture()
                    .onChanged { value in
                        gestureZoomScale = value.magnification
                    }
                    .onEnded { value in
                        // 確定値の更新とジェスチャ一時値のリセットを同一アニメーション内で行い、
                        // スナップバック（一瞬元の縮尺に戻る現象）を完全に防止します。
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            zoomScale = max(0.55, min(zoomScale * value.magnification, 1.55))
                            gestureZoomScale = 1.0
                        }
                    }
            )
    }
    
    var body: some View {
        let _ = languageManager.selectedLanguage // 言語変更を検知してコンテンツを再描画
        NavigationView {
            ZStack {
                // 手帳の背景テクスチャを統一
                TimeLightingBackground()
                
                // ハニカムモード用のプログラム的遷移用の非表示NavigationLink
                NavigationLink(
                    destination: Group {
                        if let selected = selectedKappa {
                            KappaDetailView(kappa: selected)
                        }
                    },
                    isActive: Binding(
                        get: { selectedKappa != nil },
                        set: { if !$0 { selectedKappa = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
                
                VStack(spacing: 0) {
                    // ヘッダー（手書き風セクション）
                    VStack(spacing: 4) {
                        Text(AppTexts.albumTitle)
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                            .padding(.top, 16)
                        
                        HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.15))
                            .frame(width: 120)
                    }
                    .padding(.bottom, 10)
                    
                    if uniqueKappas.isEmpty {
                        ScrollView {
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
                        }
                    } else {
                        if viewMode == .grid {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    // コレクション数バッジ ＆ ビュー切り替えセレクター
                                    HStack(alignment: .center, spacing: 12) {
                                        Text(AppTexts.albumCollectedKappas)
                                            .font(.system(.subheadline, design: .rounded).bold())
                                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                                        
                                        Text(AppTexts.albumSpeciesCountText(uniqueKappas.count))
                                            .font(.system(.caption, design: .rounded).bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Theme.Colors.primaryBlue)
                                            .cornerRadius(20)
                                            .handDrawnBorder(color: .white.opacity(0.3), cornerRadius: 20)
                                        
                                        Spacer()
                                        
                                        // ビューモード切り替えセレクター
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                    viewMode = .grid
                                                }
                                                triggerSequentialAnimation()
                                            }) {
                                                Image(systemName: "square.grid.2x2.fill")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(viewMode == .grid ? .white : Theme.Colors.primaryBlue)
                                                    .padding(6)
                                                    .background(viewMode == .grid ? Theme.Colors.primaryBlue : Color.clear)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                    viewMode = .honeycomb
                                                }
                                                triggerSequentialAnimation()
                                            }) {
                                                Image(systemName: "hexagon.fill")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(viewMode == .honeycomb ? .white : Theme.Colors.primaryBlue)
                                                    .padding(6)
                                                    .background(viewMode == .honeycomb ? Theme.Colors.primaryBlue : Color.clear)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(4)
                                        .background(Theme.Colors.card(for: colorScheme))
                                        .cornerRadius(20)
                                        .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.12), cornerRadius: 20)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                    
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
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                        } else {
                            // ハニカムモード（ドラッグ＆ズーム対応のためScrollViewなし）
                            VStack(alignment: .leading, spacing: 10) {
                                // コレクション数バッジ ＆ ビュー切り替えセレクター
                                HStack(alignment: .center, spacing: 12) {
                                    Text(AppTexts.albumCollectedKappas)
                                        .font(.system(.subheadline, design: .rounded).bold())
                                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                                    
                                    Text(AppTexts.albumSpeciesCountText(uniqueKappas.count))
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Theme.Colors.primaryBlue)
                                        .cornerRadius(20)
                                        .handDrawnBorder(color: .white.opacity(0.3), cornerRadius: 20)
                                    
                                    Spacer()
                                    
                                    // ビューモード切り替えセレクター
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                viewMode = .grid
                                            }
                                            triggerSequentialAnimation()
                                        }) {
                                            Image(systemName: "square.grid.2x2.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(viewMode == .grid ? .white : Theme.Colors.primaryBlue)
                                                .padding(6)
                                                .background(viewMode == .grid ? Theme.Colors.primaryBlue : Color.clear)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                viewMode = .honeycomb
                                            }
                                            triggerSequentialAnimation()
                                        }) {
                                            Image(systemName: "hexagon.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(viewMode == .honeycomb ? .white : Theme.Colors.primaryBlue)
                                                .padding(6)
                                                .background(viewMode == .honeycomb ? Theme.Colors.primaryBlue : Color.clear)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(4)
                                    .background(Theme.Colors.card(for: colorScheme))
                                    .cornerRadius(20)
                                    .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.12), cornerRadius: 20)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                
                                // 双方向ズーム・ドラッグ可能なハニカムキャンバス
                                GeometryReader { geometry in
                                    ZStack {
                                        // 内部のハニカムグリッドコンテンツ。ズームとドラッグ（オフセット）はこのインナーZStackにのみ適用されます。
                                        ZStack {
                                            // 背景：空のハニカムグリッドの網目（37枠すべて描画）
                                            ForEach(0..<37, id: \.self) { index in
                                                let offset = honeycombOffset(for: index)
                                                EmptyHexagonSlot(colorScheme: colorScheme)
                                                    .offset(x: offset.x, y: offset.y)
                                                    .allowsHitTesting(false)
                                            }
                                            
                                            // 前景：解放されたカッパたちの六角形セル（時差ポップアニメーション）
                                            ForEach(0..<uniqueKappas.count, id: \.self) { index in
                                                let cell = uniqueKappas[index]
                                                let isCellAnimated = index <= animatedIndexLimit
                                                let offset = honeycombOffset(for: index)
                                                
                                                Button(action: {
                                                    print("🟢 [AlbumView] Cell tapped via Button: \(cell.title), id: \(cell.id)")
                                                    selectedKappa = cell
                                                }) {
                                                    HexagonKappaCard(kappa: cell, colorScheme: colorScheme)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .contentShape(Hexagon())
                                                .scaleEffect(isCellAnimated ? 1.0 : 0.01)
                                                .opacity(isCellAnimated ? 1.0 : 0.0)
                                                .offset(x: offset.x, y: offset.y)
                                            }
                                        }
                                        .scaleEffect((zoomScale * gestureZoomScale) * (UIScreen.main.bounds.width < 450 ? 0.85 : 1.0))
                                        .offset(x: dragOffset.width + gestureDragOffset.width, y: dragOffset.height + gestureDragOffset.height)
                                    }
                                    // 外側のコンテナは画面全体に静止したままジェスチャを待ち受けます。
                                    // これにより、ハニカムがズームや移動でどこへ行こうとも、画面全体のどこからでもズームやドラッグを確実に検知します！
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .background(Color.black.opacity(0.001))
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(panAndZoomGesture)
                                    .onTapGesture(count: 2) {
                                        // ダブルタップで位置・スケールを標準状態にリセットするコジーな隠しジェスチャ！
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                                            zoomScale = 0.95
                                            dragOffset = .zero
                                        }
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
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
        .navigationBarHidden(false)
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
        } else if baseId == "seaweed" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_seaweed_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_seaweed_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_seaweed_3", defaultValue: "Stage 3: 幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_seaweed_4", defaultValue: "Stage 4: 成長期（のりベビー）")
            default: return LanguageManager.shared.localizedString(forKey: "stage_seaweed_5", defaultValue: "Stage 5: 成体期（のりかっぱ最終形態）")
            }
        } else if baseId == "bonsai" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_bonsai_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_bonsai_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_bonsai_3", defaultValue: "Stage 3: ベビー期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_bonsai_4", defaultValue: "Stage 4: 盆栽ベビー期")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_bonsai_5", defaultValue: "Stage 5: 盆栽チャイルド期")
            case 6: return LanguageManager.shared.localizedString(forKey: "stage_bonsai_6", defaultValue: "Stage 6: 盆栽アダルト期")
            default: return LanguageManager.shared.localizedString(forKey: "stage_bonsai_7", defaultValue: "Stage 7: 盆栽マスター期（最終形態）")
            }
        } else if baseId == "karesansui" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_karesansui_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_karesansui_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_karesansui_3", defaultValue: "Stage 3: 幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_karesansui_4", defaultValue: "Stage 4: 成長期（枯山水ベビー）")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_karesansui_5", defaultValue: "Stage 5: 成長期（枯山水チャイルド）")
            default: return LanguageManager.shared.localizedString(forKey: "stage_karesansui_6", defaultValue: "Stage 6: 成体期（枯山水かっぱ最終形態）")
            }
        } else if baseId == "cyber" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_cyber_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_cyber_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_cyber_3", defaultValue: "Stage 3: 電脳幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_cyber_4", defaultValue: "Stage 4: 成長期（サイバーベビー）")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_cyber_5", defaultValue: "Stage 5: 成長期（サイバーチャイルド）")
            default: return LanguageManager.shared.localizedString(forKey: "stage_cyber_6", defaultValue: "Stage 6: 成体期（サイバーかっぱ最終形態）")
            }
        } else if baseId == "creamsoda" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_3", defaultValue: "Stage 3: ベビー期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_4", defaultValue: "Stage 4: ソーダベビー期")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_5", defaultValue: "Stage 5: ソーダチャイルド期")
            case 6: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_6", defaultValue: "Stage 6: メロンソーダアダルト期")
            case 7: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_7", defaultValue: "Stage 7: アイスクリーム期")
            default: return LanguageManager.shared.localizedString(forKey: "stage_creamsoda_8", defaultValue: "Stage 8: クリームソーダかっぱ（極上最終形態）")
            }
        } else if baseId == "atrier" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_atrier_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_atrier_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_atrier_3", defaultValue: "Stage 3: 幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_atrier_4", defaultValue: "Stage 4: 成長期（アトリエベビー）")
            case 5: return LanguageManager.shared.localizedString(forKey: "stage_atrier_5", defaultValue: "Stage 5: 成長期（アトリエチャイルド）")
            default: return LanguageManager.shared.localizedString(forKey: "stage_atrier_6", defaultValue: "Stage 6: 成体期（アトリエかっぱ最終形態）")
            }
        } else if baseId == "surf" {
            switch stage {
            case 1: return LanguageManager.shared.localizedString(forKey: "stage_surf_1", defaultValue: "Stage 1: 卵期")
            case 2: return LanguageManager.shared.localizedString(forKey: "stage_surf_2", defaultValue: "Stage 2: ひび割れ期")
            case 3: return LanguageManager.shared.localizedString(forKey: "stage_surf_3", defaultValue: "Stage 3: 幼生期")
            case 4: return LanguageManager.shared.localizedString(forKey: "stage_surf_4", defaultValue: "Stage 4: 成長期（波乗りベビー）")
            default: return LanguageManager.shared.localizedString(forKey: "stage_surf_5", defaultValue: "Stage 5: 成体期（波乗りかっぱ最終形態）")
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

// MARK: - Honeycomb Elements

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let xSpacing = width / 4
        
        path.move(to: CGPoint(x: xSpacing, y: 0))
        path.addLine(to: CGPoint(x: xSpacing * 3, y: 0))
        path.addLine(to: CGPoint(x: width, y: height / 2))
        path.addLine(to: CGPoint(x: xSpacing * 3, y: height))
        path.addLine(to: CGPoint(x: xSpacing, y: height))
        path.addLine(to: CGPoint(x: 0, y: height / 2))
        path.closeSubpath()
        return path
    }
}

struct EmptyHexagonSlot: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        Hexagon()
            .stroke(
                Color.white.opacity(colorScheme == .dark ? 0.22 : 0.50),
                lineWidth: 1.5
            )
            .frame(width: 110, height: 96)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.03), radius: 2, x: 0, y: 1)
    }
}

struct HexagonKappaCard: View {
    let kappa: KappaCollection
    let colorScheme: ColorScheme
    
    var baseId: String {
        kappa.id.components(separatedBy: "_").first ?? "gamer"
    }
    
    var maxStage: Int {
        KappaData.find(by: baseId)?.numberOfStages ?? 5
    }
    
    var body: some View {
        ZStack {
            // 背景のグラデーション六角形
            Hexagon()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.lightBlue.opacity(colorScheme == .dark ? 0.25 : 0.18),
                            Theme.Colors.primaryBlue.opacity(colorScheme == .dark ? 0.12 : 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // カッパイラスト（六角形で切り抜き、端が見切れても良い全体表示）
            KappaImageView(kappaId: baseId, stage: maxStage, contentMode: .fill)
                .frame(width: 110, height: 96)
                .clipShape(Hexagon())
        }
        .frame(width: 110, height: 96)
        // 手書き風六角形ボーダー（白っぽくはっきり見えるよう白色線幅3.0に強化）
        .overlay(
            Hexagon()
                .stroke(Color.white.opacity(0.85), lineWidth: 3.0)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 5, x: 0, y: 2)
    }
}

