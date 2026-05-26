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
    static var tabHome: String { LanguageManager.shared.localizedString(forKey: "tab_home", defaultValue: "ホーム") }
    static var tabAlbum: String { LanguageManager.shared.localizedString(forKey: "tab_album", defaultValue: "図鑑") }
    static var tabLog: String { LanguageManager.shared.localizedString(forKey: "tab_log", defaultValue: "記録") }
    static var tabSettings: String { LanguageManager.shared.localizedString(forKey: "tab_settings", defaultValue: "設定") }
    
    // MARK: - HomeView
    static var nextEvolution: String { LanguageManager.shared.localizedString(forKey: "home_next_evolution", defaultValue: "次の進化まで") }
    static func remainingMl(_ ml: Int) -> String {
        let format = LanguageManager.shared.localizedString(forKey: "home_remaining_ml", defaultValue: "あと %d ml")
        return String(format: format, ml)
    }
    static var evolutionComplete: String { LanguageManager.shared.localizedString(forKey: "home_evolution_complete", defaultValue: "進化完了！") }
    static var todaysWater: String { LanguageManager.shared.localizedString(forKey: "home_todays_water", defaultValue: "本日の水分量") }
    static var raiseNextKappa: String { LanguageManager.shared.localizedString(forKey: "home_raise_next_kappa", defaultValue: "次のカッパを育てる") }
    static var shareBtnText: String { LanguageManager.shared.localizedString(forKey: "home_share_btn_text", defaultValue: "この姿をシェアする") }
    
    static func stageText(_ stage: Int) -> String {
        switch stage {
        case 1: return LanguageManager.shared.localizedString(forKey: "stage_1", defaultValue: "Stage 1: 卵期")
        case 2: return LanguageManager.shared.localizedString(forKey: "stage_2", defaultValue: "Stage 2: ひび割れ期")
        case 3: return LanguageManager.shared.localizedString(forKey: "stage_3", defaultValue: "Stage 3: 幼生期")
        case 4: return LanguageManager.shared.localizedString(forKey: "stage_4", defaultValue: "Stage 4: 成長期")
        default: return LanguageManager.shared.localizedString(forKey: "stage_5", defaultValue: "Stage 5: 成体期")
        }
    }
    
    // MARK: - LogView
    static var logTitle: String { LanguageManager.shared.localizedString(forKey: "log_title", defaultValue: "記録") }
    static var logToday: String { LanguageManager.shared.localizedString(forKey: "log_today", defaultValue: "本日の記録") }
    static var logEmpty: String { LanguageManager.shared.localizedString(forKey: "log_empty", defaultValue: "まだ本日の記録はありません。") }
    static var weekdays: [String] {
        [
            LanguageManager.shared.localizedString(forKey: "weekday_sun", defaultValue: "日"),
            LanguageManager.shared.localizedString(forKey: "weekday_mon", defaultValue: "月"),
            LanguageManager.shared.localizedString(forKey: "weekday_tue", defaultValue: "火"),
            LanguageManager.shared.localizedString(forKey: "weekday_wed", defaultValue: "水"),
            LanguageManager.shared.localizedString(forKey: "weekday_thu", defaultValue: "木"),
            LanguageManager.shared.localizedString(forKey: "weekday_fri", defaultValue: "金"),
            LanguageManager.shared.localizedString(forKey: "weekday_sat", defaultValue: "土")
        ]
    }
    static var logWeeklyStamp: String { LanguageManager.shared.localizedString(forKey: "log_weekly_stamp", defaultValue: "週間のスタンプ") }
    static func logTotalAmountText(_ amount: Int) -> String {
        let format = LanguageManager.shared.localizedString(forKey: "log_total_amount_format", defaultValue: "計 %d ml")
        return String(format: format, amount)
    }
    
    // MARK: - AlbumView
    static var albumTitle: String { LanguageManager.shared.localizedString(forKey: "album_title", defaultValue: "図鑑") }
    static var albumEmpty: String { LanguageManager.shared.localizedString(forKey: "album_empty", defaultValue: "まだカッパがいません。水分補給をして解放しましょう！") }
    static var albumCollectedKappas: String { LanguageManager.shared.localizedString(forKey: "album_collected_kappas", defaultValue: "収集したカッパ") }
    static func albumSpeciesCountText(_ count: Int) -> String {
        let format = LanguageManager.shared.localizedString(forKey: "album_species_count_format", defaultValue: "%d 種")
        return String(format: format, count)
    }
    static var albumEmptyTitle: String { LanguageManager.shared.localizedString(forKey: "album_empty_title", defaultValue: "まだカッパを発見していません。") }
    static var albumEmptyDetail: String { LanguageManager.shared.localizedString(forKey: "album_empty_detail", defaultValue: "ホーム画面で水分を記録し、お皿を水で満たしてカッパを完全に成長させると、ここに思い出として登録されます。") }
    static var albumUndiscovered: String { LanguageManager.shared.localizedString(forKey: "album_undiscovered", defaultValue: "未発見") }
    
    // MARK: - SettingsView
    static var settingsTitle: String { LanguageManager.shared.localizedString(forKey: "settings_title", defaultValue: "設定") }
    static var personalSection: String { LanguageManager.shared.localizedString(forKey: "settings_personal_section", defaultValue: "パーソナル設定") }
    static var modeSelection: String { LanguageManager.shared.localizedString(forKey: "settings_mode_selection", defaultValue: "モード選択") }
    static var genderFemale: String { LanguageManager.shared.localizedString(forKey: "settings_gender_female", defaultValue: "女性 (1500ml)") }
    static var genderMale: String { LanguageManager.shared.localizedString(forKey: "settings_gender_male", defaultValue: "男性 (2000ml)") }
    
    static var customGoalSection: String { LanguageManager.shared.localizedString(forKey: "settings_custom_goal_section", defaultValue: "1日の目標水分量") }
    static var customGoalTitle: String { LanguageManager.shared.localizedString(forKey: "settings_custom_goal_title", defaultValue: "あなたに最適な目標量を分析する") }
    static func currentGoalLabel(_ amount: Int) -> String {
        let format = LanguageManager.shared.localizedString(forKey: "settings_current_goal", defaultValue: "現在の目標: %dml")
        return String(format: format, amount)
    }
    static var resetGoalButton: String { LanguageManager.shared.localizedString(forKey: "settings_reset_goal", defaultValue: "簡易設定（性別）に戻す") }
    static var settingsCurrentGoalTitleLabel: String { LanguageManager.shared.localizedString(forKey: "settings_current_goal_title_label", defaultValue: "現在の目標") }
    static var settingsGoalNotice: String { LanguageManager.shared.localizedString(forKey: "settings_goal_notice", defaultValue: "表示される目標量はあくまで一般的な目安です。体調・持病・服薬状況などによって適切な水分量は異なります。ご自身の体調を優先し、不安な場合は医師や専門家にご相談ください。") }
    static var settingsWidgetTitle: String { LanguageManager.shared.localizedString(forKey: "settings_widget_title", defaultValue: "ウィジェット") }
    static var settingsWidgetGuideBtn: String { LanguageManager.shared.localizedString(forKey: "settings_widget_guide_btn", defaultValue: "ウィジェットの設定方法") }
    static var settingsPolicySectionTitle: String { LanguageManager.shared.localizedString(forKey: "settings_policy_section_title", defaultValue: "ポリシー・規約") }
    static var settingsTermsTitle: String { LanguageManager.shared.localizedString(forKey: "settings_terms_title", defaultValue: "利用規約") }
    static var settingsPrivacyTitle: String { LanguageManager.shared.localizedString(forKey: "settings_privacy_title", defaultValue: "プライバシーポリシー") }
    static var settingsResetAlertMessage: String { LanguageManager.shared.localizedString(forKey: "settings_reset_alert_message", defaultValue: "データを初期化しますか？\nすべての記録と図鑑がリセットされます。") }
    static var settingsResetConfirmBtn: String { LanguageManager.shared.localizedString(forKey: "settings_reset_confirm_btn", defaultValue: "初期化する") }
    
    // MARK: - WaterAnalysisView
    static var analysisTitle: String { LanguageManager.shared.localizedString(forKey: "analysis_title", defaultValue: "目標水分量の分析") }
    
    static var analysisMethodTitle: String { LanguageManager.shared.localizedString(forKey: "analysis_method_title", defaultValue: "目標の決め方を選んでください") }
    static var analysisMethodSimpleTitle: String { LanguageManager.shared.localizedString(forKey: "analysis_method_simple_title", defaultValue: "簡易設定") }
    static var analysisMethodSimpleDesc: String { LanguageManager.shared.localizedString(forKey: "analysis_method_simple_desc", defaultValue: "性別を選択して標準的な目標量を設定します") }
    static var analysisMethodDetailTitle: String { LanguageManager.shared.localizedString(forKey: "analysis_method_detail_title", defaultValue: "詳細分析") }
    static var analysisMethodDetailDesc: String { LanguageManager.shared.localizedString(forKey: "analysis_method_detail_desc", defaultValue: "生活スタイルや気候からあなた専用の目標量を算出します") }
    
    static var analysisGenderTitle: String { LanguageManager.shared.localizedString(forKey: "analysis_gender_title", defaultValue: "性別を選択してください") }
    static var analysisGenderFemale: String { LanguageManager.shared.localizedString(forKey: "analysis_gender_female", defaultValue: "女性") }
    static var analysisGenderMale: String { LanguageManager.shared.localizedString(forKey: "analysis_gender_male", defaultValue: "男性") }
    
    static var q1Title: String { LanguageManager.shared.localizedString(forKey: "analysis_q1_title", defaultValue: "あなたのことを教えてください") }
    static var q1WeightPlaceholder: String { LanguageManager.shared.localizedString(forKey: "analysis_q1_weight", defaultValue: "体重 (kg)") }
    static var q1Age1: String { LanguageManager.shared.localizedString(forKey: "analysis_q1_age1", defaultValue: "18〜54歳") }
    static var q1Age2: String { LanguageManager.shared.localizedString(forKey: "analysis_q1_age2", defaultValue: "55〜64歳") }
    static var q1Age3: String { LanguageManager.shared.localizedString(forKey: "analysis_q1_age3", defaultValue: "65歳以上") }
    
    static var q2Title: String { LanguageManager.shared.localizedString(forKey: "analysis_q2_title", defaultValue: "普段の運動量や仕事のスタイルは？") }
    static var q2Option1: String { LanguageManager.shared.localizedString(forKey: "analysis_q2_opt1", defaultValue: "ほとんど動かない\n（デスクワーク・在宅中心）") }
    static var q2Option2: String { LanguageManager.shared.localizedString(forKey: "analysis_q2_opt2", defaultValue: "適度に動く\n（立ち仕事・徒歩移動が多い）") }
    static var q2Option3: String { LanguageManager.shared.localizedString(forKey: "analysis_q2_opt3", defaultValue: "日常的に運動する\n（週に数回のジム・肉体労働）") }
    static var q2Option4: String { LanguageManager.shared.localizedString(forKey: "analysis_q2_opt4", defaultValue: "激しく運動する\n（毎日のハードなトレーニング等）") }
    
    static var q3Title: String { LanguageManager.shared.localizedString(forKey: "analysis_q3_title", defaultValue: "今の季節、またはお住まいの気候は？") }
    static var q3Option1: String { LanguageManager.shared.localizedString(forKey: "analysis_q3_opt1", defaultValue: "涼しい・寒い\n（春・秋・冬、エアコン環境）") }
    static var q3Option2: String { LanguageManager.shared.localizedString(forKey: "analysis_q3_opt2", defaultValue: "暖かい・汗ばむ\n（初夏・最高気温25°C〜30°C）") }
    static var q3Option3: String { LanguageManager.shared.localizedString(forKey: "analysis_q3_opt3", defaultValue: "厳しい暑さ\n（真夏・最高気温30°C以上）") }
    
    static var q4Title: String { LanguageManager.shared.localizedString(forKey: "analysis_q4_title", defaultValue: "特別なステータス（任意）") }
    static var q4Option1: String { LanguageManager.shared.localizedString(forKey: "analysis_q4_opt1", defaultValue: "妊娠中") }
    static var q4Option2: String { LanguageManager.shared.localizedString(forKey: "analysis_q4_opt2", defaultValue: "授乳中") }
    static var q4Option3: String { LanguageManager.shared.localizedString(forKey: "analysis_q4_opt3", defaultValue: "あてはまらない / スキップ") }
    
    static var analysisNext: String { LanguageManager.shared.localizedString(forKey: "analysis_next", defaultValue: "次へ") }
    static var analysisComplete: String { LanguageManager.shared.localizedString(forKey: "analysis_complete", defaultValue: "分析完了！") }
    static func analysisResult(_ amount: Int) -> String {
        let format = LanguageManager.shared.localizedString(forKey: "analysis_result", defaultValue: "あなたの最適な目標量は\n%dml です")
        return String(format: format, amount)
    }
    static var analysisApply: String { LanguageManager.shared.localizedString(forKey: "analysis_apply", defaultValue: "この目標量を設定する") }
    static var analysisRetry: String { LanguageManager.shared.localizedString(forKey: "analysis_retry", defaultValue: "やり直す") }
    
    static var myCupSection: String { LanguageManager.shared.localizedString(forKey: "settings_my_cup_section", defaultValue: "マイコップ設定") }
    static func cupLabel(_ index: Int) -> String {
        let format = LanguageManager.shared.localizedString(forKey: "settings_cup_label", defaultValue: "コップ %d")
        return String(format: format, index)
    }
    
    static var dataInit: String { LanguageManager.shared.localizedString(forKey: "settings_data_init", defaultValue: "データ初期化") }
    
    // MARK: - Onboarding
    static var onboardingStoryLines: [String] {
        [
            LanguageManager.shared.localizedString(forKey: "onboarding_story_1", defaultValue: "古来より日本に伝わる、"),
            LanguageManager.shared.localizedString(forKey: "onboarding_story_2", defaultValue: "伝説の生き物、河童。"),
            LanguageManager.shared.localizedString(forKey: "onboarding_story_3", defaultValue: "彼らの頭にあるお皿には、"),
            LanguageManager.shared.localizedString(forKey: "onboarding_story_4", defaultValue: "常に満ちる水が必要でした。"),
            LanguageManager.shared.localizedString(forKey: "onboarding_story_5", defaultValue: "お皿の水が乾けば、"),
            LanguageManager.shared.localizedString(forKey: "onboarding_story_6", defaultValue: "その生命も"),
            LanguageManager.shared.localizedString(forKey: "onboarding_story_7", defaultValue: "失われてしまうのです…。")
        ]
    }
    
    static var onboardingHumanTitle: String { LanguageManager.shared.localizedString(forKey: "onboarding_human_title", defaultValue: "人間も河童みたいなもの") }
    static var onboardingHumanMessage: String { LanguageManager.shared.localizedString(forKey: "onboarding_human_message", defaultValue: "河童のお皿が乾いてはいけないように、\n私たち人間もまた、\n日々の給水を絶やしてはいけないのです。") }
    
    static var onboardingBenefitsTitle: String { LanguageManager.shared.localizedString(forKey: "onboarding_benefits_title", defaultValue: "お水を飲む４つのメリット") }
    static var onboardingBenefitsSubtitle: String { LanguageManager.shared.localizedString(forKey: "onboarding_benefits_subtitle", defaultValue: "カードをタップして詳細をご覧ください") }
    
    static var onboardingBenefits: [HydrationBenefit] {
        [
            HydrationBenefit(
                icon: "flame.fill",
                iconColor: .orange,
                title: LanguageManager.shared.localizedString(forKey: "onboarding_benefit1_title", defaultValue: "① 代謝アップ"),
                subtitle: LanguageManager.shared.localizedString(forKey: "onboarding_benefit1_sub", defaultValue: "痩せやすい体へ"),
                description: LanguageManager.shared.localizedString(forKey: "onboarding_benefit1_desc", defaultValue: "水分が体に満たされると血液の巡りが良くなり全身の基礎代謝がアップ。何もしなくても消費されるカロリーが増え、脂肪燃焼効率も高まります。")
            ),
            HydrationBenefit(
                icon: "sparkles",
                iconColor: Theme.Colors.primaryBlue,
                title: LanguageManager.shared.localizedString(forKey: "onboarding_benefit2_title", defaultValue: "② 美肌効果"),
                subtitle: LanguageManager.shared.localizedString(forKey: "onboarding_benefit2_sub", defaultValue: "内側からの潤い"),
                description: LanguageManager.shared.localizedString(forKey: "onboarding_benefit2_desc", defaultValue: "高価な化粧水よりも、内側からの水分補給が美肌への近道。ターンオーバーが正常化し、乾燥の改善、ハリ・ツヤや顔の透明感が向上します。")
            ),
            HydrationBenefit(
                icon: "leaf.fill",
                iconColor: .green,
                title: LanguageManager.shared.localizedString(forKey: "onboarding_benefit3_title", defaultValue: "③ デトックス"),
                subtitle: LanguageManager.shared.localizedString(forKey: "onboarding_benefit3_sub", defaultValue: "便秘・むくみ解消"),
                description: LanguageManager.shared.localizedString(forKey: "onboarding_benefit3_desc", defaultValue: "腸内環境を整えてお通じをスムーズに。水分不足になると体は逆に水をため込もうとしてむくむため、しっかり飲んで老廃物を流し出すのが正解です。")
            ),
            HydrationBenefit(
                icon: "brain.fill",
                iconColor: .purple,
                title: LanguageManager.shared.localizedString(forKey: "onboarding_benefit4_title", defaultValue: "④ 疲労軽減"),
                subtitle: LanguageManager.shared.localizedString(forKey: "onboarding_benefit4_sub", defaultValue: "集中力の維持"),
                description: LanguageManager.shared.localizedString(forKey: "onboarding_benefit4_desc", defaultValue: "わずか1〜2%の水分不足でもだるさや集中力低下の原因に。脳と体のパフォーマンスをベストに保つための、最も簡単なスイッチです。")
            )
        ]
    }
    
    static var onboardingBenefitPreconditionTitle: String { LanguageManager.shared.localizedString(forKey: "onboarding_precondition_title", defaultValue: "効果を最大にするための「大前提」") }
    static var onboardingBenefitPreconditionDesc: String { LanguageManager.shared.localizedString(forKey: "onboarding_precondition_desc", defaultValue: "人が一度に吸収できる水分は約200〜250ml（コップ1杯分）です。1日7〜8回に分けこまめに飲むのが最大のコツです。") }
    
    static var onboardingGuideTitle: String { LanguageManager.shared.localizedString(forKey: "onboarding_guide_title", defaultValue: "アプリの使い方") }
    static var onboardingGuideSubtitle: String { LanguageManager.shared.localizedString(forKey: "onboarding_guide_subtitle", defaultValue: "数字をタップして機能をご確認ください") }
    static var onboardingGuideHint: String { LanguageManager.shared.localizedString(forKey: "onboarding_guide_hint", defaultValue: "スワイプ、またはカード外のタップで次へ進みます") }
    
    static var onboardingGuideSteps: [HydrationBenefit] {
        [
            HydrationBenefit(
                icon: "plus.circle.fill",
                iconColor: Theme.Colors.primaryBlue,
                title: LanguageManager.shared.localizedString(forKey: "onboarding_guide1_title", defaultValue: "水分補給を記録する"),
                subtitle: "STEP 1",
                description: LanguageManager.shared.localizedString(forKey: "onboarding_guide1_desc", defaultValue: "コップのアイコンをワンタップするだけで、飲んだ水分量を素早く記録できます。毎日の給水をスムーズに習慣化しましょう。")
            ),
            HydrationBenefit(
                icon: "sparkles",
                iconColor: .orange,
                title: LanguageManager.shared.localizedString(forKey: "onboarding_guide2_title", defaultValue: "水を飲んでカッパを育てる"),
                subtitle: "STEP 2",
                description: LanguageManager.shared.localizedString(forKey: "onboarding_guide2_desc", defaultValue: "あなたが水を飲むと、カッパに水が届きます。たくさん飲んで様々なカッパを現代に甦らせましょう。")
            ),
            HydrationBenefit(
                icon: "square.text.square.fill",
                iconColor: .purple,
                title: LanguageManager.shared.localizedString(forKey: "onboarding_guide3_title", defaultValue: "ウィジェットで瞬時に給水"),
                subtitle: "STEP 3",
                description: LanguageManager.shared.localizedString(forKey: "onboarding_guide3_desc", defaultValue: "ホーム画面にウィジェットを配置すれば、アプリを開かずにホーム画面からワンタップで瞬時に記録を更新できます。")
            )
        ]
    }
    
    static var onboardingGoalSetupTitle: String { LanguageManager.shared.localizedString(forKey: "onboarding_goal_title", defaultValue: "お水の目標を設定しましょう") }
    static var onboardingGoalSetupDesc: String { LanguageManager.shared.localizedString(forKey: "onboarding_goal_desc", defaultValue: "河童のお皿を潤すために、あなたに最適な１日の補給目標量を自動で分析・診断します。") }
    static var onboardingGoalSetupButton: String { LanguageManager.shared.localizedString(forKey: "onboarding_goal_button", defaultValue: "最適な目標量を診断する") }
    
    // MARK: - Share Text
    static func shareText(kappaName: String, stageText: String, currentAmount: Int) -> String {
        let format = LanguageManager.shared.localizedString(forKey: "share_message_format", defaultValue: "#LofiKappa カッパ育成中！今日の給水量: %dml ")
        return String(format: format, kappaName, stageText, currentAmount)
    }
    
    // MARK: - Reminders
    static var reminderSectionTitle: String { LanguageManager.shared.localizedString(forKey: "reminder_section_title", defaultValue: "通知") }
    static var reminderToggleTitle: String { LanguageManager.shared.localizedString(forKey: "reminder_toggle_title", defaultValue: "給水リマインダー") }
    static var reminderToggleDescription: String { LanguageManager.shared.localizedString(forKey: "reminder_toggle_desc", defaultValue: "お水を最後に飲んでから2時間後と3時間後にカッパが通知します（給水するとリセットされます）") }
    static var reminderNotificationTitle: String { LanguageManager.shared.localizedString(forKey: "notification_title", defaultValue: "給水タイムかっぱ！") }
    static var reminderNotificationBody1: String { LanguageManager.shared.localizedString(forKey: "notification_body_1", defaultValue: "お皿が少し乾いてきたかっぱ…!コップ1杯のお水ください…!") }
    static var reminderNotificationBody2: String { LanguageManager.shared.localizedString(forKey: "notification_body_2", defaultValue: "お皿にもう水が無いかっぱ…お、お水を…くだ…さい…") }
    
    // MARK: - Common UI Buttons
    static var backBtnText: String { LanguageManager.shared.localizedString(forKey: "back_btn_text", defaultValue: "戻る") }
    static var cancelBtnText: String { LanguageManager.shared.localizedString(forKey: "cancel_btn_text", defaultValue: "キャンセル") }
    static var closeBtnText: String { LanguageManager.shared.localizedString(forKey: "close_btn_text", defaultValue: "閉じる") }
    
    // MARK: - WidgetGuideView
    static var widgetGuideTitle: String { LanguageManager.shared.localizedString(forKey: "widget_guide_title", defaultValue: "ウィジェット設定ガイド") }
    static var widgetGuideHeaderTitle: String { LanguageManager.shared.localizedString(forKey: "widget_guide_header_title", defaultValue: "ホーム画面にウィジェットを追加しよう") }
    static var widgetGuideHeaderDesc: String { LanguageManager.shared.localizedString(forKey: "widget_guide_header_desc", defaultValue: "カッパをホーム画面に配置して、アプリを開かずに簡単に水分を補給できるようになります。") }
    static var widgetGuideStep1Title: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step1_title", defaultValue: "ホーム画面を長押し") }
    static var widgetGuideStep1Desc: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step1_desc", defaultValue: "ホーム画面の空いている場所（アプリアイコンやウィジェットがないスペース）を、アイコンが揺れ始めるまで長押しします。") }
    static var widgetGuideStep2Title: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step2_title", defaultValue: "「＋」ボタンをタップ") }
    static var widgetGuideStep2Desc: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step2_desc", defaultValue: "画面の左上（または右上）に表示される「＋」追加ボタンをタップして、ウィジェットギャラリーを開きます。") }
    static var widgetGuideStep3Title: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step3_title", defaultValue: "「KapStation」を検索") }
    static var widgetGuideStep3Desc: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step3_desc", defaultValue: "ウィジェットギャラリーの上部検索バーで「KapStation」と入力するか、アプリ一覧から見つけてタップします。") }
    static var widgetGuideStep4Title: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step4_title", defaultValue: "サイズを選んで追加") }
    static var widgetGuideStep4Desc: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step4_desc", defaultValue: "お好みのウィジェットサイズ（小・中）を選択し、下部の「ウィジェットを追加」ボタンをタップします。") }
    static var widgetGuideStep5Title: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step5_title", defaultValue: "配置の完了と給水操作") }
    static var widgetGuideStep5Desc: String { LanguageManager.shared.localizedString(forKey: "widget_guide_step5_desc", defaultValue: "ホーム画面にウィジェットが配置されたら、完了ボタンを押します。ウィジェット上の給水ボタンをタップするだけで、すぐに今日の記録へ反映されます！") }
    static var widgetGuideTroubleTitle: String { LanguageManager.shared.localizedString(forKey: "widget_guide_trouble_title", defaultValue: "うまく同期されない時は？") }
    static var widgetGuideTroubleDesc: String { LanguageManager.shared.localizedString(forKey: "widget_guide_trouble_desc", defaultValue: "ウィジェットの追加直後や、日付が変わったタイミングなどでデータが表示されない場合は、一度アプリを起動して水分を補給してみてください。自動的にデータが同期・更新されます。") }
    
    // MARK: - Widget
    static var widgetTodayWater: String { LanguageManager.shared.localizedString(forKey: "widget_today_water", defaultValue: "今日の給水") }
    static var widgetEvolutionProgress: String { LanguageManager.shared.localizedString(forKey: "widget_evolution_progress", defaultValue: "進化の進捗") }
    static var widgetStatusRecord: String { LanguageManager.shared.localizedString(forKey: "widget_status_record", defaultValue: "観察記録ステータス") }
    static var widgetTodayAmount: String { LanguageManager.shared.localizedString(forKey: "widget_today_amount", defaultValue: "本日の水分量") }
}
