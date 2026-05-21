import Foundation

struct AppTexts {
    // MARK: - Tab Bar
    static let tabHome = String(localized: "tab_home", defaultValue: "ホーム")
    static let tabAlbum = String(localized: "tab_album", defaultValue: "図鑑")
    static let tabLog = String(localized: "tab_log", defaultValue: "記録")
    static let tabSettings = String(localized: "tab_settings", defaultValue: "設定")
    
    // MARK: - HomeView
    static let nextEvolution = String(localized: "home_next_evolution", defaultValue: "次の進化まで")
    static func remainingMl(_ ml: Int) -> String {
        let format = String(localized: "home_remaining_ml", defaultValue: "あと %d ml")
        return String(format: format, ml)
    }
    static let evolutionComplete = String(localized: "home_evolution_complete", defaultValue: "進化完了！")
    static let todaysWater = String(localized: "home_todays_water", defaultValue: "本日の水分量")
    static let raiseNextKappa = String(localized: "home_raise_next_kappa", defaultValue: "次のかっぱを育てる")
    
    static func stageText(_ stage: Int) -> String {
        switch stage {
        case 1: return String(localized: "stage_1", defaultValue: "Stage 1: 卵期")
        case 2: return String(localized: "stage_2", defaultValue: "Stage 2: ひび割れ期")
        case 3: return String(localized: "stage_3", defaultValue: "Stage 3: 幼生期")
        case 4: return String(localized: "stage_4", defaultValue: "Stage 4: 成長期")
        default: return String(localized: "stage_5", defaultValue: "Stage 5: 成体期")
        }
    }
    
    // MARK: - LogView
    static let logTitle = String(localized: "log_title", defaultValue: "記録")
    static let logToday = String(localized: "log_today", defaultValue: "本日の記録")
    static let logEmpty = String(localized: "log_empty", defaultValue: "まだ本日の記録はありません。")
    static let weekdays = [
        String(localized: "weekday_sun", defaultValue: "日"),
        String(localized: "weekday_mon", defaultValue: "月"),
        String(localized: "weekday_tue", defaultValue: "火"),
        String(localized: "weekday_wed", defaultValue: "水"),
        String(localized: "weekday_thu", defaultValue: "木"),
        String(localized: "weekday_fri", defaultValue: "金"),
        String(localized: "weekday_sat", defaultValue: "土")
    ]
    
    // MARK: - AlbumView
    static let albumTitle = String(localized: "album_title", defaultValue: "思い出アルバム")
    static let albumEmpty = String(localized: "album_empty", defaultValue: "まだかっぱがいません。水分補給をして解放しましょう！")
    
    // MARK: - SettingsView
    static let settingsTitle = String(localized: "settings_title", defaultValue: "設定")
    static let personalSection = String(localized: "settings_personal_section", defaultValue: "パーソナル設定")
    static let modeSelection = String(localized: "settings_mode_selection", defaultValue: "モード選択")
    static let genderFemale = String(localized: "settings_gender_female", defaultValue: "女性 (1500ml)")
    static let genderMale = String(localized: "settings_gender_male", defaultValue: "男性 (2000ml)")
    
    static let customGoalSection = String(localized: "settings_custom_goal_section", defaultValue: "1日の目標水分量")
    static let customGoalTitle = String(localized: "settings_custom_goal_title", defaultValue: "あなたに最適な目標量を分析する")
    static func currentGoalLabel(_ amount: Int) -> String {
        let format = String(localized: "settings_current_goal", defaultValue: "現在の目標: %dml")
        return String(format: format, amount)
    }
    static let resetGoalButton = String(localized: "settings_reset_goal", defaultValue: "簡易設定（性別）に戻す")
    
    // MARK: - WaterAnalysisView
    static let analysisTitle = String(localized: "analysis_title", defaultValue: "目標水分量の分析")
    
    static let q1Title = String(localized: "analysis_q1_title", defaultValue: "あなたのことを教えてください")
    static let q1WeightPlaceholder = String(localized: "analysis_q1_weight", defaultValue: "体重 (kg)")
    static let q1Age1 = String(localized: "analysis_q1_age1", defaultValue: "18〜54歳")
    static let q1Age2 = String(localized: "analysis_q1_age2", defaultValue: "55〜64歳")
    static let q1Age3 = String(localized: "analysis_q1_age3", defaultValue: "65歳以上")
    
    static let q2Title = String(localized: "analysis_q2_title", defaultValue: "普段の運動量や仕事のスタイルは？")
    static let q2Option1 = String(localized: "analysis_q2_opt1", defaultValue: "ほとんど動かない\n（デスクワーク・在宅中心）")
    static let q2Option2 = String(localized: "analysis_q2_opt2", defaultValue: "適度に動く\n（立ち仕事・徒歩移動が多い）")
    static let q2Option3 = String(localized: "analysis_q2_opt3", defaultValue: "日常的に運動する\n（週に数回のジム・肉体労働）")
    static let q2Option4 = String(localized: "analysis_q2_opt4", defaultValue: "激しく運動する\n（毎日のハードなトレーニング等）")
    
    static let q3Title = String(localized: "analysis_q3_title", defaultValue: "今の季節、またはお住まいの気候は？")
    static let q3Option1 = String(localized: "analysis_q3_opt1", defaultValue: "涼しい・寒い\n（春・秋・冬、エアコン環境）")
    static let q3Option2 = String(localized: "analysis_q3_opt2", defaultValue: "暖かい・汗ばむ\n（初夏・最高気温25°C〜30°C）")
    static let q3Option3 = String(localized: "analysis_q3_opt3", defaultValue: "厳しい暑さ\n（真夏・最高気温30°C以上）")
    
    static let q4Title = String(localized: "analysis_q4_title", defaultValue: "特別なステータス（任意）")
    static let q4Option1 = String(localized: "analysis_q4_opt1", defaultValue: "妊娠中")
    static let q4Option2 = String(localized: "analysis_q4_opt2", defaultValue: "授乳中")
    static let q4Option3 = String(localized: "analysis_q4_opt3", defaultValue: "あてはまらない / スキップ")
    
    static let analysisNext = String(localized: "analysis_next", defaultValue: "次へ")
    static let analysisComplete = String(localized: "analysis_complete", defaultValue: "分析完了！")
    static func analysisResult(_ amount: Int) -> String {
        let format = String(localized: "analysis_result", defaultValue: "あなたの最適な目標量は\n%dml です")
        return String(format: format, amount)
    }
    static let analysisApply = String(localized: "analysis_apply", defaultValue: "この目標量を設定する")
    
    static let myCupSection = String(localized: "settings_my_cup_section", defaultValue: "マイコップ設定")
    static func cupLabel(_ index: Int) -> String {
        let format = String(localized: "settings_cup_label", defaultValue: "コップ %d")
        return String(format: format, index)
    }
    
    static let dataInit = String(localized: "settings_data_init", defaultValue: "データ初期化")
    
    // MARK: - Kappa Data Names & Descriptions
    static func kappaName(_ key: String, defaultName: String) -> String {
        return NSLocalizedString(key, value: defaultName, comment: "")
    }
    static func kappaDesc(_ key: String, defaultDesc: String) -> String {
        return NSLocalizedString(key, value: defaultDesc, comment: "")
    }
}
