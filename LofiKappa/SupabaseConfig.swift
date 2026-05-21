import Foundation

struct SupabaseConfig {
    /// .env ファイルからプロジェクトIDを取得。見つからない場合はフォールバック値を使用
    static var projectRef: String {
        Env.get("SUPABASE_PROJECT_REF") ?? "YOUR_SUPABASE_PROJECT_ID"
    }
    
    /// .env からベースURLを取得。取得できない場合は projectRef をベースに組み立てたデフォルトURLを返す
    static var supabaseUrl: String {
        Env.get("SUPABASE_URL") ?? "https://\(projectRef).supabase.co"
    }
    
    /// .env から Anon Key を取得
    static var anonKey: String? {
        Env.get("SUPABASE_ANON_KEY")
    }
    
    static let bucketName = "kappa"
    
    // 正しいファイル名（拡張子が.jpgのものが含まれます）
    static let gamerFilenames = [
        "1_kappa_egg_1.png",
        "2_kappa_egg_cracked_1.png",
        "3_kappa_baby_1.png",
        "4_kappa_gamer_baby.png",
        "5_kappa_gamer_child.jpg",
        "6_kappa_gamer_adult.jpg",
        "7_kappa_gamer_pro.jpg"
    ]
    
    /// カッパ種IDと進化ステージから、Supabase Storage의 Public URLを返す
    static func imageUrl(for kappaId: String, stage: Int) -> URL? {
        let folderName = KappaData.find(by: kappaId)?.storageFolderName ?? "1_\(kappaId)"
        
        let fileName: String
        // 1. 動的に取得したファイル名マップがあるか確認
        if let dynamicFileName = SupabaseStorageManager.shared.fileName(for: kappaId, stage: stage) {
            fileName = dynamicFileName
        } else {
            // 2. なければフォールバック配列から先頭の数字が一致するものを探す (gamerのみフォールバックあり)
            if kappaId == "gamer",
               let matchedFileName = gamerFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else {
                return nil
            }
        }
        
        let baseUrl = supabaseUrl.hasSuffix("/") ? String(supabaseUrl.dropLast()) : supabaseUrl
        let urlString = "\(baseUrl)/storage/v1/object/public/\(bucketName)/\(folderName)/\(fileName)"
        return URL(string: urlString)
    }
}
