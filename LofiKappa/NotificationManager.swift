import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// 通知の利用許可をリクエストする
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("🔴 [NotificationManager] Error requesting auth: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// 給水リマインダー通知をスケジュールする（最後の給水から2時間後、3時間後の計2回）
    func scheduleReminder() {
        // 設定が有効でなければスケジュールしない
        guard UserDefaults.standard.bool(forKey: "isReminderEnabled") else { return }
        
        // 既存の未送信リマインダーを一度キャンセル
        cancelAllReminders()
        
        // 1回目のリマインド（2時間後 = 7200秒）
        let content1 = UNMutableNotificationContent()
        content1.title = AppTexts.reminderNotificationTitle
        content1.body = AppTexts.reminderNotificationBody1
        content1.sound = .default
        
        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
        let request1 = UNNotificationRequest(identifier: "water_reminder_1", content: content1, trigger: trigger1)
        
        // 2回目のリマインド（追い通知: 3時間後 = 10800秒）
        let content2 = UNMutableNotificationContent()
        content2.title = AppTexts.reminderNotificationTitle
        content2.body = AppTexts.reminderNotificationBody2
        content2.sound = .default
        
        let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: 10800, repeats: false)
        let request2 = UNNotificationRequest(identifier: "water_reminder_2", content: content2, trigger: trigger2)
        
        // 通知登録
        UNUserNotificationCenter.current().add(request1) { error in
            if let error = error {
                print("🔴 [NotificationManager] Failed to add reminder 1: \(error)")
            } else {
                print("🟢 [NotificationManager] Successfully scheduled reminder 1 (2 hours later)")
            }
        }
        
        UNUserNotificationCenter.current().add(request2) { error in
            if let error = error {
                print("🔴 [NotificationManager] Failed to add reminder 2: \(error)")
            } else {
                print("🟢 [NotificationManager] Successfully scheduled reminder 2 (3 hours later / chase)")
            }
        }
    }
    
    /// スケジュールされているすべてのリマインダー通知をキャンセルする
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["water_reminder_1", "water_reminder_2"])
        print("ℹ️ [NotificationManager] Cancelled all pending reminders")
    }
    
    /// 水分補給の進捗状況に応じてスマートにリセット（給水時や目標達成時に呼び出す）
    func resetReminder(isTargetCompleted: Bool) {
        cancelAllReminders()
        
        if isTargetCompleted {
            print("🎉 [NotificationManager] Target is completed! Reminders will not be scheduled for today.")
        } else {
            // 目標がまだ未達成の場合は、次のリマインダーをスケジュール
            scheduleReminder()
        }
    }
}
