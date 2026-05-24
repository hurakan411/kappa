import Foundation

struct KappaData {
    let id: String
    let name: String
    let description: String
    
    // 1日の目標量の何倍で完全進化するか（カッパごとの難易度）
    // 例: 1.0 = 1日分でコンプリート、2.0 = 2日分必要
    let totalEvolutionMultiplier: Double
    
    // Supabase Storage上のフォルダ名（必須プロパティとしてここでハードコード定義）
    let storageFolderName: String
    
    // 段階進化の最大ステージ数（デフォルトは5。ゲーマーかっぱは7、おだんごかっぱは6）
    var numberOfStages: Int {
        if id == "gamer" {
            return 7
        } else if id == "odango" {
            return 6
        } else {
            return 5
        }
    }
    
    // ユーザーの1日目標量をもとに各ステージの閾値を動的に計算
    func scaledRequirements(dailyGoal: Int) -> [Int] {
        let total = Double(dailyGoal) * totalEvolutionMultiplier
        if numberOfStages == 7 {
            // 7段階進化の場合：15%, 30%, 45%, 60%, 75%, 100% の6つの閾値
            return [
                Int(total * 0.15),
                Int(total * 0.30),
                Int(total * 0.45),
                Int(total * 0.60),
                Int(total * 0.75),
                Int(total)
            ]
        } else if numberOfStages == 6 {
            // 6段階進化の場合：20%, 40%, 60%, 80%, 100% の5つの閾値
            return [
                Int(total * 0.20),
                Int(total * 0.40),
                Int(total * 0.60),
                Int(total * 0.80),
                Int(total)
            ]
        } else {
            // 5段階進化の場合：20%, 40%, 60%, 100% の4つの閾値
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
        name: AppTexts.kappaName("kappa_gamer_name", defaultName: "ゲーマーかっぱ"),
        description: AppTexts.kappaDesc("kappa_gamer_desc", defaultDesc: "エナジードリンクばかり飲んでお皿が少しネオン色になっている。"),
        totalEvolutionMultiplier: 1.6,
        storageFolderName: "1_gamer" // 👈 ここで明示的に定義
    ),
    // 難易度: 普通 (1.2日)
    KappaData(
        id: "odango",
        name: AppTexts.kappaOdangoName,
        description: AppTexts.kappaOdangoDesc,
        totalEvolutionMultiplier: 1.2,
        storageFolderName: "2_odango"
    )
]
