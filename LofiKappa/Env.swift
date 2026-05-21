import Foundation

struct Env {
    private static var variables: [String: String] = {
        // メインバンドルから .env ファイルを探索
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ WARNING: .env file not found in main bundle.")
            return [:]
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            var dict: [String: String] = [:]
            
            content.enumerateLines { line, _ in
                // トリミングを行い、空行やコメント行 (#) をスキップ
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { return }
                
                // key=value の分割
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let val = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'/")) // クォーテーション等の除去
                    dict[key] = val
                }
            }
            print("ℹ️ INFO: Loaded .env successfully with keys: \(Array(dict.keys))")
            return dict
        } catch {
            print("⚠️ ERROR: Failed to parse .env file: \(error)")
            return [:]
        }
    }()
    
    /// 環境変数名から値を取得する。見つからない場合は nil を返します。
    static func get(_ key: String) -> String? {
        return variables[key]
    }
}
