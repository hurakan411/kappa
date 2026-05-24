import Foundation
import SwiftUI

// メリットデータの構造体
struct HydrationBenefit {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

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
    
    // MARK: - Onboarding
    static let onboardingStoryLines = [
        String(localized: "onboarding_story_1", defaultValue: "古来より日本に伝わる、"),
        String(localized: "onboarding_story_2", defaultValue: "伝説の生き物、河童。"),
        String(localized: "onboarding_story_3", defaultValue: "彼らの頭にあるお皿には、"),
        String(localized: "onboarding_story_4", defaultValue: "常に満ちる水が必要でした。"),
        String(localized: "onboarding_story_5", defaultValue: "お皿の水が乾けば、"),
        String(localized: "onboarding_story_6", defaultValue: "その生命も"),
        String(localized: "onboarding_story_7", defaultValue: "失われてしまうのです…。")
    ]
    
    static let onboardingHumanTitle = String(localized: "onboarding_human_title", defaultValue: "人間も河童みたいなもの")
    static let onboardingHumanMessage = String(localized: "onboarding_human_message", defaultValue: "河童のお皿が乾いてはいけないように、\n私たち人間もまた、\n日々の給水を絶やしてはいけないのです。")
    
    static let onboardingBenefitsTitle = String(localized: "onboarding_benefits_title", defaultValue: "お水を飲む４つのメリット")
    static let onboardingBenefitsSubtitle = String(localized: "onboarding_benefits_subtitle", defaultValue: "カードをタップして詳細をご覧ください")
    
    static let onboardingBenefits = [
        HydrationBenefit(
            icon: "flame.fill",
            iconColor: .orange,
            title: String(localized: "onboarding_benefit1_title", defaultValue: "① 代謝アップ"),
            subtitle: String(localized: "onboarding_benefit1_sub", defaultValue: "痩せやすい体へ"),
            description: String(localized: "onboarding_benefit1_desc", defaultValue: "水分が体に満たされると血液の巡りが良くなり全身の基礎代謝がアップ。何もしなくても消費されるカロリーが増え、脂肪燃焼効率も高まります。")
        ),
        HydrationBenefit(
            icon: "sparkles",
            iconColor: Theme.Colors.primaryBlue,
            title: String(localized: "onboarding_benefit2_title", defaultValue: "② 美肌効果"),
            subtitle: String(localized: "onboarding_benefit2_sub", defaultValue: "内側からの潤い"),
            description: String(localized: "onboarding_benefit2_desc", defaultValue: "高価な化粧水よりも、内側からの水分補給が美肌への近道。ターンオーバーが正常化し、乾燥の改善、ハリ・ツヤや顔の透明感が向上します。")
        ),
        HydrationBenefit(
            icon: "leaf.fill",
            iconColor: .green,
            title: String(localized: "onboarding_benefit3_title", defaultValue: "③ デトックス"),
            subtitle: String(localized: "onboarding_benefit3_sub", defaultValue: "便秘・むくみ解消"),
            description: String(localized: "onboarding_benefit3_desc", defaultValue: "腸内環境を整えてお通じをスムーズに。水分不足になると体は逆に水をため込もうとしてむくむため、しっかり飲んで老廃物を流し出すのが正解です。")
        ),
        HydrationBenefit(
            icon: "brain.fill",
            iconColor: .purple,
            title: String(localized: "onboarding_benefit4_title", defaultValue: "④ 疲労軽減"),
            subtitle: String(localized: "onboarding_benefit4_sub", defaultValue: "集中力の維持"),
            description: String(localized: "onboarding_benefit4_desc", defaultValue: "わずか1〜2%の水分不足でもだるさや集中力低下の原因に。脳と体のパフォーマンスをベストに保つための、最も簡単なスイッチです。")
        )
    ]
    
    static let onboardingBenefitPreconditionTitle = String(localized: "onboarding_precondition_title", defaultValue: "効果を最大にするための「大前提」")
    static let onboardingBenefitPreconditionDesc = String(localized: "onboarding_precondition_desc", defaultValue: "人が一度に吸収できる水分は約200〜250ml（コップ1杯分）です。1日7〜8回に分けこまめに飲むのが最大のコツです。")
    
    static let onboardingGuideTitle = String(localized: "onboarding_guide_title", defaultValue: "アプリの使い方")
    static let onboardingGuideSubtitle = String(localized: "onboarding_guide_subtitle", defaultValue: "数字をタップして機能をご確認ください")
    static let onboardingGuideHint = String(localized: "onboarding_guide_hint", defaultValue: "スワイプ、またはカード外のタップで次へ進みます")
    
    static let onboardingGuideSteps = [
        HydrationBenefit(
            icon: "plus.circle.fill",
            iconColor: Theme.Colors.primaryBlue,
            title: String(localized: "onboarding_guide1_title", defaultValue: "水分補給を記録する"),
            subtitle: "STEP 1",
            description: String(localized: "onboarding_guide1_desc", defaultValue: "コップのアイコンをワンタップするだけで、飲んだ水分量を素早く記録できます。毎日の給水をスムーズに習慣化しましょう。")
        ),
        HydrationBenefit(
            icon: "sparkles",
            iconColor: .orange,
            title: String(localized: "onboarding_guide2_title", defaultValue: "水を飲んでカッパを育てる"),
            subtitle: "STEP 2",
            description: String(localized: "onboarding_guide2_desc", defaultValue: "あなたが水を飲むと、カッパに水が届きます。たくさん飲んで様々なカッパを現代に甦らせましょう。")
        ),
        HydrationBenefit(
            icon: "square.text.square.fill",
            iconColor: .purple,
            title: String(localized: "onboarding_guide3_title", defaultValue: "ウィジェットで瞬時に給水"),
            subtitle: "STEP 3",
            description: String(localized: "onboarding_guide3_desc", defaultValue: "ホーム画面にウィジェットを配置すれば、アプリを開かずにホーム画面からワンタップで瞬時に記録を更新できます。")
        )
    ]
    
    static let onboardingGoalSetupTitle = String(localized: "onboarding_goal_title", defaultValue: "お水の目標を設定しましょう")
    static let onboardingGoalSetupDesc = String(localized: "onboarding_goal_desc", defaultValue: "河童のお皿を潤すために、あなたに最適な１日の補給目標量を自動で分析・診断します。")
    static let onboardingGoalSetupButton = String(localized: "onboarding_goal_button", defaultValue: "最適な目標量を診断する")
    
    // MARK: - Share Text
    static func shareText(kappaName: String, stageText: String, currentAmount: Int) -> String {
        let format = String(localized: "share_message_format", defaultValue: "#LofiKappa カッパ育成中！今日の給水量: %dml ")
        return String(format: format, kappaName, stageText, currentAmount)
    }
    
    // MARK: - Reminders
    static let reminderSectionTitle = String(localized: "reminder_section_title", defaultValue: "通知")
    static let reminderToggleTitle = String(localized: "reminder_toggle_title", defaultValue: "給水リマインダーかっぱ")
    static let reminderToggleDescription = String(localized: "reminder_toggle_desc", defaultValue: "お水を最後に飲んでから2時間後と3時間後にカッパが通知します（給水するとリセットされます）")
    static let reminderNotificationTitle = String(localized: "notification_title", defaultValue: "給水タイムかっぱ！")
    static let reminderNotificationBody1 = String(localized: "notification_body_1", defaultValue: "お皿が少し乾いてきたかっぱ！コップ1杯の水を飲んで潤すかっぱ〜。")
    static let reminderNotificationBody2 = String(localized: "notification_body_2", defaultValue: "お皿がからからになってきちゃったかっぱ…！お水を飲むのを忘れないでね。")
}
