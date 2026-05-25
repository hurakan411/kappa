import Foundation
import Combine
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case japanese = "ja"
    case english = "en"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .system:
            return LanguageManager.shared.localizedString(forKey: "lang_system", defaultValue: "システム設定")
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var selectedLanguage: AppLanguage = .system {
        didSet {
            UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)?.set(selectedLanguage.rawValue, forKey: "app_language")
            UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)?.synchronize()
            // 値の変更を通知
            objectWillChange.send()
        }
    }
    
    private init() {
        let saved = UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)?.string(forKey: "app_language") ?? "system"
        self.selectedLanguage = AppLanguage(rawValue: saved) ?? .system
    }
    
    var currentLanguageCode: String {
        if selectedLanguage == .system {
            let lang = Bundle.main.preferredLocalizations.first ?? "en"
            return lang.hasPrefix("ja") ? "ja" : "en"
        } else {
            return selectedLanguage.rawValue
        }
    }
    
    var bundle: Bundle {
        let code = currentLanguageCode
        // 開発環境と本番環境の両方でリソースが配置されたバンドルを探索
        // AppおよびWidgetの両ターゲットで正しく .lproj を参照できるようにする
        for bundle in Bundle.allBundles {
            if let path = bundle.path(forResource: code, ofType: "lproj"),
               let langBundle = Bundle(path: path) {
                return langBundle
            }
        }
        return Bundle.main
    }
    
    func localizedString(forKey key: String, defaultValue: String) -> String {
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: defaultValue, comment: "")
    }
}
