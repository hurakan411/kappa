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
    
    @AppStorage("isReminderEnabled") private var isReminderEnabled = true
    
    private let cupIcons = ["cup.and.saucer.fill", "mug.fill", "drop.fill", "waterbottle.fill", "takeoutbag.and.cup.and.straw.fill"]
    
    var body: some View {
        let _ = languageManager.selectedLanguage // 言語変更を検知してコンテンツを再描画
        NavigationView {
            ZStack {
                // 手帳の背景テクスチャを統一
                TimeLightingBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // ヘッダー（手書き風セクション）
                        VStack(spacing: 4) {
                            Text(AppTexts.settingsTitle)
                                .font(.system(.headline, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                                .padding(.top, 16)
                            
                            HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.15))
                                .frame(width: 120)
                        }
                        .padding(.bottom, 10)
                        
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
                                
                                VStack(spacing: 10) {
                                    ForEach(0..<5, id: \.self) { i in
                                        HStack(spacing: 12) {
                                            HStack(spacing: 10) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Theme.Colors.lightBlue.opacity(0.12))
                                                        .frame(width: 38, height: 38)
                                                        .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.15), cornerRadius: 19)
                                                    
                                                    Image(systemName: cupIcons[i])
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(Theme.Colors.primaryBlue)
                                                }
                                                
                                                Text(AppTexts.cupLabel(i + 1))
                                                    .font(.system(.body, design: .rounded).bold())
                                                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                                            }
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 8) {
                                                // 減らすボタン
                                                Button(action: {
                                                    adjustCupSize(index: i, delta: -50)
                                                }) {
                                                    Image(systemName: "minus")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(Theme.Colors.primaryBlue)
                                                        .frame(width: 28, height: 28)
                                                        .background(Theme.Colors.lightBlue.opacity(0.15))
                                                        .clipShape(Circle())
                                                        .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.25), cornerRadius: 14)
                                                }
                                                .buttonStyle(BouncingButtonStyle())
                                                
                                                // 容量テキスト
                                                if i < cupSizes.count {
                                                    Text("\(cupSizes[i])ml")
                                                        .font(.system(.body, design: .rounded).bold())
                                                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                                                        .frame(width: 58, alignment: .center)
                                                }
                                                
                                                // 増やすボタン
                                                Button(action: {
                                                    adjustCupSize(index: i, delta: 50)
                                                }) {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(Theme.Colors.primaryBlue)
                                                        .frame(width: 28, height: 28)
                                                        .background(Theme.Colors.lightBlue.opacity(0.15))
                                                        .clipShape(Circle())
                                                        .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.25), cornerRadius: 14)
                                                }
                                                .buttonStyle(BouncingButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            // 水分量が直感的に伝わる進捗グラデーション背景
                                            GeometryReader { geo in
                                                let sizeVal = i < cupSizes.count ? (Double(cupSizes[i]) ?? 0) : 0
                                                let progress = CGFloat(sizeVal / 1000.0)
                                                let fillWidth = geo.size.width * progress
                                                ZStack(alignment: .leading) {
                                                    Color.clear
                                                    LinearGradient(
                                                        colors: [Theme.Colors.lightBlue.opacity(0.15), Theme.Colors.primaryBlue.opacity(0.06)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                    .frame(width: fillWidth)
                                                }
                                            }
                                        )
                                        .cornerRadius(12)
                                        .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.08), cornerRadius: 12)
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
            }
            .navigationTitle("")
            .navigationBarHidden(true)
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
    
    private func adjustCupSize(index: Int, delta: Int) {
        guard index < cupSizes.count else { return }
        let currentValue = Int(cupSizes[index]) ?? 0
        let newValue = max(0, min(1000, currentValue + delta))
        
        // タプティクスフィードバック
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cupSizes[index] = "\(newValue)"
        }
        saveCupSize(index: index, value: "\(newValue)")
    }
}

struct BouncingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

