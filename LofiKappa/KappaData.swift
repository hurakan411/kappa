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
        if id == "gamer" {
            return 7
        } else if id == "odango" || id == "kingyo" {
            return 6
        } else {
            return 5
        }
    }
    
    // ユーザーの1日目標量をもとに各ステージの閾値を動的に計算
    func scaledRequirements(dailyGoal: Int) -> [Int] {
        let total = Double(dailyGoal) * totalEvolutionMultiplier
        if numberOfStages == 7 {
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
    )
]
