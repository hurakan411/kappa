import Foundation
import Combine
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var selectedLanguage: AppLanguage = .english {
        didSet {
            UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)?.set(selectedLanguage.rawValue, forKey: "app_language")
            UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)?.synchronize()
            // 値の変更を通知
            objectWillChange.send()
        }
    }
    
    private init() {
        let sharedDefaults = UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)
        if let saved = sharedDefaults?.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: saved) {
            self.selectedLanguage = lang
        } else {
            // 初回起動時: デバイスの優先言語を検出してデフォルトを設定
            let preferred = Bundle.main.preferredLocalizations.first ?? "en"
            let defaultLang: AppLanguage = preferred.hasPrefix("ja") ? .japanese : .english
            self.selectedLanguage = defaultLang
            
            // UserDefaultsに永続化
            sharedDefaults?.set(defaultLang.rawValue, forKey: "app_language")
            sharedDefaults?.synchronize()
        }
    }
    
    var currentLanguageCode: String {
        return selectedLanguage.rawValue
    }
    
    var bundle: Bundle {
        let code = currentLanguageCode
        // まずはメインアプリのバンドルを最優先で探索する
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return langBundle
        }
        // 見つからない場合は他のすべてのバンドルを探索（開発環境やウィジェットターゲットなどのため）
        for bundle in Bundle.allBundles {
            if bundle != Bundle.main,
               let path = bundle.path(forResource: code, ofType: "lproj"),
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
