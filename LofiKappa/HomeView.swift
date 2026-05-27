import SwiftUI
import SwiftData
import WidgetKit
import StoreKit

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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @Query private var userSettings: [UserSettings]
    @Query private var waterLogs: [DailyWaterLog]
    @Query private var unlockedKappas: [KappaCollection]
    @ObservedObject private var languageManager = LanguageManager.shared
    
    @State private var isAnimating = false
    @State private var isReady = false
    @State private var isMenuOpen = false
    
    // タッチ＆エフェクト用ステート
    @State private var touchScaleX: CGFloat = 1.0
    @State private var touchScaleY: CGFloat = 1.0
    @State private var sparkles: [SparkleEffectItem] = []
    
    // MARK: - Stable accessors (no side effects)
    
    private var safeSettings: UserSettings? {
        userSettings.first
    }
    
    private var localTodayLog: DailyWaterLog? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        return waterLogs.first(where: { $0.dateString == todayStr })
    }
    
    private var safeLog: DailyWaterLog? { localTodayLog }
    
    private var safeDailyGoal: Int {
        safeSettings?.dailyGoal ?? 1500
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
        let _ = languageManager.selectedLanguage // 言語変更を検知してコンテンツを再描画
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
                            (amount: safeSettings?.cupSize1 ?? 150, icon: "cup.and.saucer.fill"),
                            (amount: safeSettings?.cupSize2 ?? 200, icon: "mug.fill"),
                            (amount: safeSettings?.cupSize3 ?? 300, icon: "drop.fill"),
                            (amount: safeSettings?.cupSize4 ?? 400, icon: "waterbottle.fill"),
                            (amount: safeSettings?.cupSize5 ?? 500, icon: "takeoutbag.and.cup.and.straw.fill")
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
        .onChange(of: safeDailyGoal) { newGoal in
            guard isReady, let log = localTodayLog, !log.isCompleted else { return }
            let currentRefGoal = log.referenceDailyGoal ?? newGoal
            if currentRefGoal != newGoal && currentRefGoal > 0 {
                let oldAmount = log.kappaCurrentAmount
                let scaled = Int((Double(oldAmount) * Double(newGoal) / Double(currentRefGoal)).rounded())
                log.kappaCurrentAmount = scaled
                log.referenceDailyGoal = newGoal
                print("🌱 [HomeView] Live scaled today's kappa progress from \(oldAmount)ml to \(scaled)ml due to dailyGoal change (\(currentRefGoal)ml -> \(newGoal)ml)")
                try? modelContext.save()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("🟢 [HomeView] App entered active foreground. Syncing widget data via UserDefaults.")
                syncFromWidget()
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
                    .id("\(currentKappaId)_\(currentStageIndex)")
                    .frame(width: 360, height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .onTapGesture {
                        triggerSparkles(count: 8)
                    }
            }
            
            // 画像の外（直下）に設置された手書き風のプレミアムシェアボタン
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                shareKappa()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .bold))
                    Text(AppTexts.shareBtnText)
                        .font(.system(.caption, design: .rounded).bold())
                }
                .foregroundColor(Theme.Colors.primaryBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.lightBlue.opacity(0.18))
                .cornerRadius(20)
                .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.3), cornerRadius: 20)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 10)
            
            Spacer(minLength: 24)
            
            VStack(spacing: 12) {
                StatSegmentCard(
                    value: evolutionProgress,
                    icon: "sparkles",
                    label: AppTexts.nextEvolution,
                    currentText: currentStageIndex == maxStageIndex ? "MAX" : "\(currentKappaAmount) ml",
                    maxText: currentStageIndex == maxStageIndex ? "" : "/ \(nextEvolutionGoal) ml",
                    tintColor: Theme.Colors.kappaGreenDark,
                    lightTintColor: Theme.Colors.kappaGreenLight,
                    colorScheme: colorScheme
                )
                StatSegmentCard(
                    value: progress,
                    icon: "drop.fill",
                    label: AppTexts.todaysWater,
                    currentText: "\(currentAmount) ml",
                    maxText: "/ \(todayGoal) ml",
                    tintColor: Theme.Colors.primaryBlue,
                    lightTintColor: Theme.Colors.lightBlue,
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
        // 1. Settings を安全に取得・作成
        if userSettings.isEmpty {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
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
        } else if todaysLogs.isEmpty {
            // 前日のログを探す
            let sortedLogs = waterLogs.sorted(by: { $0.dateString < $1.dateString })
            var targetKappa = getNextRandomKappa()
            var startingProgress = 0
            
            if let lastLog = sortedLogs.last {
                if !lastLog.isCompleted {
                    // 未完了なら前日のカッパ種と成長進捗を引き継ぐ！
                    targetKappa = lastLog.targetKappaId
                    
                    // 前日の目標水分量と現在の目標水分量に差がある場合、進捗をスケーリングする
                    let yesterdayGoal = lastLog.referenceDailyGoal ?? safeDailyGoal
                    if yesterdayGoal != safeDailyGoal && yesterdayGoal > 0 {
                        startingProgress = Int((Double(lastLog.kappaCurrentAmount) * Double(safeDailyGoal) / Double(yesterdayGoal)).rounded())
                        print("🌱 [HomeView] Scaled yesterday's progress from \(lastLog.kappaCurrentAmount)ml to \(startingProgress)ml due to dailyGoal change (\(yesterdayGoal)ml -> \(safeDailyGoal)ml)")
                    } else {
                        startingProgress = lastLog.kappaCurrentAmount
                    }
                    print("🌱 [HomeView] Continuing raising yesterday's kappa: \(targetKappa) with progress \(startingProgress)ml")
                } else {
                    print("🎉 [HomeView] Yesterday's kappa was completed! Starting a new one.")
                }
            }
            
            let newLog = DailyWaterLog(dateString: todayStr, targetKappaId: targetKappa, referenceDailyGoal: safeDailyGoal)
            newLog.kappaCurrentAmount = startingProgress
            modelContext.insert(newLog)
            try? modelContext.save()
        } else {
            // 今日のログが既に存在する場合：
            // 今日の目標水分量が変更された場合に備え、進捗をリアルタイムにスケーリング
            if let todayLog = todaysLogs.first {
                let currentRefGoal = todayLog.referenceDailyGoal ?? safeDailyGoal
                if currentRefGoal != safeDailyGoal && currentRefGoal > 0 && !todayLog.isCompleted {
                    let oldAmount = todayLog.kappaCurrentAmount
                    let scaled = Int((Double(oldAmount) * Double(safeDailyGoal) / Double(currentRefGoal)).rounded())
                    todayLog.kappaCurrentAmount = scaled
                    todayLog.referenceDailyGoal = safeDailyGoal
                    print("🌱 [HomeView] Scaled today's kappa progress from \(oldAmount)ml to \(scaled)ml due to dailyGoal change (\(currentRefGoal)ml -> \(safeDailyGoal)ml)")
                    try? modelContext.save()
                } else if todayLog.referenceDailyGoal == nil {
                    todayLog.referenceDailyGoal = safeDailyGoal
                    try? modelContext.save()
                }
            }
        }
        
        // 3. 現在の状態を UserDefaults に同期（ウィジェットが読めるように）
        if let log = localTodayLog {
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "yyyy-MM-dd"
            WidgetDataSync.save(
                dateString: formatter2.string(from: Date()),
                currentAmount: log.currentAmount,
                kappaCurrentAmount: log.kappaCurrentAmount,
                isCompleted: log.isCompleted,
                targetKappaId: log.targetKappaId,
                dailyGoal: safeDailyGoal
            )
            // 自分が書き込んだデータを自分でマージしないように、同期済みタイムスタンプを記録
            markSyncTimestamp()
        }
        
        // 4. 準備完了 → メイン画面を表示
        isReady = true
        
        // 給水リマインダーがデフォルトONのため、未決定の場合は通知許可をリクエスト
        NotificationManager.shared.requestAuthorizationIfNotDetermined()
    }
    
    /// 特定の進化ステージ変化を検知してレビュー依頼を要求する
    private func checkAndRequestReview(oldStage: Int, newStage: Int) {
        // 1体目のカッパを育てている（図鑑登録数が0である状態）
        if unlockedKappas.isEmpty {
            // 一体目のカッパが最終stageになったら
            if oldStage < maxStageIndex && newStage == maxStageIndex {
                let key = "hasRequestedReviewForFirstKappaFinalStage"
                if !UserDefaults.standard.bool(forKey: key) {
                    requestReview()
                    UserDefaults.standard.set(true, forKey: key)
                    print("⭐ [Review] Requested review: First kappa reached Final Stage (\(maxStageIndex)) (from \(oldStage) to \(newStage))")
                }
            }
        }
    }
    
    private func addWater(amount: Int) {
        guard let log = localTodayLog else { return }
        
        let evolutionToAdd = amount
        
        log.currentAmount += amount
        log.lastDrinkTime = Date()
        
        let newIntake = IntakeRecord(timestamp: Date(), amount: amount)
        modelContext.insert(newIntake)
        log.intakes.append(newIntake)
        
        if evolutionToAdd > 0 && log.kappaCurrentAmount < currentGoal {
            let oldStage = currentStageIndex
            
            log.kappaCurrentAmount = min(currentGoal, log.kappaCurrentAmount + evolutionToAdd)
            
            let newStage = currentStageIndex
            checkAndRequestReview(oldStage: oldStage, newStage: newStage)
            
            if log.kappaCurrentAmount >= currentGoal && !log.isCompleted {
                log.isCompleted = true
                unlockCurrentKappa()
            }
        }
        
        try? modelContext.save()
        
        // UserDefaults に同期（ウィジェットが読めるように）
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        WidgetDataSync.save(
            dateString: formatter.string(from: Date()),
            currentAmount: log.currentAmount,
            kappaCurrentAmount: log.kappaCurrentAmount,
            isCompleted: log.isCompleted,
            targetKappaId: log.targetKappaId,
            dailyGoal: safeDailyGoal
        )
        // 自分が書き込んだデータを自分でマージしないように、同期済みタイムスタンプを記録
        markSyncTimestamp()
        WidgetCenter.shared.reloadAllTimelines()
        
        // 水分補給時のスパークルエフェクトをトリガー
        triggerSparkles(count: 16)
        
        // 給水リマインダーのスマートリセット
        NotificationManager.shared.resetReminder(isTargetCompleted: log.isCompleted)
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
    
    private func shareKappa() {
        let stageText = AppTexts.stageText(currentStageIndex)
        let shareText = AppTexts.shareText(
            kappaName: currentKappa.name,
            stageText: stageText,
            currentAmount: currentAmount
        )
        
        var items: [Any] = [shareText]
        if let imageUrl = SupabaseConfig.imageUrl(for: currentKappaId, stage: currentStageIndex) {
            if let uiImage = KappaImageLoader.cachedImage(for: imageUrl) {
                items.append(uiImage)
            } else {
                items.append(imageUrl)
            }
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            
            // iPadでのポップオーバー表示対策（クラッシュ防止）
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func resetKappa() {
        guard let log = localTodayLog else { return }
        let randomKappa = getNextRandomKappa()
        log.targetKappaId = randomKappa
        log.kappaCurrentAmount = 0
        log.isCompleted = false
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func getNextRandomKappa() -> String {
        let unlockedIds = Set(unlockedKappas.map { $0.id.components(separatedBy: "_").first ?? "" })
        let availableKappas = allKappas.filter { !unlockedIds.contains($0.id) }
        
        if availableKappas.isEmpty {
            // 全て解放済みの場合は、登録されているすべてのカッパからランダムに選択
            return allKappas.randomElement()?.id ?? "gamer"
        } else {
            return availableKappas.randomElement()?.id ?? "gamer"
        }
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
        
        // 登録後の合計件数（今回挿入した分を含めて unlockedKappas.count + 1）が3に達した時
        let totalUnlockedCount = unlockedKappas.count + 1
        if totalUnlockedCount == 3 {
            let key = "hasRequestedReviewForThreeKappas"
            if !UserDefaults.standard.bool(forKey: key) {
                requestReview()
                UserDefaults.standard.set(true, forKey: key)
                print("⭐ [Review] Requested review: Total unlocked kappas reached 3")
            }
        }
    }
    
    /// アプリ側が最後に同期を確認したUserDefaultsのタイムスタンプを記録する
    private func markSyncTimestamp() {
        if let syncData = WidgetDataSync.load() {
            UserDefaults.standard.set(syncData.timestamp, forKey: "lastSyncedWidgetTimestamp")
        }
    }
    
    /// UserDefaults からウィジェットが書き込んだデータを読み取り、SwiftData に反映する
    private func syncFromWidget() {
        guard let syncData = WidgetDataSync.load() else {
            print("ℹ️ [HomeView] No widget sync data available")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        // 同期データが今日のものでなければスキップ
        guard syncData.dateString == todayStr else {
            print("ℹ️ [HomeView] Widget sync data is for \(syncData.dateString), not today (\(todayStr)). Skipping.")
            return
        }
        
        // タイムスタンプが前回同期済みの値と同じ場合、新しいデータがないのでスキップ
        // （アプリ自身が書き込んだデータを自分でマージしてしまう二重反映を防止）
        let lastSyncedTimestamp = UserDefaults.standard.double(forKey: "lastSyncedWidgetTimestamp")
        guard syncData.timestamp > lastSyncedTimestamp else {
            print("ℹ️ [HomeView] Widget sync data timestamp (\(syncData.timestamp)) is not newer than last synced (\(lastSyncedTimestamp)). Skipping.")
            return
        }
        
        if let log = localTodayLog {
            // ウィジェット側の方が進んでいる場合のみマージ
            if syncData.currentAmount > log.currentAmount || syncData.kappaCurrentAmount > log.kappaCurrentAmount {
                print("🟢 [HomeView] Merging widget data: amount \(log.currentAmount)->\(syncData.currentAmount), kappa \(log.kappaCurrentAmount)->\(syncData.kappaCurrentAmount)")
                let oldStage = currentStageIndex
                
                log.currentAmount = max(log.currentAmount, syncData.currentAmount)
                log.kappaCurrentAmount = max(log.kappaCurrentAmount, syncData.kappaCurrentAmount)
                
                let newStage = currentStageIndex
                checkAndRequestReview(oldStage: oldStage, newStage: newStage)
                
                if syncData.isCompleted && !log.isCompleted {
                    log.isCompleted = true
                    unlockCurrentKappa()
                }
                try? modelContext.save()
                
                // ウィジェット経由の給水時もリマインダーをスマートリセット
                NotificationManager.shared.resetReminder(isTargetCompleted: log.isCompleted)
            } else {
                print("ℹ️ [HomeView] App data is up-to-date or ahead of widget data. No merge needed.")
            }
        } else {
            // アプリ側に今日のログがない場合、ウィジェット側のデータで新規作成
            print("🟢 [HomeView] Creating today's log from widget sync data")
            let newLog = DailyWaterLog(
                dateString: todayStr,
                currentAmount: syncData.currentAmount,
                kappaCurrentAmount: syncData.kappaCurrentAmount,
                isCompleted: syncData.isCompleted,
                targetKappaId: syncData.targetKappaId,
                referenceDailyGoal: syncData.dailyGoal
            )
            modelContext.insert(newLog)
            try? modelContext.save()
        }
        
        // 同期済みタイムスタンプを更新し、次のフォアグラウンド復帰時に同じデータを再マージしないようにする
        markSyncTimestamp()
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
    let tintColor: Color    // メインのテーマカラー（primaryBlue または kappaGreenDark）
    let lightTintColor: Color // サブのライトカラー（lightBlue または kappaGreenLight）
    let colorScheme: ColorScheme

    private let segmentCount = 10
    private let segH: CGFloat = 7

    var body: some View {
        VStack(spacing: 10) {
            // ラベル行
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(tintColor)
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 2) {
                    Text(currentText)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(tintColor)
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
                                        lightTintColor.opacity(0.8),
                                        tintColor
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                : AnyShapeStyle(lightTintColor.opacity(0.18))
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
        .handDrawnBorder(color: tintColor.opacity(0.24), cornerRadius: 16)
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
            // ダークモード時は神秘的な森の深泉・ディープティールグリーン
            if hour >= 6 && hour < 10 {
                // 朝
                timeGradientColors = [Color(hex: "142220"), Color(hex: "0E1615")]
            } else if hour >= 10 && hour < 16 {
                // 昼
                timeGradientColors = [Color(hex: "162624"), Color(hex: "111C1A")]
            } else if hour >= 16 && hour < 19 {
                // 夕方
                timeGradientColors = [Color(hex: "1C2D2A"), Color(hex: "111C1A")]
            } else {
                // 夜・深夜
                timeGradientColors = [Color(hex: "11211F"), Color(hex: "0B1312")]
            }
        } else {
            // ライトモード時は爽やかなミントアクア・薄水色・薄緑グラデーション
            if hour >= 6 && hour < 10 {
                // 朝：朝霧の薄緑 → 澄み渡る薄水色
                timeGradientColors = [Color(hex: "E0F2F1").opacity(0.6), Color(hex: "E0F7FA").opacity(0.85)]
            } else if hour >= 10 && hour < 16 {
                // 昼：まぶしい木漏れ日を浴びた水面
                timeGradientColors = [Color(hex: "EBF4F2"), Color(hex: "DDF0EC")]
            } else if hour >= 16 && hour < 19 {
                // 夕方：木々のライムグリーンを反射した水辺
                timeGradientColors = [Color(hex: "EBF4D3").opacity(0.55), Color(hex: "E0F2F1").opacity(0.75)]
            } else {
                // 夜・深夜：月明かりに照らされる静かなアクアブルー
                timeGradientColors = [Color(hex: "E2F0ED").opacity(0.5), Color(hex: "D0E8F2").opacity(0.7)]
            }
        }
    }
}

