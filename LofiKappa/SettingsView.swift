import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var userSettings: [UserSettings]
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var settings: UserSettings {
        if let s = userSettings.first {
            return s
        } else {
            let s = UserSettings()
            modelContext.insert(s)
            return s
        }
    }
    
    @State private var selectedGender: Gender = .female
    @State private var cupSizes: [String] = ["150", "200", "300", "400", "500"]
    @State private var showingAnalysis = false
    @State private var showDeleteConfirm = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingWidgetGuide = false
    
    @AppStorage("isReminderEnabled") private var isReminderEnabled = false
    
    private let cupIcons = ["cup.and.saucer.fill", "mug.fill", "drop.fill", "waterbottle.fill", "takeoutbag.and.cup.and.straw.fill"]
    
    var body: some View {
        let _ = languageManager.selectedLanguage // 言語変更を検知してコンテンツを再描画
        NavigationView {
            ZStack {
                // 手帳の背景テクスチャを統一
                TimeLightingBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - 目標水分量カード
                        settingCard {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(icon: "target", title: AppTexts.customGoalSection)
                                
                                // 現在の目標
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(AppTexts.settingsCurrentGoalTitleLabel)
                                            .font(.system(.caption, design: .rounded).bold())
                                            .foregroundColor(.secondary)
                                        Text("\(settings.dailyGoal) ml")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(Theme.Colors.primaryBlue)
                                    }
                                    Spacer()
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.Colors.lightBlue)
                                }
                                
                                HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.12))
                                
                                // 分析ボタン
                                Button(action: { showingAnalysis = true }) {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                            .font(.body)
                                        Text(AppTexts.customGoalTitle)
                                            .font(.system(.body, design: .rounded).bold())
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .foregroundColor(Theme.Colors.primaryBlue)
                            }
                        }
                        
                        // MARK: - 注意事項（ふせん風デザイン）
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.footnote)
                                .padding(.top, 1)
                            Text(AppTexts.settingsGoalNotice)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(12)
                        .handDrawnBorder(color: Color.orange.opacity(0.24), cornerRadius: 12)
                        .padding(.horizontal, 16)
                        
                        // MARK: - マイコップ設定カード
                        settingCard {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(icon: "cup.and.saucer.fill", title: AppTexts.myCupSection)
                                
                                VStack(spacing: 12) {
                                    ForEach(0..<5, id: \.self) { i in
                                        HStack(spacing: 14) {
                                            Image(systemName: cupIcons[i])
                                                .font(.body)
                                                .foregroundColor(Theme.Colors.primaryBlue)
                                                .frame(width: 24)
                                            
                                            Text(AppTexts.cupLabel(i + 1))
                                                .font(.system(.body, design: .rounded).bold())
                                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 4) {
                                                Menu {
                                                    ForEach([50, 100, 120, 150, 180, 200, 250, 300, 350, 400, 450, 500, 600, 700, 800, 1000], id: \.self) { size in
                                                        Button("\(size) ml") {
                                                            cupSizes[i] = "\(size)"
                                                            saveCupSize(index: i, value: "\(size)")
                                                        }
                                                    }
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Text("\(cupSizes[i])")
                                                            .font(.system(.body, design: .rounded).bold())
                                                            .foregroundColor(Theme.Colors.primaryBlue)
                                                        Image(systemName: "chevron.up.chevron.down")
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Theme.Colors.lightBlue.opacity(0.12))
                                                    .cornerRadius(8)
                                                    .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.18), cornerRadius: 8)
                                                }
                                                Text("ml")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        if i < 4 {
                                            HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.1))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - ウィジェット設定ガイド
                        settingCard {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(icon: "square.text.square.fill", title: AppTexts.settingsWidgetTitle)
                                
                                Button(action: { showingWidgetGuide = true }) {
                                    HStack {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.body)
                                            .foregroundColor(Theme.Colors.primaryBlue)
                                            .frame(width: 24)
                                        Text(AppTexts.settingsWidgetGuideBtn)
                                            .font(.system(.body, design: .rounded).bold())
                                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // MARK: - リマインダー通知設定
                        settingCard {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(icon: "bell.fill", title: AppTexts.reminderSectionTitle)
                                
                                Toggle(isOn: Binding(get: {
                                    isReminderEnabled
                                }, set: { newValue in
                                    if newValue {
                                        NotificationManager.shared.requestAuthorization { granted in
                                            isReminderEnabled = granted
                                            if granted {
                                                NotificationManager.shared.resetReminder(isTargetCompleted: false)
                                            }
                                        }
                                    } else {
                                        isReminderEnabled = false
                                        NotificationManager.shared.cancelAllReminders()
                                    }
                                })) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(AppTexts.reminderToggleTitle)
                                            .font(.system(.body, design: .rounded).bold())
                                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                                        Text(AppTexts.reminderToggleDescription)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .tint(Theme.Colors.primaryBlue)
                            }
                        }
                        
                        // MARK: - 言語設定
                        settingCard {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(icon: "globe", title: LanguageManager.shared.localizedString(forKey: "settings_lang_section_title", defaultValue: "言語設定 (Language)"))
                                
                                HStack {
                                    Text(LanguageManager.shared.localizedString(forKey: "settings_lang_label", defaultValue: "表示言語"))
                                        .font(.system(.body, design: .rounded).bold())
                                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $languageManager.selectedLanguage) {
                                        ForEach(AppLanguage.allCases) { lang in
                                            Text(lang.displayName)
                                                .tag(lang)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Theme.Colors.primaryBlue)
                                    .onChange(of: languageManager.selectedLanguage) { _ in
                                        // 言語が変更されたら、ウィジェットのタイムラインも更新する
                                        WidgetCenter.shared.reloadAllTimelines()
                                    }
                                }
                            }
                        }
                        
                        // MARK: - プライバシーポリシー & 利用規約
                        settingCard {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(icon: "doc.text.fill", title: AppTexts.settingsPolicySectionTitle)
                                
                                // 利用規約ボタン
                                Button(action: { showingTerms = true }) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.body)
                                            .foregroundColor(Theme.Colors.primaryBlue)
                                            .frame(width: 24)
                                        Text(AppTexts.settingsTermsTitle)
                                            .font(.system(.body, design: .rounded).bold())
                                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.1))
                                
                                // プライバシーポリシーボタン
                                Button(action: { showingPrivacy = true }) {
                                    HStack {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.body)
                                            .foregroundColor(Theme.Colors.primaryBlue)
                                            .frame(width: 24)
                                        Text(AppTexts.settingsPrivacyTitle)
                                            .font(.system(.body, design: .rounded).bold())
                                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // MARK: - データ初期化
                        settingCard {
                            Button(action: { showDeleteConfirm = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.body)
                                    Text(AppTexts.dataInit)
                                        .font(.system(.body, design: .rounded).bold())
                                    Spacer()
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(AppTexts.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAnalysis) {
                WaterAnalysisView(customDailyGoal: Binding(get: {
                    settings.customDailyGoal
                }, set: { newValue in
                    settings.customDailyGoal = newValue
                    try? modelContext.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }), selectedGender: Binding(get: {
                    settings.gender
                }, set: { newValue in
                    settings.gender = newValue
                    selectedGender = newValue
                    try? modelContext.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }))
            }
            .sheet(isPresented: $showingTerms) {
                PolicyDocumentView(title: AppTexts.settingsTermsTitle, content: PolicyTexts.termsOfService)
            }
            .sheet(isPresented: $showingPrivacy) {
                PolicyDocumentView(title: AppTexts.settingsPrivacyTitle, content: PolicyTexts.privacyPolicy)
            }
            .sheet(isPresented: $showingWidgetGuide) {
                WidgetGuideView()
            }
            .confirmationDialog(
                AppTexts.settingsResetAlertMessage,
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(AppTexts.settingsResetConfirmBtn, role: .destructive) {
                    resetData()
                }
                Button(AppTexts.cancelBtnText, role: .cancel) {}
            }
            .onAppear {
                selectedGender = settings.gender
                cupSizes = [
                    "\(settings.cupSize1)",
                    "\(settings.cupSize2)",
                    "\(settings.cupSize3)",
                    "\(settings.cupSize4)",
                    "\(settings.cupSize5)"
                ]
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func settingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(Theme.Colors.card(for: colorScheme))
            .cornerRadius(16)
            .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.15), cornerRadius: 16)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.07), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
    }
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(Theme.Colors.primaryBlue)
            Text(title)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(1)
        }
    }
    
    // MARK: - Data helpers
    
    private func saveCupSize(index: Int, value: String) {
        guard let val = Int(value) else { return }
        switch index {
        case 0: settings.cupSize1 = val
        case 1: settings.cupSize2 = val
        case 2: settings.cupSize3 = val
        case 3: settings.cupSize4 = val
        case 4: settings.cupSize5 = val
        default: break
        }
        try? modelContext.save()
    }
    
    private func resetData() {
        do {
            try modelContext.delete(model: DailyWaterLog.self)
            try modelContext.delete(model: KappaCollection.self)
            try modelContext.save()
            
            // オンボーディング完了フラグをリセット
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            
            // レビュー関連のUserDefaultsもクリア
            UserDefaults.standard.removeObject(forKey: "isReviewRequestPending")
            UserDefaults.standard.removeObject(forKey: "pendingReviewReason")
            UserDefaults.standard.removeObject(forKey: "hasReviewedStage3")
            UserDefaults.standard.removeObject(forKey: "hasReviewedFinalStage")
            UserDefaults.standard.removeObject(forKey: "hasReviewed3Kappas")
            
            // リマインダー通知設定をOFFにする
            UserDefaults.standard.set(false, forKey: "isReminderEnabled")
            NotificationManager.shared.cancelAllReminders()
            
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

