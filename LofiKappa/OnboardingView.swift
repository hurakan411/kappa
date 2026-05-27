import SwiftUI
import SwiftData
import WidgetKit



struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query private var userSettings: [UserSettings]
    
    @State private var currentStep = 1
    @State private var emakimonoOpacity = 0.0
    @State private var textCharCount = 0
    @State private var showingAnalysis = false
    @State private var selectedBenefitIndex = 0 // 選択されているメリット
    @State private var currentGuideStep = 0 // アプリ使い方のカレントステップ
    
    private var settings: UserSettings {
        if let s = userSettings.first {
            return s
        } else {
            let s = UserSettings()
            modelContext.insert(s)
            return s
        }
    }
    
    // 短く改行した縦書きの物語（右から左へ並ぶように定義）
    private var storyLines: [String] { AppTexts.onboardingStoryLines }
    
    // メリットの静的データリスト
    private var benefits: [HydrationBenefit] { AppTexts.onboardingBenefits }
    
    // アプリ使い方のステップデータ
    private var guideSteps: [HydrationBenefit] { AppTexts.onboardingGuideSteps }
    
    // 全行の合計文字数
    private var totalCharCount: Int {
        storyLines.reduce(0) { $0 + $1.count }
    }
    
    var body: some View {
        let isFirstStep = currentStep == 1
        
        ZStack {
            // 背景の切り替え
            if isFirstStep {
                // 1画面目：神秘的な和のグラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "0d1b2a"),
                        Color(hex: "1b263b")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 背景の絵巻物（左右の余白をなくし、横幅いっぱいに大きく表示）
                if let uiImage = UIImage(named: "onboarding_emakimono") ?? UIImage(named: "onboarding_emakimono.jpeg") ?? UIImage(contentsOfFile: Bundle.main.path(forResource: "onboarding_emakimono", ofType: "jpeg") ?? "") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .opacity(emakimonoOpacity)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            } else {
                // 2つ目以降の画面は背景白
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // メインコンテンツエリア（ステップごとに滑らかに切り替える）
            VStack {
                Spacer()
                
                switch currentStep {
                case 1:
                    stepStoryView()
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                case 2:
                    stepHumanMessageView()
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                case 3:
                    stepDehydrationView()
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                case 4:
                    stepAppGuideView()
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                case 5:
                    stepGoalSetupView()
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                default:
                    EmptyView()
                }
                
                Spacer()
                
                // 下部のインジケータ（白背景用・黒背景用で色を切り替え、全5ドットに拡張）
                if currentStep < 5 {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { step in
                            Circle()
                                .fill(step == currentStep ? Theme.Colors.primaryBlue : (isFirstStep ? Color.white.opacity(0.2) : Color.black.opacity(0.12)))
                                .frame(width: 6, height: 6)
                                .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(.horizontal, 24)
        }
        .contentShape(Rectangle()) // 画面全体のタップ領域を確保
        .onTapGesture {
            // Step 1〜4の間は、画面タップで次のステップへ進む
            // ただし、Step 3（メリット画面）はカードタップ操作を優先させるため、スワイプでのみ進めるようにタップ遷移は除外します
            if currentStep < 5 && currentStep != 3 {
                withAnimation(.easeInOut(duration: 0.6)) {
                    currentStep += 1
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 25, coordinateSpace: .local)
                .onEnded { value in
                    // 横方向のスワイプ移動量を判定
                    let horizontalTranslation = value.translation.width
                    let verticalTranslation = value.translation.height
                    
                    if abs(horizontalTranslation) > abs(verticalTranslation) {
                        if horizontalTranslation < 0 {
                            // 左スワイプ（右から左へ払う）：次のステップへ進む
                            if currentStep < 5 {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    currentStep += 1
                                }
                            }
                        } else if horizontalTranslation > 0 {
                            // 右スワイプ（左から右へ払う）：前のステップに戻る
                            if currentStep > 1 {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    currentStep -= 1
                                }
                            }
                        }
                    }
                }
        )
        .onAppear {
            // 絵巻物画像のフェードイン（1.8秒かけてくっきりと表示）
            withAnimation(.easeOut(duration: 1.8)) {
                emakimonoOpacity = 0.95
            }
            
            // 2.2秒後に、じわっと半透明に溶け込ませるフェードアウト（2.0秒）を開始
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    emakimonoOpacity = 0.32
                }
            }
            
            // 絵巻物のフェードアウトが完全に完了する「4.2秒後」に、タイピングアニメーションを静かに開始
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
                startTypingAnimation()
            }
        }
        .sheet(isPresented: $showingAnalysis) {
            // 目標診断シートの表示
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
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            }))
        }
        .onChange(of: showingAnalysis) { oldVal, newVal in
            // 診断シートが閉じられたら自動的にオンボーディングを完了してホームへ遷移
            if !newVal {
                // オンボーディング完了後のレビュー要求
                let key = "hasRequestedReviewAfterOnboarding"
                if !UserDefaults.standard.bool(forKey: key) {
                    requestReview()
                    UserDefaults.standard.set(true, forKey: key)
                    print("⭐ [Review] Requested review: After Onboarding completed")
                }
                
                withAnimation(.easeInOut(duration: 0.8)) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
    
    // MARK: - Step 1: 語り部と絵巻物（縦書き/英語時は横書き）
    @ViewBuilder
    private func stepStoryView() -> some View {
        let isEnglish = LanguageManager.shared.selectedLanguage == .english
        
        VStack(spacing: 0) {
            if isEnglish {
                // 英語版：読みやすい横書き
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(0..<storyLines.count, id: \.self) { index in
                        let line = storyLines[index]
                        let visibleText = getVisibleTextForLine(line, lineIndex: index)
                        
                        Text(visibleText)
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            } else {
                // 日本語版：伝統的な縦書き
                HStack(alignment: .top, spacing: 24) {
                    ForEach(0..<storyLines.count, id: \.self) { index in
                        let line = storyLines[index]
                        VStack(spacing: 8) {
                            ForEach(0..<line.count, id: \.self) { charIndex in
                                let char = line[line.index(line.startIndex, offsetBy: charIndex)]
                                Text(String(char))
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundColor(.white.opacity(isCharVisible(lineIndex: index, charIndex: charIndex) ? 0.92 : 0.0))
                                    .animation(.easeOut(duration: 0.4), value: textCharCount)
                            }
                        }
                    }
                }
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 20)
            }
        }
        .frame(height: 380)
    }
    
    // 英語の横書き用タイピング部分文字列取得
    private func getVisibleTextForLine(_ line: String, lineIndex: Int) -> String {
        var previousCharsCount = 0
        for i in 0..<lineIndex {
            previousCharsCount += storyLines[i].count
        }
        
        if textCharCount <= previousCharsCount {
            return ""
        } else if textCharCount >= previousCharsCount + line.count {
            return line
        } else {
            let visibleLength = textCharCount - previousCharsCount
            let index = line.index(line.startIndex, offsetBy: visibleLength)
            return String(line[..<index])
        }
    }
    
    // MARK: - Step 2: 人間も給水を絶やしてはいけない（新規メッセージ・白背景用）
    @ViewBuilder
    private func stepHumanMessageView() -> some View {
        VStack(spacing: 32) {
            // 優美な水滴グラフィック
            // 美しいLottieアニメーション (Drink Water)
            LottieView(name: "Drink Water")
                .frame(width: 140, height: 140)
            
            VStack(spacing: 20) {
                Text(AppTexts.onboardingHumanTitle)
                    .font(.system(.title3, design: .serif).bold())
                    .foregroundColor(.black.opacity(0.85))
                
                Text(AppTexts.onboardingHumanMessage)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(.black.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(10) // ゆったりした気品ある行間
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 32)
        .background(Color.white)
    }
    
    // MARK: - Step 3: 水分補給の重要性（案A: 2×2 グリッド ＋ インタラクティブ詳細パネル）
    @ViewBuilder
    private func stepDehydrationView() -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(AppTexts.onboardingBenefitsTitle)
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(.black.opacity(0.85))
                Text(AppTexts.onboardingBenefitsSubtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.black.opacity(0.5))
            }
            .padding(.top, 4)
            
            // 2×2 グリッドレイアウト
            let columns = [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ]
            
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<benefits.count, id: \.self) { index in
                    let benefit = benefits[index]
                    let isSelected = selectedBenefitIndex == index
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(benefit.iconColor.opacity(isSelected ? 0.16 : 0.08))
                                .frame(width: 44, height: 44)
                            Image(systemName: benefit.icon)
                                .font(.system(size: 20))
                                .foregroundColor(benefit.iconColor)
                        }
                        
                        Text(benefit.title)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(.black.opacity(0.85))
                        
                        Text(benefit.subtitle)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.03), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 3 : 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Theme.Colors.primaryBlue : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                    )
                    .scaleEffect(isSelected ? 1.03 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedBenefitIndex)
                    .onTapGesture {
                        selectedBenefitIndex = index
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // 選択されたメリットの詳細解説パネル（タップで上品にフェード切り替え）
            VStack(alignment: .leading, spacing: 8) {
                Text(benefits[selectedBenefitIndex].title)
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(benefits[selectedBenefitIndex].iconColor)
                
                Text(benefits[selectedBenefitIndex].description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
                    .lineSpacing(4)
                    .frame(height: 72, alignment: .top) // 高さを固定しガタツキを防止
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "f8f9fa"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .id(selectedBenefitIndex) // IDバインドによりタップ時に自然なトランジションを発生させる
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: selectedBenefitIndex)
            
            // 効果を最大にする「大前提」
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(Theme.Colors.primaryBlue)
                    Text(AppTexts.onboardingBenefitPreconditionTitle)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(.black.opacity(0.85))
                }
                
                Text(AppTexts.onboardingBenefitPreconditionDesc)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "f0f7ff"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.primaryBlue.opacity(0.15), lineWidth: 1)
            )
        }
    }    
    // MARK: - Step 4: アプリの使い方説明（案X: 水平タイムライン・ステップカード同期）
    @ViewBuilder
    private func stepAppGuideView() -> some View {
        VStack(spacing: 24) {
            // タイトルエリア
            VStack(spacing: 4) {
                Text(AppTexts.onboardingGuideTitle)
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(.black.opacity(0.85))
                Text(AppTexts.onboardingGuideSubtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.black.opacity(0.5))
            }
            .padding(.top, 4)
            
            // 水平タイムライン
            ZStack {
                // 背景のグレーライン
                Rectangle()
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 3)
                    .padding(.horizontal, 40)
                
                // アクティブなブルーライン（進捗に合わせて伸びる）
                GeometryReader { geo in
                    let stepWidth = (geo.size.width - 80) / 2
                    let activeWidth = CGFloat(currentGuideStep) * stepWidth
                    
                    Rectangle()
                        .fill(Theme.Colors.primaryBlue)
                        .frame(width: activeWidth, height: 3)
                        .padding(.horizontal, 40)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentGuideStep)
                }
                .frame(height: 3)
                
                // 3つのステップドット
                HStack(spacing: 0) {
                    ForEach(0..<guideSteps.count, id: \.self) { index in
                        let isSelected = currentGuideStep == index
                        
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Theme.Colors.primaryBlue : Color.white)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: isSelected ? Theme.Colors.primaryBlue.opacity(0.3) : Color.black.opacity(0.08), radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 1)
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? Theme.Colors.primaryBlue : Color.black.opacity(0.12), lineWidth: 1.5)
                                    )
                                
                                Text("\(index + 1)")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(isSelected ? .white : .black.opacity(0.6))
                            }
                            .scaleEffect(isSelected ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentGuideStep)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                currentGuideStep = index
                            }
                        }
                    }
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 8)
            
            // 現在選択されているステップのカード
            let currentStepData = guideSteps[currentGuideStep]
            
            VStack(spacing: 20) {
                // アイコンの装飾エリア
                ZStack {
                    Circle()
                        .fill(currentStepData.iconColor.opacity(0.08))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(currentStepData.iconColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: currentStepData.icon)
                        .font(.system(size: 30))
                        .foregroundColor(currentStepData.iconColor)
                        .shadow(color: currentStepData.iconColor.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 8)
                
                VStack(spacing: 8) {
                    Text(currentStepData.subtitle)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(currentStepData.iconColor)
                        .tracking(1.5)
                    
                    Text(currentStepData.title)
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.black.opacity(0.85))
                    
                    Text(currentStepData.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.black.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                        .frame(height: 64, alignment: .top) // 高さを固定して見切れやガタツキを防止
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 12)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .id(currentGuideStep) // アニメーション用にIDを付与
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                removal: .opacity
            ))
            .animation(.easeInOut(duration: 0.35), value: currentGuideStep)
            
            // 下部スワイプガイド
            HStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .font(.caption)
                Text(AppTexts.onboardingGuideHint)
                    .font(.system(.caption2, design: .rounded))
            }
            .foregroundColor(.black.opacity(0.35))
            .padding(.top, 4)
        }
    }
    
    // MARK: - Step 5: 目標診断のみの画面（白背景用）
    @ViewBuilder
    private func stepGoalSetupView() -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.Colors.primaryBlue)
                    .shadow(color: Theme.Colors.primaryBlue.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Text(AppTexts.onboardingGoalSetupTitle)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(.black.opacity(0.85))
                    .multilineTextAlignment(.center)
                
                Text(AppTexts.onboardingGoalSetupDesc)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.black.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(2)
            }
            
            Button(action: {
                showingAnalysis = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.body)
                    Text(AppTexts.onboardingGoalSetupButton)
                        .font(.system(.body, design: .rounded).bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.primaryBlue, Theme.Colors.lightBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(color: Theme.Colors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(32)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - タイピングアニメーションの制御
    private func startTypingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            if textCharCount < totalCharCount {
                textCharCount += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    // 各インデックスの文字が表示可能か判定する
    private func isCharVisible(lineIndex: Int, charIndex: Int) -> Bool {
        var globalIndex = 0
        for i in 0..<lineIndex {
            globalIndex += storyLines[i].count
        }
        globalIndex += charIndex
        
        return globalIndex < textCharCount
    }
}
