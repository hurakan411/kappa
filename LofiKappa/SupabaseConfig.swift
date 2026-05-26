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
    
    // おだんごかっぱのフォールバック用ファイル名（実際のアップロード名に適合）
    static let odangoFilenames = [
        "1_odango.png",
        "2_odango.png",
        "3_odango.png",
        "4_odango.png",
        "5_odango.png",
        "6_odango.png"
    ]
    
    // 金魚かっぱのフォールバック用ファイル名
    static let kingyoFilenames = [
        "1_kingyo.png",
        "2_kingyo.png",
        "3_kingyo.png",
        "4_kingyo.png",
        "5_kingyo.png",
        "6_kingyo.png"
    ]

    // 新規カッパ6種のフォールバック用ファイル名配列
    static let seaweedFilenames = [
        "seaweed_1.png", "seaweed_2.png", "seaweed_3.png", "seaweed_4.png", "seaweed_5.png"
    ]
    static let bonsaiFilenames = [
        "bonsai_1.png", "bonsai_2.png", "bonsai_3.png", "bonsai_4.png", "bonsai_5.png", "bonsai_6.png", "bonsai_7.png"
    ]
    static let karesansuiFilenames = [
        "karesansui_1.png", "karesansui_2.png", "karesansui_3.png", "karesansui_4.png", "karesansui_5.png", "karesansui_6.png"
    ]
    static let cyberFilenames = [
        "cyber_1.png", "cyber_2.png", "cyber_3.png", "cyber_4.png", "cyber_5.png", "cyber_6.png"
    ]
    static let creamsodaFilenames = [
        "creamsoda_1.png", "creamsoda_2.png", "creamsoda_3.png", "creamsoda_4.png", "creamsoda_5.png", "creamsoda_6.png", "creamsoda_7.png", "creamsoda_8.png"
    ]
    static let atrierFilenames = [
        "atrier_1.png", "atrier_2.png", "atrier_3.png", "atrier_4.png", "atrier_5.png", "atrier_6.png"
    ]
    
    /// カッパ種IDと進化ステージから、Supabase Storageの Public URLを返す
    static func imageUrl(for kappaId: String, stage: Int) -> URL? {
        let folderName = KappaData.find(by: kappaId)?.storageFolderName ?? "1_\(kappaId)"
        
        let fileName: String
        // 1. 動的に取得したファイル名マップがあるか確認
        if let dynamicFileName = SupabaseStorageManager.shared.fileName(for: kappaId, stage: stage) {
            fileName = dynamicFileName
        } else {
            // 2. なければフォールバック配列からマッチするものを探す（先頭数字、またはアンダースコア直後の数字）
            let matchBlock = { (name: String) -> Bool in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return name.contains("_\(stage).")
            }
            
            if kappaId == "gamer", let matchedFileName = gamerFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "odango", let matchedFileName = odangoFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "kingyo", let matchedFileName = kingyoFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "seaweed", let matchedFileName = seaweedFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "bonsai", let matchedFileName = bonsaiFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "karesansui", let matchedFileName = karesansuiFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "cyber", let matchedFileName = cyberFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "creamsoda", let matchedFileName = creamsodaFilenames.first(where: matchBlock) {
                fileName = matchedFileName
            } else if kappaId == "atrier", let matchedFileName = atrierFilenames.first(where: matchBlock) {
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
