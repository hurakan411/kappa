import Foundation
import SwiftData

enum Gender: String, Codable {
    case female
    case male
    
    var dailyGoal: Int {
        switch self {
        case .female: return 1500
        case .male: return 2000
        }
    }
}

@Model
class UserSettings {
    var genderRaw: String
    var cupSize1: Int
    var cupSize2: Int
    var cupSize3: Int = 300
    var cupSize4: Int = 400
    var cupSize5: Int = 500
    var notificationsEnabled: Bool
    var customDailyGoal: Int?
    
    var dailyGoal: Int {
        return customDailyGoal ?? gender.dailyGoal
    }
    
    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .female }
        set { genderRaw = newValue.rawValue }
    }
    
    init(gender: Gender = .female, cupSize1: Int = 150, cupSize2: Int = 200, cupSize3: Int = 300, cupSize4: Int = 400, cupSize5: Int = 500, notificationsEnabled: Bool = false) {
        self.genderRaw = gender.rawValue
        self.cupSize1 = cupSize1
        self.cupSize2 = cupSize2
        self.cupSize3 = cupSize3
        self.cupSize4 = cupSize4
        self.cupSize5 = cupSize5
        self.notificationsEnabled = notificationsEnabled
    }
}

@Model
class DailyWaterLog {
    @Attribute(.unique) var dateString: String // yyyy-MM-dd format
    var currentAmount: Int
    var kappaCurrentAmount: Int
    var penaltyCount: Int
    var isCompleted: Bool
    var lastDrinkTime: Date?
    var hourlyAmount: Int // Used to track overflow penalty per hour
    var targetKappaId: String
    
    @Relationship(deleteRule: .cascade) var intakes: [IntakeRecord] = []
    
    init(dateString: String, currentAmount: Int = 0, kappaCurrentAmount: Int = 0, penaltyCount: Int = 0, isCompleted: Bool = false, targetKappaId: String = "gamer") {
        self.dateString = dateString
        self.currentAmount = currentAmount
        self.kappaCurrentAmount = kappaCurrentAmount
        self.penaltyCount = penaltyCount
        self.isCompleted = isCompleted
        self.hourlyAmount = 0
        self.targetKappaId = targetKappaId
    }
}

@Model
class IntakeRecord {
    var id: UUID
    var timestamp: Date
    var amount: Int
    
    init(id: UUID = UUID(), timestamp: Date, amount: Int) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
    }
}

@Model
class KappaCollection {
    @Attribute(.unique) var id: String
    var title: String
    var kappaDescription: String
    var dateUnlocked: Date
    
    init(id: String, title: String, kappaDescription: String, dateUnlocked: Date) {
        self.id = id
        self.title = title
        self.kappaDescription = kappaDescription
        self.dateUnlocked = dateUnlocked
    }
}
