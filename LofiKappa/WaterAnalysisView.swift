import SwiftUI
import SwiftData

struct WaterAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var customDailyGoal: Int?
    @Binding var selectedGender: Gender
    
    enum SetupStep {
        case choice
        case simple
        case detailed
        case result
    }
    
    @State private var step: SetupStep = .choice
    
    // Q1
    @State private var weightStr: String = ""
    @State private var ageSelection: Int = 0 // 0: 18-54, 1: 55-64, 2: 65+
    
    // Q2
    @State private var activitySelection: Int = 0 // 0: +0, 1: +200, 2: +400, 3: +700
    
    // Q3
    @State private var weatherSelection: Int = 0 // 0: +0, 1: +250, 2: +600
    
    // Q4
    @State private var specialSelection: Int = 2 // 0: +300, 1: +600, 2: +0
    
    @State private var showingResult = false
    @State private var calculatedTarget = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // 手帳の背景テクスチャを統一
                TimeLightingBackground()
                
                switch step {
                case .choice:
                    choiceView
                case .simple:
                    simpleView
                case .detailed:
                    questionsView
                case .result:
                    resultView
                }
            }
            .navigationTitle(AppTexts.analysisTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step != .choice {
                        Button(AppTexts.backBtnText) {
                            withAnimation { step = .choice }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTexts.cancelBtnText) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var choiceView: some View {
        VStack(spacing: 30) {
            Text(AppTexts.analysisMethodTitle)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(Theme.Colors.text(for: colorScheme))
                .padding(.top, 40)
            
            Button(action: {
                withAnimation { step = .simple }
            }) {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                         .font(.largeTitle)
                    Text(AppTexts.analysisMethodSimpleTitle)
                        .font(.system(.headline, design: .rounded).bold())
                    Text(AppTexts.analysisMethodSimpleDesc)
                        .font(.system(.caption, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.card(for: colorScheme))
                .cornerRadius(16)
                .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.2), cornerRadius: 16)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
            .foregroundColor(Theme.Colors.primaryBlue)
            
            Button(action: {
                withAnimation { step = .detailed }
            }) {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                    Text(AppTexts.analysisMethodDetailTitle)
                        .font(.system(.headline, design: .rounded).bold())
                    Text(AppTexts.analysisMethodDetailDesc)
                        .font(.system(.caption, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.card(for: colorScheme))
                .cornerRadius(16)
                .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.2), cornerRadius: 16)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
            .foregroundColor(Theme.Colors.primaryBlue)
            
            Spacer()
        }
        .padding(30)
    }
    
    private var simpleView: some View {
        VStack(spacing: 30) {
            Text(AppTexts.analysisGenderTitle)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(Theme.Colors.text(for: colorScheme))
                .padding(.top, 40)
            
            HStack(spacing: 20) {
                Button(action: {
                    selectedGender = .female
                    customDailyGoal = nil // カスタムをクリアしてベース値を使う
                    dismiss()
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                        Text(AppTexts.analysisGenderFemale)
                            .font(.system(.headline, design: .rounded).bold())
                        Text("1500ml")
                            .font(.system(.caption, design: .rounded).bold())
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.card(for: colorScheme))
                    .cornerRadius(16)
                    .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.2), cornerRadius: 16)
                    .shadow(color: .black.opacity(0.05), radius: 4)
                }
                .foregroundColor(Theme.Colors.primaryBlue)
                
                Button(action: {
                    selectedGender = .male
                    customDailyGoal = nil // カスタムをクリアしてベース値を使う
                    dismiss()
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                        Text(AppTexts.analysisGenderMale)
                            .font(.system(.headline, design: .rounded).bold())
                        Text("2000ml")
                            .font(.system(.caption, design: .rounded).bold())
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.card(for: colorScheme))
                    .cornerRadius(16)
                    .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.2), cornerRadius: 16)
                    .shadow(color: .black.opacity(0.05), radius: 4)
                }
                .foregroundColor(Theme.Colors.primaryBlue)
            }
            
            Spacer()
        }
        .padding(30)
    }

    private var questionsView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Q1: Base
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppTexts.q1Title)
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                    
                    TextField(AppTexts.q1WeightPlaceholder, text: $weightStr)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Theme.Colors.card(for: colorScheme))
                        .cornerRadius(12)
                        .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.12), cornerRadius: 12)
                        .shadow(color: .black.opacity(0.04), radius: 2)
                    
                    Picker("", selection: $ageSelection) {
                        Text(AppTexts.q1Age1).tag(0)
                        Text(AppTexts.q1Age2).tag(1)
                        Text(AppTexts.q1Age3).tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.top, 4)
                }
                .padding(.horizontal)
                
                // Q2: Activity
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppTexts.q2Title)
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                    
                    VStack(spacing: 12) {
                        optionButton(text: AppTexts.q2Option1, icon: "desktopcomputer", isSelected: activitySelection == 0) { activitySelection = 0 }
                        optionButton(text: AppTexts.q2Option2, icon: "figure.walk", isSelected: activitySelection == 1) { activitySelection = 1 }
                        optionButton(text: AppTexts.q2Option3, icon: "figure.run", isSelected: activitySelection == 2) { activitySelection = 2 }
                        optionButton(text: AppTexts.q2Option4, icon: "figure.highintensity.intervaltraining", isSelected: activitySelection == 3) { activitySelection = 3 }
                    }
                }
                .padding(.horizontal)
                
                // Q3: Weather
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppTexts.q3Title)
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                    
                    VStack(spacing: 12) {
                        optionButton(text: AppTexts.q3Option1, icon: "snowflake", isSelected: weatherSelection == 0) { weatherSelection = 0 }
                        optionButton(text: AppTexts.q3Option2, icon: "sun.max", isSelected: weatherSelection == 1) { weatherSelection = 1 }
                        optionButton(text: AppTexts.q3Option3, icon: "flame", isSelected: weatherSelection == 2) { weatherSelection = 2 }
                    }
                }
                .padding(.horizontal)
                
                // Q4: Special
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppTexts.q4Title)
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                    
                    VStack(spacing: 12) {
                        optionButton(text: AppTexts.q4Option1, icon: "figure.maternity", isSelected: specialSelection == 0) { specialSelection = 0 }
                        optionButton(text: AppTexts.q4Option2, icon: "drop", isSelected: specialSelection == 1) { specialSelection = 1 }
                        optionButton(text: AppTexts.q4Option3, icon: "xmark.circle", isSelected: specialSelection == 2) { specialSelection = 2 }
                    }
                }
                .padding(.horizontal)
                
                Button(action: calculateResult) {
                    Text(AppTexts.analysisNext)
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(weightStr.isEmpty ? Color.gray : Theme.Colors.primaryBlue)
                        .cornerRadius(14)
                        .handDrawnBorder(color: .white.opacity(0.3), cornerRadius: 14)
                }
                .disabled(weightStr.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }
    
    private var resultView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text(AppTexts.analysisComplete)
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundColor(Theme.Colors.primaryBlue)
            
            Text(AppTexts.analysisResult(calculatedTarget))
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(Theme.Colors.text(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
            
            Spacer()
            
            Button(action: applyResult) {
                Text(AppTexts.analysisApply)
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primaryBlue)
                    .cornerRadius(14)
                    .handDrawnBorder(color: .white.opacity(0.3), cornerRadius: 14)
            }
            .padding(.horizontal, 30)
            
            Button(AppTexts.analysisRetry) {
                withAnimation { step = .detailed }
            }
            .font(.system(.body, design: .rounded).bold())
            .foregroundColor(Theme.Colors.primaryBlue)
            .padding(.bottom, 40)
        }
    }
    
    private func optionButton(text: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isSelected ? Theme.Colors.primaryBlue : .gray)
                    .frame(width: 30)
                
                Text(text)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.primaryBlue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .padding()
            .background(Theme.Colors.card(for: colorScheme))
            .cornerRadius(12)
            .handDrawnBorder(color: isSelected ? Theme.Colors.primaryBlue : Theme.Colors.text(for: colorScheme).opacity(0.12), cornerRadius: 12)
            .shadow(color: .black.opacity(0.04), radius: 2)
        }
    }
    
    private func calculateResult() {
        guard let weight = Double(weightStr) else { return }
        
        let multiplier: Double
        switch ageSelection {
        case 0: multiplier = 8.0
        case 1: multiplier = 6.0
        case 2: multiplier = 4.0
        default: multiplier = 8.0
        }
        
        let base = 1000.0 + (weight * multiplier)
        
        let activityValues = [0, 100, 200, 300]
        let activity = activityValues[activitySelection]
        
        let weatherValues = [0, 100, 200]
        let weather = weatherValues[weatherSelection]
        
        let specialValues = [100, 200, 0]
        let special = specialValues[specialSelection]
        
        let rawTarget = Int(base) + activity + weather + special
        calculatedTarget = max(1500, min(rawTarget, 2500))
        
        withAnimation {
            step = .result
        }
    }
    
    private func applyResult() {
        customDailyGoal = calculatedTarget
        dismiss()
    }
}

