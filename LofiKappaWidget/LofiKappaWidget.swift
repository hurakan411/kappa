import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - AddWaterIntent

struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "給水する"
    static var description = IntentDescription("選択した量の水を飲みます。")
    
    @Parameter(title: "量(ml)")
    var amount: Int
    
    init() {
        self.amount = 200
    }
    
    init(amount: Int) {
        self.amount = amount
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let context = SharedDatabase.container.mainContext
        
        // 1. 設定情報の取得
        let descriptor = FetchDescriptor<UserSettings>()
        let settings = (try? context.fetch(descriptor))?.first ?? UserSettings()
        let dailyGoal = settings.dailyGoal
        
        // 2. 今日の日付文字列
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayDateStr = formatter.string(from: Date())
        
        // 3. 今日のログを取得・作成
        let logDescriptor = FetchDescriptor<DailyWaterLog>()
        let logs = (try? context.fetch(logDescriptor)) ?? []
        let localTodayLog = logs.first(where: { $0.dateString == todayDateStr })
        
        let targetLog: DailyWaterLog
        if let existingLog = localTodayLog {
            targetLog = existingLog
        } else {
            // 前日のログを引き継ぐロジック
            let sortedLogs = logs.sorted(by: { $0.dateString < $1.dateString })
            var targetKappa = "gamer"
            var startingProgress = 0
            
            if let lastLog = sortedLogs.last {
                if !lastLog.isCompleted {
                    targetKappa = lastLog.targetKappaId
                    let yesterdayGoal = lastLog.referenceDailyGoal ?? dailyGoal
                    if yesterdayGoal != dailyGoal && yesterdayGoal > 0 {
                        startingProgress = Int((Double(lastLog.kappaCurrentAmount) * Double(dailyGoal) / Double(yesterdayGoal)).rounded())
                    } else {
                        startingProgress = lastLog.kappaCurrentAmount
                    }
                } else {
                    let collectionsDescriptor = FetchDescriptor<KappaCollection>()
                    let unlockedKappas = (try? context.fetch(collectionsDescriptor)) ?? []
                    let unlockedIds = Set(unlockedKappas.map { $0.id.components(separatedBy: "_").first ?? "" })
                    let availableKappas = allKappas.filter { !unlockedIds.contains($0.id) }
                    targetKappa = availableKappas.randomElement()?.id ?? "gamer"
                }
            }
            
            targetLog = DailyWaterLog(dateString: todayDateStr, targetKappaId: targetKappa, referenceDailyGoal: dailyGoal)
            targetLog.kappaCurrentAmount = startingProgress
            context.insert(targetLog)
        }
        
        // 4. 給水を記録
        targetLog.currentAmount += amount
        targetLog.lastDrinkTime = Date()
        
        let newIntake = IntakeRecord(timestamp: Date(), amount: amount)
        context.insert(newIntake)
        targetLog.intakes.append(newIntake)
        
        // 5. 進化進捗を更新
        let currentKappa = allKappas.first(where: { $0.id == targetLog.targetKappaId }) ?? allKappas[0]
        let currentGoal = currentKappa.scaledRequirements(dailyGoal: dailyGoal).last ?? dailyGoal
        
        if targetLog.kappaCurrentAmount < currentGoal {
            targetLog.kappaCurrentAmount = min(currentGoal, targetLog.kappaCurrentAmount + amount)
            
            if targetLog.kappaCurrentAmount >= currentGoal && !targetLog.isCompleted {
                targetLog.isCompleted = true
                
                // 図鑑に解放
                let collectionsDescriptor = FetchDescriptor<KappaCollection>()
                let unlockedKappas = (try? context.fetch(collectionsDescriptor)) ?? []
                let alreadyUnlocked = unlockedKappas.contains { collection in
                    let baseId = collection.id.components(separatedBy: "_").first ?? ""
                    return baseId == targetLog.targetKappaId
                }
                if !alreadyUnlocked {
                    let collectionId = "\(targetLog.targetKappaId)_\(todayDateStr)"
                    let newUnlock = KappaCollection(
                        id: collectionId,
                        title: currentKappa.name,
                        kappaDescription: currentKappa.description,
                        dateUnlocked: Date()
                    )
                    context.insert(newUnlock)
                }
            }
        }
        
        try? context.save()
        
        // UserDefaults経由でアプリプロセスへ確実にデータを渡す
        WidgetDataSync.save(
            dateString: todayDateStr,
            currentAmount: targetLog.currentAmount,
            kappaCurrentAmount: targetLog.kappaCurrentAmount,
            isCompleted: targetLog.isCompleted,
            targetKappaId: targetLog.targetKappaId,
            dailyGoal: dailyGoal
        )
        
        // タイムラインを更新
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let currentAmount: Int
    let dailyGoal: Int
    let kappaCurrentAmount: Int
    let kappaGoal: Int
    let evolutionProgress: Double
    let kappaId: String
    let kappaStage: Int
    let kappaName: String
    let kappaImage: UIImage?
    let isCompleted: Bool
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            currentAmount: 800,
            dailyGoal: 1500,
            kappaCurrentAmount: 1200,
            kappaGoal: 2400,
            evolutionProgress: 0.5,
            kappaId: "gamer",
            kappaStage: 3,
            kappaName: "ゲーマーかっぱ",
            kappaImage: nil,
            isCompleted: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            let entry = fetchEntry(for: Date())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task { @MainActor in
            let entry = fetchEntry(for: Date())
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    @MainActor
    private func fetchEntry(for date: Date) -> SimpleEntry {
        let context = SharedDatabase.container.mainContext
        
        // 1. 設定情報の取得
        let descriptor = FetchDescriptor<UserSettings>()
        let settings = (try? context.fetch(descriptor))?.first ?? UserSettings()
        let dailyGoal = settings.dailyGoal
        
        // 2. 今日の日付文字列
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: date)
        
        // 3. 今日のログを取得
        let logDescriptor = FetchDescriptor<DailyWaterLog>()
        let logs = (try? context.fetch(logDescriptor)) ?? []
        let localTodayLog = logs.first(where: { $0.dateString == todayStr })
        
        let currentAmount = localTodayLog?.currentAmount ?? 0
        let kappaCurrentAmount = localTodayLog?.kappaCurrentAmount ?? 0
        let kappaId = localTodayLog?.targetKappaId ?? "gamer"
        let isCompleted = localTodayLog?.isCompleted ?? false
        
                let currentKappa = allKappas.first(where: { $0.id == kappaId }) ?? allKappas[0]
        
        // ステージ判定
        var kappaStage = 1
        let reqs = currentKappa.scaledRequirements(dailyGoal: dailyGoal)
        for i in 0..<reqs.count {
            if kappaCurrentAmount < reqs[i] {
                kappaStage = i + 1
                break
            }
        }
        if kappaCurrentAmount >= (reqs.last ?? dailyGoal) {
            kappaStage = reqs.count + 1
        }
        
        let maxStageIndex = currentKappa.numberOfStages
        
        // 次の進化目標 (累計)
        let nextEvolutionGoal: Int
        let idx = kappaStage - 1
        if idx >= 0 && idx < reqs.count {
            nextEvolutionGoal = reqs[idx]
        } else {
            nextEvolutionGoal = reqs.last ?? dailyGoal
        }
        
        // 現在のステージのベース値
        let currentStageBase: Int
        let baseIdx = kappaStage - 2
        if baseIdx >= 0 && baseIdx < reqs.count {
            currentStageBase = reqs[baseIdx]
        } else {
            currentStageBase = 0
        }
        
        // 進度割合 (ステージ内での割合)
        let evolutionProgress: Double
        if kappaStage == maxStageIndex {
            evolutionProgress = 1.0
        } else {
            let stageTotal = nextEvolutionGoal - currentStageBase
            if stageTotal > 0 {
                let stageCurrent = kappaCurrentAmount - currentStageBase
                evolutionProgress = min(max(Double(stageCurrent) / Double(stageTotal), 0.0), 1.0)
            } else {
                evolutionProgress = 0.0
            }
        }
        
        // 動的フォルダマップの構築（Widget起動時用）
        if SupabaseStorageManager.shared.fileName(for: kappaId, stage: kappaStage) == nil {
            let semaphore = DispatchSemaphore(value: 0)
            let folderName = currentKappa.storageFolderName
            if let listURL = URL(string: "\(SupabaseConfig.supabaseUrl)/storage/v1/object/list/\(SupabaseConfig.bucketName)") {
                var request = URLRequest(url: listURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                if let anonKey = SupabaseConfig.anonKey {
                    request.setValue(anonKey, forHTTPHeaderField: "apikey")
                    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
                }
                
                let body: [String: Any] = [
                    "prefix": folderName + "/",
                    "limit": 100,
                    "offset": 0,
                    "sortBy": ["column": "name", "order": "asc"]
                ]
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data {
                        struct SupabaseFile: Decodable {
                            let name: String
                        }
                        if let files = try? JSONDecoder().decode([SupabaseFile].self, from: data) {
                            var stageMap: [Int: String] = [:]
                            for file in files {
                                let cleanName = URL(fileURLWithPath: file.name).lastPathComponent
                                if let firstChar = cleanName.first, let stage = Int(String(firstChar)) {
                                    stageMap[stage] = cleanName
                                }
                            }
                            if !stageMap.isEmpty {
                                DispatchQueue.main.async {
                                    SupabaseStorageManager.shared.fileMap[kappaId] = stageMap
                                }
                            }
                        }
                    }
                    semaphore.signal()
                }.resume()
                _ = semaphore.wait(timeout: .now() + 1.5)
            }
        }
        
        // 画像の同期ダウンロード
        var kappaImage: UIImage? = nil
        if let imageUrl = SupabaseConfig.imageUrl(for: kappaId, stage: kappaStage) {
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    kappaImage = image
                }
                semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: .now() + 1.5)
        }
        
        return SimpleEntry(
            date: date,
            currentAmount: currentAmount,
            dailyGoal: dailyGoal,
            kappaCurrentAmount: kappaCurrentAmount,
            kappaGoal: nextEvolutionGoal,
            evolutionProgress: evolutionProgress,
            kappaId: kappaId,
            kappaStage: kappaStage,
            kappaName: currentKappa.name,
            kappaImage: kappaImage,
            isCompleted: isCompleted
        )
    }
}

// MARK: - Views

struct LofiKappaShowcaseWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // 手書き風カラーテーマ
    private var baseBg: Color { Color(hex: "FAF6F0") }
    private var cardBg: Color { Color(hex: "FFFDFB") }
    private var inkText: Color { Color(hex: "3F3F46") }
    
    var body: some View {
        Group {
            switch family {
            case .systemLarge:
                largeView
            case .systemExtraLarge:
                extraLargeView
            default:
                largeView
            }
        }
        .containerBackground(for: .widget) {
            baseBg
        }
    }
    
    // MARK: - Showcase Large Layout (.systemLarge)
    
    private var largeView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            
            // 巨大なカッパイラスト (全面的表示・主役) - 名前や「進化完了」テキストは完全に排除
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBg)
                    .handDrawnBorder(color: inkText.opacity(0.15), cornerRadius: 20)
                
                if let image = entry.kappaImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(inkText.opacity(0.3))
                        Text("No Image")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(inkText.opacity(0.5))
                    }
                }
            }
            .frame(width: 190, height: 190) // 最大限に広げたショーケース
            .shadow(color: inkText.opacity(0.03), radius: 6, x: 0, y: 3)
            
            Spacer(minLength: 12)
            
            // 下部HUD：両方の進捗バー (本日の給水 ＆ 進化進度)
            VStack(spacing: 6) {
                // 1. 本日の給水
                VStack(spacing: 2) {
                    HStack {
                        Label("今日", systemImage: "drop.fill")
                            .font(.system(size: 9).bold())
                            .foregroundColor(Theme.Colors.primaryBlue)
                        Spacer()
                        Text("\(entry.currentAmount) / \(entry.dailyGoal) ml")
                            .font(.system(size: 9, design: .monospaced).bold())
                            .foregroundColor(inkText.opacity(0.7))
                    }
                    customProgressBar(
                        value: Double(entry.currentAmount) / Double(entry.dailyGoal),
                        color: Theme.Colors.primaryBlue,
                        height: 5
                    )
                }
                .padding(.horizontal, 20)
                
                // 2. 進化の進度
                VStack(spacing: 2) {
                    HStack {
                        Label("進化", systemImage: "sparkles")
                            .font(.system(size: 9).bold())
                            .foregroundColor(Theme.Colors.kappaGreenDark)
                        Spacer()
                        if entry.kappaStage >= (allKappas.first(where: { $0.id == entry.kappaId })?.numberOfStages ?? 3) {
                            Text("MAX")
                                .font(.system(size: 9, design: .monospaced).bold())
                                .foregroundColor(inkText.opacity(0.7))
                        } else {
                            Text("\(entry.kappaCurrentAmount) / \(entry.kappaGoal) ml")
                                .font(.system(size: 9, design: .monospaced).bold())
                                .foregroundColor(inkText.opacity(0.7))
                        }
                    }
                    customProgressBar(
                        value: entry.evolutionProgress,
                        color: Theme.Colors.kappaGreenDark,
                        height: 5
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 6)
                
                // クイック給水ボタン 3個 (コップ、ボトル、メガ)
                HStack(spacing: 8) {
                    WidgetDrinkButton(amount: 150, icon: "cup.and.saucer.fill", label: "コップ", inkText: inkText)
                    WidgetDrinkButton(amount: 300, icon: "drop.fill", label: "ボトル", inkText: inkText)
                    WidgetDrinkButton(amount: 500, icon: "takeoutbag.and.cup.and.straw.fill", label: "メガ", inkText: inkText)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Showcase Extra Large Layout (.systemExtraLarge)
    
    private var extraLargeView: some View {
        HStack(spacing: 0) {
            // 左側カラム：カッパ超巨大ショーケース (全面的表示) - 名前や「進化完了」テキストは完全に排除
            VStack(spacing: 0) {
                Spacer(minLength: 16)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(cardBg)
                        .handDrawnBorder(color: inkText.opacity(0.15), cornerRadius: 28)
                    
                    if let image = entry.kappaImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(inkText.opacity(0.3))
                            Text("No Image")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(inkText.opacity(0.5))
                        }
                    }
                }
                .frame(width: 290, height: 290) // 特大サイズの左半分をほぼ一杯に占有
                .shadow(color: inkText.opacity(0.04), radius: 8, x: 0, y: 4)
                
                Spacer(minLength: 16)
            }
            .frame(width: 330)
            
            // 縦の区切り線
            Rectangle()
                .fill(inkText.opacity(0.12))
                .frame(width: 1.2)
                .padding(.vertical, 24)
            
            // 右側カラム：進捗情報 ＆ 給水ボタン
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("カッパ観察日記")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(inkText)
                        .padding(.top, 24)
                    
                    // ダブルプログレスバー (スリム版)
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label("本日の水分量", systemImage: "drop.bubble.fill")
                                    .font(.system(size: 11).bold())
                                    .foregroundColor(inkText.opacity(0.8))
                                Spacer()
                                Text("\(entry.currentAmount) / \(entry.dailyGoal) ml")
                                    .font(.system(size: 11, design: .monospaced).bold())
                                    .foregroundColor(Theme.Colors.primaryBlue)
                            }
                            customProgressBar(
                                value: Double(entry.currentAmount) / Double(entry.dailyGoal),
                                color: Theme.Colors.primaryBlue,
                                height: 8
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label("進化の進捗", systemImage: "sparkles")
                                    .font(.system(size: 11).bold())
                                    .foregroundColor(inkText.opacity(0.8))
                                Spacer()
                                if entry.kappaStage >= (allKappas.first(where: { $0.id == entry.kappaId })?.numberOfStages ?? 3) {
                                    Text("MAX")
                                        .font(.system(size: 11, design: .monospaced).bold())
                                        .foregroundColor(Theme.Colors.kappaGreenDark)
                                } else {
                                    Text("\(entry.kappaCurrentAmount) / \(entry.kappaGoal) ml")
                                        .font(.system(size: 11, design: .monospaced).bold())
                                        .foregroundColor(Theme.Colors.kappaGreenDark)
                                }
                            }
                            customProgressBar(
                                value: entry.evolutionProgress,
                                color: Theme.Colors.kappaGreenDark,
                                height: 8
                            )
                        }
                    }
                    
                    // 手帳風の成長メモ - 名前や「進化完了」テキストは完全に排除
                    VStack(alignment: .leading, spacing: 4) {
                        Text("💧 毎日少しずつの積み重ねが、お皿を潤しカッパの急成長へと繋がります。")
                            .font(.system(size: 10))
                            .foregroundColor(inkText.opacity(0.65))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(cardBg)
                    .handDrawnBorder(color: inkText.opacity(0.1), cornerRadius: 10)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 16)
                
                // 給水ボタンのグリッド
                VStack(spacing: 8) {
                    HandDrawnDivider(color: inkText.opacity(0.1))
                        .frame(height: 3)
                    
                    HStack(spacing: 8) {
                        WidgetDrinkButton(amount: 150, icon: "cup.and.saucer.fill", label: "コップ", inkText: inkText)
                        WidgetDrinkButton(amount: 300, icon: "drop.fill", label: "ボトル", inkText: inkText)
                        WidgetDrinkButton(amount: 500, icon: "takeoutbag.and.cup.and.straw.fill", label: "メガ", inkText: inkText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Custom Segmented Progress Bar
    
    @ViewBuilder
    private func customProgressBar(value: Double, color: Color, height: CGFloat = 8) -> some View {
        let clampedValue = min(max(value, 0.0), 1.0)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 背景レール
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(inkText.opacity(0.06))
                    .frame(height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2)
                            .stroke(inkText.opacity(0.08), lineWidth: 0.6)
                    )
                
                // 進捗部分
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * clampedValue, height: height)
                    .shadow(color: color.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Widget Components

struct WidgetDrinkButton: View {
    let amount: Int
    let icon: String
    let label: String
    let inkText: Color
    
    var body: some View {
        Button(intent: AddWaterIntent(amount: amount)) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.primaryBlue)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(label)
                        .font(.system(size: 8).bold())
                        .foregroundColor(inkText.opacity(0.6))
                    Text("+\(amount)ml")
                        .font(.system(size: 9, design: .rounded).bold())
                        .foregroundColor(inkText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .background(Color(hex: "FFFDFB"))
            .cornerRadius(10)
            .handDrawnBorder(color: inkText.opacity(0.15), cornerRadius: 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget Definitions

@main
struct LofiKappaShowcaseWidget: Widget {
    let kind: String = "LofiKappaShowcaseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LofiKappaShowcaseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("カッパ観察ウィジェット")
        .description("カッパの姿を全面に大きく表示し、すばやく給水できるウィジェットです。")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}
