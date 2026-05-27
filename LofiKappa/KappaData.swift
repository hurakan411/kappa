import Foundation

struct KappaData {
    let id: String
    private let nameKey: String
    private let defaultName: String
    private let descKey: String
    private let defaultDesc: String
    
    var name: String {
        LanguageManager.shared.localizedString(forKey: nameKey, defaultValue: defaultName)
    }
    
    var description: String {
        LanguageManager.shared.localizedString(forKey: descKey, defaultValue: defaultDesc)
    }
    
    // 1日の目標量の何倍で完全進化するか（カッパごとの難易度）
    let totalEvolutionMultiplier: Double
    
    // Supabase Storage上のフォルダ名
    let storageFolderName: String
    
    init(id: String, nameKey: String, defaultName: String, descKey: String, defaultDesc: String, totalEvolutionMultiplier: Double, storageFolderName: String) {
        self.id = id
        self.nameKey = nameKey
        self.defaultName = defaultName
        self.descKey = descKey
        self.defaultDesc = defaultDesc
        self.totalEvolutionMultiplier = totalEvolutionMultiplier
        self.storageFolderName = storageFolderName
    }
    
    // 段階進化の最大ステージ数
    var numberOfStages: Int {
        if id == "creamsoda" {
            return 8
        } else if id == "gamer" || id == "bonsai" {
            return 7
        } else if id == "odango" || id == "kingyo" || id == "karesansui" || id == "cyber" || id == "atrier" {
            return 6
        } else {
            return 5
        }
    }
    
    // ユーザーの1日目標量をもとに各ステージの閾値を動的に計算
    func scaledRequirements(dailyGoal: Int) -> [Int] {
        let total = Double(dailyGoal) * totalEvolutionMultiplier
        if numberOfStages == 8 {
            return [
                Int(total * 0.14),
                Int(total * 0.28),
                Int(total * 0.42),
                Int(total * 0.56),
                Int(total * 0.70),
                Int(total * 0.84),
                Int(total)
            ]
        } else if numberOfStages == 7 {
            return [
                Int(total * 0.15),
                Int(total * 0.30),
                Int(total * 0.45),
                Int(total * 0.60),
                Int(total * 0.75),
                Int(total)
            ]
        } else if numberOfStages == 6 {
            return [
                Int(total * 0.20),
                Int(total * 0.40),
                Int(total * 0.60),
                Int(total * 0.80),
                Int(total)
            ]
        } else {
            return [
                Int(total * 0.20),
                Int(total * 0.40),
                Int(total * 0.60),
                Int(total)
            ]
        }
    }
}

extension KappaData {
    static func find(by id: String) -> KappaData? {
        allKappas.first { $0.id == id }
    }
}

let allKappas: [KappaData] = [
    // 難易度: 難しい (1.6日)
    KappaData(
        id: "gamer",
        nameKey: "kappa_gamer_name",
        defaultName: "ゲーマーかっぱ",
        descKey: "kappa_gamer_desc",
        defaultDesc: "エナジードリンクばかり飲んでお皿が少しネオン色になっている。",
        totalEvolutionMultiplier: 1.6,
        storageFolderName: "1_gamer"
    ),
    // 難易度: 普通 (1.2日)
    KappaData(
        id: "odango",
        nameKey: "kappa_odango_name",
        defaultName: "おだんごかっぱ",
        descKey: "kappa_odango_desc",
        defaultDesc: "お皿の上にお団子がちょこんと乗った、和菓子が大好きな甘党かっぱ。",
        totalEvolutionMultiplier: 1.2,
        storageFolderName: "2_odango"
    ),
    // 難易度: 普通 (1.2日)
    KappaData(
        id: "kingyo",
        nameKey: "kappa_kingyo_name",
        defaultName: "金魚かっぱ",
        descKey: "kappa_kingyo_desc",
        defaultDesc: "お皿の上を金魚が優雅に泳ぐ、涼しげで水が大好きな風流かっぱ。",
        totalEvolutionMultiplier: 1.2,
        storageFolderName: "3_kingyo"
    ),
    // 難易度: 普通 (1.1日)
    KappaData(
        id: "seaweed",
        nameKey: "kappa_seaweed_name",
        defaultName: "のりかっぱ",
        descKey: "kappa_seaweed_desc",
        defaultDesc: "お皿のまわりに焼き海苔を巻いた、磯の香りが漂うおにぎり大好きなかっぱ。",
        totalEvolutionMultiplier: 1.1,
        storageFolderName: "4_seaweed"
    ),
    // 難易度: 難しい (1.5日)
    KappaData(
        id: "bonsai",
        nameKey: "kappa_bonsai_name",
        defaultName: "盆栽かっぱ",
        descKey: "kappa_bonsai_desc",
        defaultDesc: "お皿の上に立派な松の盆栽を育てている、とても落ち着きのある高尚なかっぱ。",
        totalEvolutionMultiplier: 1.5,
        storageFolderName: "5_bonsai"
    ),
    // 難易度: 普通 (1.3日)
    KappaData(
        id: "karesansui",
        nameKey: "kappa_karesansui_name",
        defaultName: "枯山水かっぱ",
        descKey: "kappa_karesansui_desc",
        defaultDesc: "お皿に白い砂と小石を配し、見事な枯山水の庭園を描き出したわびさび深いかっぱ。",
        totalEvolutionMultiplier: 1.3,
        storageFolderName: "6_karesansui"
    ),
    // 難易度: 普通 (1.3日)
    KappaData(
        id: "cyber",
        nameKey: "kappa_cyber_name",
        defaultName: "サイバーかっぱ",
        descKey: "kappa_cyber_desc",
        defaultDesc: "電脳世界からやってきた、ホログラムのお皿がサイケデリックに発光する未来派かっぱ。",
        totalEvolutionMultiplier: 1.3,
        storageFolderName: "7_cyber"
    ),
    // 難易度: 非常に難しい (1.7日)
    KappaData(
        id: "creamsoda",
        nameKey: "kappa_creamsoda_name",
        defaultName: "クリームソーダかっぱ",
        descKey: "kappa_creamsoda_desc",
        defaultDesc: "お皿がメロンソーダで満たされ、アイスクリームとチェリーを乗せた、レトロポップなかっぱ。",
        totalEvolutionMultiplier: 1.7,
        storageFolderName: "8_creamsoda"
    ),
    // 難易度: 普通 (1.3日)
    KappaData(
        id: "atrier",
        nameKey: "kappa_atrier_name",
        defaultName: "アトリエかっぱ",
        descKey: "kappa_atrier_desc",
        defaultDesc: "お皿をパレットにしてカラフルな絵の具を溶かしている、芸術家肌でクリエイティブなかっぱ。",
        totalEvolutionMultiplier: 1.3,
        storageFolderName: "9_atrier"
    ),
    // 難易度: 普通 (1.3日)
    KappaData(
        id: "surf",
        nameKey: "kappa_surf_name",
        defaultName: "波乗りかっぱ",
        descKey: "kappa_surf_desc",
        defaultDesc: "お皿の上に波をまとわせ、サーフボードでスタイリッシュに波を乗りこなす、アクティブで夏が大好きなかっぱ。",
        totalEvolutionMultiplier: 1.3,
        storageFolderName: "10_surf"
    )
]
