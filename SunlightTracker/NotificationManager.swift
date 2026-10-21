import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleReminder(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "🌻 해바라기가 시들어가고 있어요!")
        content.body = String(localized: "햇빛을 쐬러 나가볼까요? 15분이면 세로토닌이 분비되기 시작해요.")
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleGoalAchieved(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "🌻 해바라기가 활짝 폈어요!")
        content.body = String(localized: "오늘 \(minutes)분의 햇빛으로 수면의 질이 좋아질 거예요. 대단해요!")
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goal_achieved",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
