import Foundation
import SwiftData

public final class SharedDatabase {
    public static let appGroupIdentifier = "group.com.lofikappa.app"
    
    public static let schema = Schema([
        UserSettings.self,
        DailyWaterLog.self,
        IntakeRecord.self,
        KappaCollection.self,
    ])
    
    public static var container: ModelContainer = {
        let modelConfiguration: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let databaseURL = groupURL.appendingPathComponent("LofiKappa.sqlite")
            modelConfiguration = ModelConfiguration(schema: schema, url: databaseURL)
            print("🟢 [SharedDatabase] Using App Group container at: \(databaseURL.path)")
        } else {
            let fallbackURL = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("LofiKappa.sqlite")
            try? FileManager.default.createDirectory(
                at: fallbackURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            modelConfiguration = ModelConfiguration(schema: schema, url: fallbackURL)
            print("⚠️ [SharedDatabase] App Group NOT available. Falling back to: \(fallbackURL.path)")
        }
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("🔴 [SharedDatabase] Could not create ModelContainer: \(error)")
        }
    }()
}

// MARK: - WidgetDataSync
// UserDefaults(suiteName:) を使った確実なクロスプロセス同期レイヤー
// SwiftData はプロセス間の変更通知をサポートしていないため、
// ウィジェット ↔ アプリ間のデータ共有にはこの仕組みが必要

public struct WidgetDataSync {
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)
    }
    
    // キー定数
    private static let kDateString = "wds_dateString"
    private static let kCurrentAmount = "wds_currentAmount"
    private static let kKappaCurrentAmount = "wds_kappaCurrentAmount"
    private static let kIsCompleted = "wds_isCompleted"
    private static let kTargetKappaId = "wds_targetKappaId"
    private static let kDailyGoal = "wds_dailyGoal"
    private static let kTimestamp = "wds_timestamp"
    
    /// ウィジェットまたはアプリが給水した直後に呼ぶ。最新の状態を UserDefaults に書き込む。
    public static func save(
        dateString: String,
        currentAmount: Int,
        kappaCurrentAmount: Int,
        isCompleted: Bool,
        targetKappaId: String,
        dailyGoal: Int
    ) {
        guard let defaults = sharedDefaults else {
            print("⚠️ [WidgetDataSync] Cannot access shared UserDefaults (App Group unavailable)")
            return
        }
        defaults.set(dateString, forKey: kDateString)
        defaults.set(currentAmount, forKey: kCurrentAmount)
        defaults.set(kappaCurrentAmount, forKey: kKappaCurrentAmount)
        defaults.set(isCompleted, forKey: kIsCompleted)
        defaults.set(targetKappaId, forKey: kTargetKappaId)
        defaults.set(dailyGoal, forKey: kDailyGoal)
        defaults.set(Date().timeIntervalSince1970, forKey: kTimestamp)
        defaults.synchronize()
        print("🟢 [WidgetDataSync] Saved: date=\(dateString), amount=\(currentAmount), kappa=\(kappaCurrentAmount), completed=\(isCompleted)")
    }
    
    /// データを読み込む。タイムスタンプが 0 なら同期データなし。
    public static func load() -> SyncData? {
        guard let defaults = sharedDefaults else {
            print("⚠️ [WidgetDataSync] Cannot access shared UserDefaults (App Group unavailable)")
            return nil
        }
        let timestamp = defaults.double(forKey: kTimestamp)
        guard timestamp > 0 else { return nil }
        
        return SyncData(
            dateString: defaults.string(forKey: kDateString) ?? "",
            currentAmount: defaults.integer(forKey: kCurrentAmount),
            kappaCurrentAmount: defaults.integer(forKey: kKappaCurrentAmount),
            isCompleted: defaults.bool(forKey: kIsCompleted),
            targetKappaId: defaults.string(forKey: kTargetKappaId) ?? "gamer",
            dailyGoal: defaults.integer(forKey: kDailyGoal),
            timestamp: timestamp
        )
    }
    
    public struct SyncData {
        public let dateString: String
        public let currentAmount: Int
        public let kappaCurrentAmount: Int
        public let isCompleted: Bool
        public let targetKappaId: String
        public let dailyGoal: Int
        public let timestamp: Double
    }
}
