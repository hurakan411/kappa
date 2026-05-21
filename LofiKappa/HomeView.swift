import SwiftUI
import SwiftData

struct SparkleEffectItem: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var color: Color
    var opacity: Double
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var userSettings: [UserSettings]
    @Query private var waterLogs: [DailyWaterLog]
    @Query private var unlockedKappas: [KappaCollection]
    
    @State private var isAnimating = false
    @State private var isReady = false
    @State private var isMenuOpen = false
    @State private var localTodayLog: DailyWaterLog? = nil
    @State private var cachedImageName: String = ""
    @State private var cachedSettings: UserSettings? = nil
    
    // タッチ＆エフェクト用ステート
    @State private var touchScaleX: CGFloat = 1.0
    @State private var touchScaleY: CGFloat = 1.0
    @State private var sparkles: [SparkleEffectItem] = []
    
    // MARK: - Stable accessors (no side effects)
    
    private var safeLog: DailyWaterLog? { localTodayLog }
    
    private var safeDailyGoal: Int {
        cachedSettings?.dailyGoal ?? 1500
    }
    
    private var currentKappaId: String {
        safeLog?.targetKappaId ?? "gamer"
    }
    
    private var currentKappa: KappaData {
        allKappas.first(where: { $0.id == currentKappaId }) ?? allKappas[0]
    }
    
    private var currentGoal: Int {
        currentKappa.scaledRequirements(dailyGoal: safeDailyGoal).last ?? safeDailyGoal
    }
    
    private var currentAmount: Int {
        safeLog?.currentAmount ?? 0
    }
    
    private var currentKappaAmount: Int {
        safeLog?.kappaCurrentAmount ?? 0
    }
    
    private var maxStageIndex: Int {
        currentKappa.numberOfStages
    }
    
    private var currentStageIndex: Int {
        let reqs = currentKappa.scaledRequirements(dailyGoal: safeDailyGoal)
        for i in 0..<reqs.count {
            if currentKappaAmount < reqs[i] {
                return i + 1
            }
        }
        return reqs.count + 1
    }
    
    private var todayGoal: Int { safeDailyGoal }
    
    private var progress: Double {
        guard todayGoal > 0 else { return 0 }
        return min(Double(currentAmount) / Double(todayGoal), 1.0)
    }
    
    private var nextEvolutionGoal: Int {
        let reqs = currentKappa.scaledRequirements(dailyGoal: safeDailyGoal)
        let idx = currentStageIndex - 1
        if idx >= 0 && idx < reqs.count {
            return reqs[idx]
        }
        return reqs.last ?? safeDailyGoal
    }
    
    private var currentStageBase: Int {
        let reqs = currentKappa.scaledRequirements(dailyGoal: safeDailyGoal)
        let idx = currentStageIndex - 2
        if idx >= 0 && idx < reqs.count {
            return reqs[idx]
        }
        return 0
    }
    
    private var evolutionProgress: Double {
        if currentStageIndex == maxStageIndex { return 1.0 }
        let stageTotal = nextEvolutionGoal - currentStageBase
        guard stageTotal > 0 else { return 0 }
        let stageCurrent = currentKappaAmount - currentStageBase
        return min(max(Double(stageCurrent) / Double(stageTotal), 0.0), 1.0)
    }
    
    private var mlToNextEvolution: Int {
        if currentStageIndex == maxStageIndex { return 0 }
        return max(nextEvolutionGoal - currentKappaAmount, 0)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // アナログ手帖の時間帯ライティング背景
            TimeLightingBackground()
            
            if isReady {
                mainContent
                
                // アーチメニューを画面最下部に固定
                if currentStageIndex == maxStageIndex {
                    Button(action: { resetKappa() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles").font(.body)
                            Text(AppTexts.raiseNextKappa)
                        }
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primaryBlue)
                        .cornerRadius(16)
                        .handDrawnBorder(color: .white.opacity(0.4), cornerRadius: 16)
                        .shadow(color: Theme.Colors.primaryBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                } else {
                    ArcWaterMenu(
                        isOpen: $isMenuOpen,
                        items: [
                            (amount: cachedSettings?.cupSize1 ?? 150, icon: "cup.and.saucer.fill"),
                            (amount: cachedSettings?.cupSize2 ?? 200, icon: "mug.fill"),
                            (amount: cachedSettings?.cupSize3 ?? 300, icon: "drop.fill"),
                            (amount: cachedSettings?.cupSize4 ?? 400, icon: "waterbottle.fill"),
                            (amount: cachedSettings?.cupSize5 ?? 500, icon: "takeoutbag.and.cup.and.straw.fill")
                        ],
                        colorScheme: colorScheme,
                        onSelect: { amount in addWater(amount: amount) }
                    )
                    .padding(.bottom, 8)
                }
            } else {
                ProgressView()
                    .onAppear { initializeData() }
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // ヘッダー（手書き風セクション）
            VStack(spacing: 4) {
                Text(AppTexts.tabHome)
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                    .padding(.top, 16)
                
                HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.15))
                    .frame(width: 120)
            }
            
            Spacer()
            
            // カッパイラスト（ぷにぷにタッチ対応）
            ZStack {
                // スパークルエフェクトの描画レイヤー
                ForEach(sparkles) { sparkle in
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(sparkle.color)
                        .scaleEffect(sparkle.scale)
                        .opacity(sparkle.opacity)
                        .offset(x: sparkle.x, y: sparkle.y)
                }
                
                KappaImageView(kappaId: currentKappaId, stage: currentStageIndex)
                    .frame(width: 360, height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .onTapGesture {
                        triggerSparkles(count: 8)
                    }
            }
            
            Spacer(minLength: 24)
            
            // セグメントバーカード
            VStack(spacing: 12) {
                StatSegmentCard(
                    value: evolutionProgress,
                    icon: "sparkles",
                    label: AppTexts.nextEvolution,
                    currentText: currentStageIndex == maxStageIndex ? "MAX" : "\(currentKappaAmount) ml",
                    maxText: currentStageIndex == maxStageIndex ? "" : "/ \(nextEvolutionGoal) ml",
                    colorScheme: colorScheme
                )
                StatSegmentCard(
                    value: progress,
                    icon: "drop.fill",
                    label: AppTexts.todaysWater,
                    currentText: "\(currentAmount) ml",
                    maxText: "/ \(todayGoal) ml",
                    colorScheme: colorScheme
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // ArcWaterMenuのトリガーボタン分の余白
            Spacer().frame(height: 90)
        }
    }
    
    // MARK: - Subviews
    
    // 旧waterButton（削除・ArcWaterMenuへ移行）
    
    // MARK: - Data operations
    
    private func initializeData() {
        // 1. Settings を安全に取得・作成（body評価の外で行う）
        if let existingSettings = userSettings.first {
            cachedSettings = existingSettings
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            cachedSettings = newSettings
        }
        
        // 2. 今日のログを取得・作成
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        let todaysLogs = waterLogs.filter { $0.dateString == todayStr }
        
        if todaysLogs.count > 1 {
            let survivor = todaysLogs.max(by: { $0.kappaCurrentAmount < $1.kappaCurrentAmount }) ?? todaysLogs[0]
            for log in todaysLogs where log !== survivor {
                modelContext.delete(log)
            }
            try? modelContext.save()
            localTodayLog = survivor
        } else if let existingLog = todaysLogs.first {
            localTodayLog = existingLog
        } else {
            let randomKappa = getNextRandomKappa()
            let newLog = DailyWaterLog(dateString: todayStr, targetKappaId: randomKappa)
            modelContext.insert(newLog)
            try? modelContext.save()
            localTodayLog = newLog
        }
        
        // 3. 画像名を確定
        rebuildImageName()
        
        // 4. 準備完了 → メイン画面を表示
        isReady = true
    }
    
    private func rebuildImageName() {
        guard let log = localTodayLog else { return }
        let goal = cachedSettings?.dailyGoal ?? 1500
        let kappa = allKappas.first(where: { $0.id == log.targetKappaId }) ?? allKappas[0]
        let reqs = kappa.scaledRequirements(dailyGoal: goal)
        let amount = log.kappaCurrentAmount
        var stage = reqs.count + 1
        for i in 0..<reqs.count {
            if amount < reqs[i] {
                stage = i + 1
                break
            }
        }
        cachedImageName = "kappa_\(log.targetKappaId)_stage\(min(stage, 5))"
    }
    
    private func addWater(amount: Int) {
        guard let log = localTodayLog else { return }
        
        #if DEBUG
        let evolutionToAdd = amount
        #else
        let availableForEvolution = max(0, todayGoal - log.currentAmount)
        let evolutionToAdd = min(amount, availableForEvolution)
        #endif
        
        log.currentAmount += amount
        log.lastDrinkTime = Date()
        
        let newIntake = IntakeRecord(timestamp: Date(), amount: amount)
        modelContext.insert(newIntake)
        log.intakes.append(newIntake)
        
        if evolutionToAdd > 0 && log.kappaCurrentAmount < currentGoal {
            log.kappaCurrentAmount = min(currentGoal, log.kappaCurrentAmount + evolutionToAdd)
            
            if log.kappaCurrentAmount >= currentGoal && !log.isCompleted {
                log.isCompleted = true
                unlockCurrentKappa()
            }
        }
        
        try? modelContext.save()
        rebuildImageName()
        
        // 水分補給時のスパークルエフェクトをトリガー
        triggerSparkles(count: 16)
    }
    
    private func triggerSparkles(count: Int) {
        var newSparkles: [SparkleEffectItem] = []
        let colors = [Theme.Colors.primaryBlue, Theme.Colors.lightBlue, Theme.Colors.kappaGreenDark, Color.yellow]
        for _ in 0..<count {
            let x = CGFloat.random(in: -70...70)
            let y = CGFloat.random(in: -70...70)
            let scale = CGFloat.random(in: 0.6...1.6)
            let color = colors.randomElement() ?? Theme.Colors.primaryBlue
            newSparkles.append(SparkleEffectItem(x: x, y: y, scale: scale, color: color, opacity: 1.0))
        }
        sparkles = newSparkles
        
        // 散乱アニメーション
        withAnimation(.easeOut(duration: 0.75)) {
            for i in 0..<sparkles.count {
                sparkles[i].x *= 2.0
                sparkles[i].y = sparkles[i].y * 2.0 - 40
                sparkles[i].scale *= 0.3
                sparkles[i].opacity = 0.0
            }
        }
        
        // 一定時間後に消去
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            sparkles.removeAll()
        }
    }
    
    private func resetKappa() {
        guard let log = localTodayLog else { return }
        let randomKappa = getNextRandomKappa()
        log.targetKappaId = randomKappa
        log.kappaCurrentAmount = 0
        log.isCompleted = false
        try? modelContext.save()
        rebuildImageName()
    }
    
    private func getNextRandomKappa() -> String {
        let unlockedIds = Set(unlockedKappas.map { $0.id.components(separatedBy: "_").first ?? "" })
        let availableKappas = allKappas.filter { !unlockedIds.contains($0.id) }
        return availableKappas.randomElement()?.id ?? "gamer"
    }
    
    private func unlockCurrentKappa() {
        // すでに解放済みのカッパ種かどうか重複チェック
        let alreadyUnlocked = unlockedKappas.contains { collection in
            let baseId = collection.id.components(separatedBy: "_").first ?? ""
            return baseId == currentKappaId
        }
        
        guard !alreadyUnlocked else { return }
        
        let kappaToSave = KappaCollection(
            id: currentKappaId + "_" + UUID().uuidString.prefix(8),
            title: currentKappa.name,
            kappaDescription: currentKappa.description,
            dateUnlocked: Date()
        )
        modelContext.insert(kappaToSave)
    }
}

// MARK: - ArcWaterMenu

struct ArcWaterMenu: View {
    @Binding var isOpen: Bool
    let items: [(amount: Int, icon: String)]
    let colorScheme: ColorScheme
    let onSelect: (Int) -> Void

    private var angles: [Double] {
        let count = items.count
        return (0..<count).map { i in
            180.0 - Double(i) * 180.0 / Double(count - 1)
        }
    }

    private let radius: CGFloat = 108
    private let triggerSize: CGFloat = 62
    /// アーチ線スウィープの所要時間（秒）
    private let arcDuration: Double = 0.45

    var body: some View {
        ZStack {
            // アーチ線：Shape + .trim() で左から右へ描画アニメーション
            ArcLineShape(radius: radius, bottomOffset: triggerSize / 2)
                .trim(from: 0, to: isOpen ? 1 : 0)
                .stroke(
                    Theme.Colors.primaryBlue.opacity(0.32),
                    style: StrokeStyle(lineWidth: 1.8, dash: [5, 4])
                )
                .animation(.easeOut(duration: arcDuration), value: isOpen)

            // アーチボタン群：アークの描画進行に合わせて左から順に出現
            ForEach(0..<items.count, id: \.self) { i in
                let angle = Angle(degrees: angles[i])
                let dx = radius * CGFloat(cos(angle.radians))
                let dy = -radius * CGFloat(sin(angle.radians))
                // ボタン i の出現タイミング = アークがその位置に到達する時刻
                let buttonDelay = isOpen
                    ? Double(i) / Double(items.count - 1) * arcDuration
                    : 0.0

                ArcWaterButton(
                    amount: items[i].amount,
                    icon: items[i].icon,
                    colorScheme: colorScheme
                ) {
                    withAnimation(.spring()) { isOpen = false }
                    onSelect(items[i].amount)
                }
                .offset(
                    x: isOpen ? dx : 0,
                    y: isOpen ? (dy + radius) : radius
                )
                .scaleEffect(isOpen ? 1.0 : 0.3)
                .opacity(isOpen ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.38, dampingFraction: 0.7)
                    .delay(buttonDelay),
                    value: isOpen
                )
            }

            // トリガーボタン（フレーム下端に固定）
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.7)) {
                    isOpen.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primaryBlue, Theme.Colors.primaryBlue.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: triggerSize, height: triggerSize)
                        .shadow(color: Theme.Colors.primaryBlue.opacity(0.4), radius: 10, x: 0, y: 5)

                    Image(systemName: isOpen ? "xmark" : "drop.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                        .animation(.spring(response: 0.3), value: isOpen)
                }
            }
            .offset(y: radius)
        }
        .frame(height: radius * 2 + triggerSize)
    }
}

// MARK: - ArcLineShape

/// トリガーボタン中心から左（180°）→右（0°）へ描画する半円弧形
struct ArcLineShape: Shape {
    let radius: CGFloat
    let bottomOffset: CGFloat // triggerSize / 2

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(
            x: rect.width / 2,
            y: rect.height - bottomOffset
        )
        var p = Path()
        // 左（180°）から右（0°）へ時計回り方向（clockwise: false = 上半圆）
        p.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return p
    }
}

// MARK: - ArcWaterButton

struct ArcWaterButton: View {
    let amount: Int
    let icon: String
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text("\(amount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Text("ml")
                    .font(.system(size: 8, design: .rounded))
            }
            .frame(width: 58, height: 58)
            .background(
                Circle()
                    .fill(Theme.Colors.card(for: colorScheme))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 6, x: 0, y: 3)
            )
            .overlay(
                Circle()
                    .stroke(Theme.Colors.primaryBlue.opacity(0.18), lineWidth: 1)
            )
            .foregroundColor(Theme.Colors.primaryBlue)
        }
    }
}

// MARK: - StatSegmentCard


struct StatSegmentCard: View {
    let value: Double       // 0.0 – 1.0
    let icon: String
    let label: String
    let currentText: String
    let maxText: String
    let colorScheme: ColorScheme

    private let segmentCount = 10
    private let segH: CGFloat = 7

    var body: some View {
        VStack(spacing: 10) {
            // ラベル行
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryBlue)
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 2) {
                    Text(currentText)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(Theme.Colors.primaryBlue)
                    if !maxText.isEmpty {
                        Text(maxText)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // セグメントバー
            GeometryReader { geo in
                let spacing: CGFloat = 4
                let totalSpacing = spacing * CGFloat(segmentCount - 1)
                let segW = (geo.size.width - totalSpacing) / CGFloat(segmentCount)
                let filledCount = Int((value * Double(segmentCount)).rounded())

                HStack(spacing: spacing) {
                    ForEach(0..<segmentCount, id: \.self) { i in
                        let filled = i < filledCount
                        RoundedRectangle(cornerRadius: segH / 2)
                            .fill(
                                filled
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [
                                        Theme.Colors.lightBlue.opacity(0.8),
                                        Theme.Colors.primaryBlue
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                : AnyShapeStyle(Theme.Colors.lightBlue.opacity(0.18))
                            )
                            .frame(width: segW, height: segH)
                            .animation(.easeOut(duration: 0.15).delay(Double(i) * 0.03), value: filled)
                    }
                }
            }
            .frame(height: segH)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.Colors.card(for: colorScheme))
        .cornerRadius(16)
        .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.24), cornerRadius: 16)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - TimeLightingBackground

struct TimeLightingBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var timeGradientColors: [Color] = [
        Theme.Colors.baseBackgroundLight,
        Theme.Colors.baseBackgroundLight
    ]
    
    var body: some View {
        ZStack {
            // 時間帯別グラデーション
            LinearGradient(
                colors: timeGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5), value: timeGradientColors)
            
            // アナログ手帳の微細な方眼/ドット風テクスチャ
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 20
                    let width = geo.size.width
                    let height = geo.size.height
                    
                    for x in stride(from: step, to: width, by: step) {
                        for y in stride(from: step, to: height, by: step) {
                            path.addEllipse(in: CGRect(x: x, y: y, width: 1.2, height: 1.2))
                        }
                    }
                }
                .fill(Theme.Colors.text(for: colorScheme).opacity(colorScheme == .dark ? 0.04 : 0.06))
            }
            .ignoresSafeArea()
        }
        .onAppear {
            updateLighting()
        }
        .onChange(of: colorScheme) { _ in
            updateLighting()
        }
    }
    
    private func updateLighting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if colorScheme == .dark {
            // ダークモード時は常に落ち着いたミッドナイト＋常夜灯トーン
            if hour >= 6 && hour < 10 {
                // 朝
                timeGradientColors = [Color(hex: "1F1D24"), Color(hex: "18151A")]
            } else if hour >= 10 && hour < 16 {
                // 昼
                timeGradientColors = [Color(hex: "221F21"), Color(hex: "1C1917")]
            } else if hour >= 16 && hour < 19 {
                // 夕方
                timeGradientColors = [Color(hex: "261C1F"), Color(hex: "1C1917")]
            } else {
                // 夜・深夜
                timeGradientColors = [Color(hex: "1A1829"), Color(hex: "1C1917")]
            }
        } else {
            // ライトモード時は明るく豊かなグラデーション
            if hour >= 6 && hour < 10 {
                // 朝：ペールイエロー → 爽やかな薄いブルー
                timeGradientColors = [Color(hex: "FEF9C3").opacity(0.45), Color(hex: "E0F2FE").opacity(0.65)]
            } else if hour >= 10 && hour < 16 {
                // 昼：ぽかぽかとした暖かなホワイトゴールド
                timeGradientColors = [Color(hex: "FFFDF5"), Color(hex: "FAF6F0")]
            } else if hour >= 16 && hour < 19 {
                // 夕方：アンバーと夕焼けピンク
                timeGradientColors = [Color(hex: "FDE68A").opacity(0.3), Color(hex: "FCE7F3").opacity(0.55)]
            } else {
                // 夜・深夜：ウォームオレンジと深いミッドナイト
                timeGradientColors = [Color(hex: "FFEDD5").opacity(0.25), Color(hex: "DBEAFE").opacity(0.45)]
            }
        }
    }
}

