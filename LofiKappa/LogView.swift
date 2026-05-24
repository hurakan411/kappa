import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \DailyWaterLog.dateString, order: .reverse) private var waterLogs: [DailyWaterLog]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    let weekdays = AppTexts.weekdays
    
    var body: some View {
        NavigationView {
            ZStack {
                // 手帳の背景テクスチャを統一
                TimeLightingBackground()
                
                VStack(spacing: 0) {
                    
                    // MARK: - 週間カレンダーカード
                    VStack(spacing: 16) {
                        // 月・年ヘッダー
                        HStack {
                            Text(currentMonthLabel)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                            Spacer()
                            Text(AppTexts.logWeeklyStamp)
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                        
                        // 曜日ヘッダー
                        HStack(spacing: 0) {
                            ForEach(Array(weekdays.enumerated()), id: \.offset) { i, day in
                                Text(day)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(i == 0 ? Color.red.opacity(0.8) : i == 6 ? Theme.Colors.primaryBlue : .secondary)
                            }
                        }
                        
                        // 日付グリッド（手描き風マス）
                        HStack(spacing: 6) {
                            ForEach(0..<calendarGrid.count, id: \.self) { index in
                                let date = calendarGrid[index]
                                let amount = amountForDate(date)
                                let isToday = isToday(date)
                                
                                WeekDayCell(
                                    date: date,
                                    amount: amount,
                                    isToday: isToday,
                                    colorScheme: colorScheme
                                )
                            }
                        }
                    }
                    .padding(20)
                    .background(Theme.Colors.card(for: colorScheme))
                    .cornerRadius(20)
                    .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.18), cornerRadius: 20)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.07), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // MARK: - 本日の記録ヘッダー
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.line")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.primaryBlue)
                            Text(AppTexts.logToday)
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                        }
                        Spacer()
                        if let intakes = todayLog?.intakes, !intakes.isEmpty {
                            Text(AppTexts.logTotalAmountText(intakes.reduce(0) { $0 + $1.amount }))
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Theme.Colors.primaryBlue)
                                .cornerRadius(20)
                                .handDrawnBorder(color: .white.opacity(0.35), cornerRadius: 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 10)
                    
                    // MARK: - 本日の詳細ログ
                    if let todayIntakes = todayLog?.intakes.sorted(by: { $0.timestamp > $1.timestamp }), !todayIntakes.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(todayIntakes.enumerated()), id: \.element.id) { i, intake in
                                    IntakeRow(
                                        intake: intake,
                                        index: todayIntakes.count - i,
                                        colorScheme: colorScheme
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    } else {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "drop.degreesign.fill")
                                .font(.system(size: 44))
                                .foregroundColor(Theme.Colors.lightBlue.opacity(0.6))
                            Text(AppTexts.logEmpty)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle(AppTexts.logTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helpers
    
    private var todayLog: DailyWaterLog? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        return waterLogs.first(where: { $0.dateString == todayStr })
    }
    
    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: Date())
    }
    
    private var calendarGrid: [Date?] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1
        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        
        var dates: [Date?] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private func amountForDate(_ date: Date?) -> Int {
        guard let date = date else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return waterLogs.first(where: { $0.dateString == dateString })?.currentAmount ?? 0
    }
    
    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
}

// MARK: - WeekDayCell (手書きインクスタンプ風カレンダー)

struct WeekDayCell: View {
    let date: Date?
    let amount: Int
    let isToday: Bool
    let colorScheme: ColorScheme
    
    var fillRatio: Double {
        guard amount > 0 else { return 0 }
        return min(Double(amount) / 2000.0, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if let date = date {
                let day = Calendar.current.component(.day, from: date)
                
                ZStack {
                    // ベースカード背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isToday ? Theme.Colors.primaryBlue.opacity(0.06) : Theme.Colors.card(for: colorScheme).opacity(0.6))
                    
                    // 水滴スタンプまたは達成スター
                    if amount > 0 && fillRatio < 1.0 {
                        // 飲んだ日：薄いインクの水滴
                        Image(systemName: "drop.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.Colors.primaryBlue.opacity(0.38))
                            .rotationEffect(.degrees(-10))
                    } else if fillRatio >= 1.0 {
                        // 100%達成日：お祝いのインクスタンプ
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "FCA5A5").opacity(0.75)) // 淡い警告サビ茶/サーモンピンクインク
                            .rotationEffect(.degrees(12))
                    }
                    
                    // 今日のハイライト太枠
                    if isToday {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.Colors.primaryBlue, lineWidth: 1.8)
                    }
                    
                    // テキスト表示
                    VStack(spacing: 3) {
                        Text("\(day)")
                            .font(.system(size: 13, weight: isToday ? .bold : .bold, design: .rounded))
                            .foregroundColor(isToday ? Theme.Colors.primaryBlue : Theme.Colors.text(for: colorScheme))
                        
                        if amount > 0 {
                            Text("\(amount)")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundColor(Theme.Colors.primaryBlue.opacity(0.85))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        } else {
                            Text("·")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                    }
                }
                .frame(height: 62)
                .handDrawnBorder(color: isToday ? Theme.Colors.primaryBlue.opacity(0.35) : Theme.Colors.text(for: colorScheme).opacity(0.12), cornerRadius: 8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(height: 62)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - IntakeRow

struct IntakeRow: View {
    let intake: IntakeRecord
    let index: Int
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            // 番号バッジ
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.primaryBlue)
                .frame(width: 26, height: 26)
                .background(Theme.Colors.primaryBlue.opacity(0.12))
                .clipShape(Circle())
            
            // ドロップアイコン
            Image(systemName: "drop.fill")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.lightBlue)
            
            // 時刻
            Text(timeString(from: intake.timestamp))
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(Theme.Colors.text(for: colorScheme))
            
            Spacer()
            
            // 水分量バッジ (高コントラスト・手帳風)
            Text("+\(intake.amount) ml")
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(Theme.Colors.primaryBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.Colors.primaryBlue.opacity(0.12))
                .cornerRadius(20)
                .handDrawnBorder(color: Theme.Colors.primaryBlue.opacity(0.24), cornerRadius: 20)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Theme.Colors.card(for: colorScheme))
        .cornerRadius(14)
        .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.12), cornerRadius: 14)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

