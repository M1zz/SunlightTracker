import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    @Published var uvIndex: Int?
    @Published var condition: String = String(localized: "맑음")
    @Published var temperature: Double?
    @Published var isGoodForSunlight: Bool = true
    @Published var recommendation: String = String(localized: "야외 활동하기 좋은 날씨입니다!")
    
    func updateRecommendation() {
        if let uv = uvIndex {
            if uv <= 2 {
                recommendation = String(localized: "자외선이 낮아요. 편하게 야외 활동을 즐기세요 ☀️")
                isGoodForSunlight = true
            } else if uv <= 5 {
                recommendation = String(localized: "적당한 자외선이에요. 30분 정도 야외 활동을 추천해요 🌤")
                isGoodForSunlight = true
            } else if uv <= 7 {
                recommendation = String(localized: "자외선이 높아요. 자외선 차단제를 바르고 나가세요 ⛅")
                isGoodForSunlight = true
            } else {
                recommendation = String(localized: "자외선이 매우 높아요! 가능하면 그늘에서 활동하세요 🌡️")
                isGoodForSunlight = false
            }
        }
    }
    
    // Simulated weather for demo (WeatherKit requires paid developer account)
    func fetchSimulatedWeather() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 6 && hour < 10 {
            uvIndex = 2
            condition = String(localized: "맑음")
            temperature = 18
        } else if hour >= 10 && hour < 14 {
            uvIndex = 5
            condition = String(localized: "맑음")
            temperature = 24
        } else if hour >= 14 && hour < 17 {
            uvIndex = 4
            condition = String(localized: "구름 조금")
            temperature = 22
        } else {
            uvIndex = 1
            condition = String(localized: "저녁")
            temperature = 16
        }
        
        updateRecommendation()
    }
}
