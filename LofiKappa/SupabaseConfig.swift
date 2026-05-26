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
        "1_seaweed.png", "2_seaweed.png", "3_seaweed.png", "4_seaweed.png", "5_seaweed.png"
    ]
    static let bonsaiFilenames = [
        "1_bonsai.png", "2_bonsai.png", "3_bonsai.png", "4_bonsai.png", "5_bonsai.png", "6_bonsai.png", "7_bonsai.png"
    ]
    static let karesansuiFilenames = [
        "1_karesansui.png", "2_karesansui.png", "3_karesansui.png", "4_karesansui.png", "5_karesansui.png", "6_karesansui.png"
    ]
    static let cyberFilenames = [
        "1_cyber.png", "2_cyber.png", "3_cyber.png", "4_cyber.png", "5_cyber.png", "6_cyber.png"
    ]
    static let creamsodaFilenames = [
        "1_creamsoda.png", "2_creamsoda.png", "3_creamsoda.png", "4_creamsoda.png", "5_creamsoda.png", "6_creamsoda.png", "7_creamsoda.png", "8_creamsoda.png"
    ]
    static let atrierFilenames = [
        "1_atrier.png", "2_atrier.png", "3_atrier.png", "4_atrier.png", "5_atrier.png", "6_atrier.png"
    ]
    
    /// カッパ種IDと進化ステージから、Supabase Storage의 Public URLを返す
    static func imageUrl(for kappaId: String, stage: Int) -> URL? {
        let folderName = KappaData.find(by: kappaId)?.storageFolderName ?? "1_\(kappaId)"
        
        let fileName: String
        // 1. 動的に取得したファイル名マップがあるか確認
        if let dynamicFileName = SupabaseStorageManager.shared.fileName(for: kappaId, stage: stage) {
            fileName = dynamicFileName
        } else {
            // 2. なければフォールバック配列から先頭の数字が一致するものを探す
            if kappaId == "gamer",
               let matchedFileName = gamerFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "odango",
                      let matchedFileName = odangoFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "kingyo",
                      let matchedFileName = kingyoFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "seaweed",
                      let matchedFileName = seaweedFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "bonsai",
                      let matchedFileName = bonsaiFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "karesansui",
                      let matchedFileName = karesansuiFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "cyber",
                      let matchedFileName = cyberFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "creamsoda",
                      let matchedFileName = creamsodaFilenames.first(where: { name in
                if let firstChar = name.first, String(firstChar) == String(stage) {
                    return true
                }
                return false
            }) {
                fileName = matchedFileName
            } else if kappaId == "atrier",
                      let matchedFileName = atrierFilenames.first(where: { name in
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
