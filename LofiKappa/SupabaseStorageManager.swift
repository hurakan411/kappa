import Foundation
import Combine

class SupabaseStorageManager: ObservableObject {
    static let shared = SupabaseStorageManager()
    
    @Published var fileMap: [String: [Int: String]] = [:] // [kappaId: [stage: fileName]]
    @Published var isLoading = false
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDatabase.appGroupIdentifier)
    }
    
    private init() {
        // 起動時にキャッシュから復元
        restoreFromCache()
    }
    
    /// キャッシュされたファイル名を取得する
    func fileName(for kappaId: String, stage: Int) -> String? {
        return fileMap[kappaId]?[stage]
    }
    
    /// UserDefaults からキャッシュを復元する
    private func restoreFromCache() {
        for kappa in allKappas {
            let cacheKey = "widget_fileMap_\(kappa.id)"
            if let cached = sharedDefaults?.dictionary(forKey: cacheKey) as? [String: String] {
                var restoredMap: [Int: String] = [:]
                for (key, value) in cached {
                    if let intKey = Int(key) {
                        restoredMap[intKey] = value
                    }
                }
                if !restoredMap.isEmpty {
                    fileMap[kappa.id] = restoredMap
                    print("🟢 [SupabaseStorageManager] Restored cache for \(kappa.id): \(restoredMap)")
                }
            }
        }
    }
    
    /// fileMap を UserDefaults にキャッシュする
    private func saveToCache(kappaId: String, stageMap: [Int: String]) {
        let cacheKey = "widget_fileMap_\(kappaId)"
        var stringKeyMap: [String: String] = [:]
        for (key, value) in stageMap {
            stringKeyMap[String(key)] = value
        }
        sharedDefaults?.set(stringKeyMap, forKey: cacheKey)
        sharedDefaults?.synchronize()
    }
    
    /// 特定のカッパ種のファイルリストを取得し、ステージ番号とファイル名のマップを更新する
    func fetchFileList(for kappaId: String) {
        // すでにロード済みの場合はスキップ
        guard fileMap[kappaId] == nil else { return }
        
        let folderName = KappaData.find(by: kappaId)?.storageFolderName ?? "1_\(kappaId)"
        guard let url = URL(string: "\(SupabaseConfig.supabaseUrl)/storage/v1/object/list/\(SupabaseConfig.bucketName)") else {
            print("🔴 [SupabaseStorageManager] Invalid Supabase URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let anonKey = SupabaseConfig.anonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ [SupabaseStorageManager] Supabase Anon Key is not set")
        }
        
        let body: [String: Any] = [
            "prefix": folderName + "/",
            "limit": 100,
            "offset": 0,
            "sortBy": [
                "column": "name",
                "order": "asc"
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("🔴 [SupabaseStorageManager] Failed to serialize request body: \(error)")
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            if let error = error {
                print("🔴 [SupabaseStorageManager] Network error fetching file list: \(error)")
                return
            }
            
            guard let data = data else {
                print("🔴 [SupabaseStorageManager] No data returned from Supabase Storage API")
                return
            }
            
            // レスポンスのデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🟢 [SupabaseStorageManager] Raw Storage API Response: \(jsonString)")
            }
            
            do {
                struct SupabaseFile: Decodable {
                    let name: String
                }
                let files = try JSONDecoder().decode([SupabaseFile].self, from: data)
                
                var stageMap: [Int: String] = [:]
                
                for file in files {
                    // prefixを指定しているので、通常ファイル名のみ（またはフォルダ名を含むパス）が返る
                    // パス全体であっても最後のコンポーネントを取り出す
                    let cleanName = URL(fileURLWithPath: file.name).lastPathComponent
                    
                    // ステージ番号として判定するロジック
                    // 1. 先頭の文字が数字である場合 (例: "1_odango.png")
                    if let firstChar = cleanName.first,
                       let stage = Int(String(firstChar)) {
                        stageMap[stage] = cleanName
                    }
                    // 2. アンダースコアの後にステージ数がくる場合 (例: "seaweed_1.png")
                    else {
                        let nameWithoutExtension = (cleanName as NSString).deletingPathExtension
                        if let lastPart = nameWithoutExtension.components(separatedBy: "_").last,
                           let stage = Int(lastPart) {
                            stageMap[stage] = cleanName
                        }
                    }
                }
                
                print("🟢 [SupabaseStorageManager] Dynamic Map parsed for \(kappaId): \(stageMap)")
                
                // 空のマップはキャッシュしない（次回起動時にリトライできるようにする）
                guard !stageMap.isEmpty else {
                    print("⚠️ [SupabaseStorageManager] Empty map for \(kappaId), not caching (will retry later)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.fileMap[kappaId] = stageMap
                }
                
                // UserDefaults にもキャッシュ（ウィジェットとの共有用）
                self?.saveToCache(kappaId: kappaId, stageMap: stageMap)
            } catch {
                print("🔴 [SupabaseStorageManager] Failed to decode API response: \(error)")
            }
        }.resume()
    }
}
