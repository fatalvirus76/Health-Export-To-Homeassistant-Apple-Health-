import SwiftUI
import HealthKit
import Combine
import UIKit
import BackgroundTasks

// MARK: - Configuration & Constants

struct HealthDataConfig: Identifiable {
    let id: HKQuantityTypeIdentifier
    let name: String
    let displayName: String
    let unit: HKUnit
    let isCumulative: Bool
    let category: HealthCategory

    init(id: HKQuantityTypeIdentifier, name: String, displayName: String? = nil, unit: HKUnit, isCumulative: Bool, category: HealthCategory) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name.replacingOccurrences(of: "_", with: " ").capitalized
        self.unit = unit
        self.isCumulative = isCumulative
        self.category = category
    }
}

// MARK: - Health Categories

enum HealthCategory: String, CaseIterable, Identifiable {
    case sleep = "Sömn"
    case activity = "Aktivitet"
    case distance = "Distanser"
    case vitals = "Vitalvärden"
    case body = "Kroppsmått"
    case nutrition = "Näring"
    case mobility = "Mobilitet"
    case running = "Löpning"
    case sport = "Sport"
    case environment = "Miljö"
    case medical = "Medicinskt"
    case habits = "Vanor"
    case heart = "Hjärta"
    case hearing = "Hörsel"
    case mind = "Sinne"
    case reproductive = "Reproduktion"

    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .activity: return "figure.walk"
        case .distance: return "map"
        case .vitals: return "heart.fill"
        case .body: return "figure.stand"
        case .nutrition: return "fork.knife"
        case .mobility: return "figure.walk.motion"
        case .running: return "figure.run"
        case .sport: return "dumbbell.fill"
        case .environment: return "sun.max.fill"
        case .medical: return "cross.case.fill"
        case .habits: return "checkmark.circle.fill"
        case .heart: return "heart.circle.fill"
        case .hearing: return "hearingaid"
        case .mind: return "brain.head.profile"
        case .reproductive: return "figure.2"
        }
    }
}

// MARK: - Health Data Configuration

final class HealthDataConfiguration: @unchecked Sendable {
    static let shared = HealthDataConfiguration()
    
    let allHealthTypes: [HealthDataConfig]
    
    private init() {
        allHealthTypes = Self.createAllHealthTypes()
    }
    
    private static func createAllHealthTypes() -> [HealthDataConfig] {
        var types: [HealthDataConfig] = []
        
        // MARK: - Sleep
        types.append(contentsOf: [
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_total", displayName: "Sömn (Total)", unit: .hour(), isCumulative: true, category: .sleep),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_rem", displayName: "Sömn (REM)", unit: .hour(), isCumulative: true, category: .sleep),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_deep", displayName: "Sömn (Djup)", unit: .hour(), isCumulative: true, category: .sleep),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_light", displayName: "Sömn (Kärna/Lätt)", unit: .hour(), isCumulative: true, category: .sleep),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_awake", displayName: "Vaken i sängen", unit: .hour(), isCumulative: true, category: .sleep),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_efficiency", displayName: "Sömn-effektivitet", unit: .percent(), isCumulative: false, category: .sleep),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_in_bed", displayName: "Tid i sängen", unit: .hour(), isCumulative: true, category: .sleep),
        ])
        
        // MARK: - Activity
        types.append(contentsOf: [
            HealthDataConfig(id: .stepCount, name: "steps", displayName: "Steg", unit: .count(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .activeEnergyBurned, name: "active_energy", displayName: "Aktiv energi", unit: .kilocalorie(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .appleExerciseTime, name: "exercise_time", displayName: "Träningstid", unit: .minute(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .appleStandTime, name: "stand_time", displayName: "Stå-tid", unit: .minute(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .appleMoveTime, name: "move_time", displayName: "Rörelsestid", unit: .minute(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .basalEnergyBurned, name: "basal_energy", displayName: "Basalenergi", unit: .kilocalorie(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .flightsClimbed, name: "flights_climbed", displayName: "Trappor", unit: .count(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .appleExerciseTime, name: "daily_quotes", displayName: "Dagliga mål", unit: .count(), isCumulative: true, category: .activity),
            HealthDataConfig(id: .appleExerciseTime, name: "goal_calories", displayName: "Kalorimål", unit: .kilocalorie(), isCumulative: false, category: .activity),
            HealthDataConfig(id: .appleExerciseTime, name: "goal_steps", displayName: "Stegmål", unit: .count(), isCumulative: false, category: .activity),
        ])
        
        // MARK: - Distance
        types.append(contentsOf: [
            HealthDataConfig(id: .distanceWalkingRunning, name: "distance_walking", displayName: "Gång/Löpning", unit: .meter(), isCumulative: true, category: .distance),
            HealthDataConfig(id: .distanceCycling, name: "distance_cycling", displayName: "Cykling", unit: .meter(), isCumulative: true, category: .distance),
            HealthDataConfig(id: .distanceSwimming, name: "distance_swimming", displayName: "Simning", unit: .meter(), isCumulative: true, category: .distance),
            HealthDataConfig(id: .distanceWheelchair, name: "distance_wheelchair", displayName: "Rullstol", unit: .meter(), isCumulative: true, category: .distance),
            HealthDataConfig(id: .distanceDownhillSnowSports, name: "distance_snow_sports", displayName: "Skidsport", unit: .meter(), isCumulative: true, category: .distance),
            HealthDataConfig(id: .distanceWalkingRunning, name: "distance_indoor", displayName: "Inomhusgång", unit: .meter(), isCumulative: true, category: .distance),
            HealthDataConfig(id: .distanceWalkingRunning, name: "distance_treadmill", displayName: "Löpband", unit: .meter(), isCumulative: true, category: .distance),
        ])
        
        // MARK: - Sport & Performance
        types.append(contentsOf: [
            HealthDataConfig(id: .vo2Max, name: "vo2_max", displayName: "VO2 Max", unit: .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute()), isCumulative: false, category: .sport),
            HealthDataConfig(id: .swimmingStrokeCount, name: "swimming_strokes", displayName: "Simtag", unit: .count(), isCumulative: true, category: .sport),
            HealthDataConfig(id: .pushCount, name: "push_count", displayName: "Push-antal", unit: .count(), isCumulative: true, category: .sport),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "workouts_count_today", displayName: "Träningspass (antal idag)", unit: .count(), isCumulative: true, category: .sport),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "workouts_minutes_today", displayName: "Träningstid (min idag)", unit: .minute(), isCumulative: true, category: .sport),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "workouts_energy_today", displayName: "Träning (kcal idag)", unit: .kilocalorie(), isCumulative: true, category: .sport),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "workouts_distance_today", displayName: "Träning (meter idag)", unit: .meter(), isCumulative: true, category: .sport),
            HealthDataConfig(id: .appleExerciseTime, name: "workout_streak", displayName: "Tränings-serie", unit: .count(), isCumulative: false, category: .sport),
            HealthDataConfig(id: .appleExerciseTime, name: "weekly_exercise_minutes", displayName: "Veckovis träning (min)", unit: .minute(), isCumulative: true, category: .sport),
        ])
        
        // MARK: - Environment
        types.append(contentsOf: [
            HealthDataConfig(id: .timeInDaylight, name: "time_in_daylight", displayName: "Tid i dagsljus", unit: .minute(), isCumulative: true, category: .environment),
            HealthDataConfig(id: .numberOfTimesFallen, name: "times_fallen", displayName: "Fall", unit: .count(), isCumulative: true, category: .environment),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleeping_wrist_temp", displayName: "Handledstemp (sömn)", unit: .degreeCelsius(), isCumulative: false, category: .environment),
            HealthDataConfig(id: .environmentalAudioExposure, name: "env_noise", displayName: "Omgivningsljud", unit: .decibelAWeightedSoundPressureLevel(), isCumulative: false, category: .environment),
            HealthDataConfig(id: .headphoneAudioExposure, name: "headphone_audio", displayName: "Hörlursljud", unit: .decibelAWeightedSoundPressureLevel(), isCumulative: false, category: .environment),
            HealthDataConfig(id: .uvExposure, name: "uv_exposure", displayName: "UV-exponering", unit: .count(), isCumulative: false, category: .environment),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "ambient_temp", displayName: "Omgivningstemperatur", unit: .degreeCelsius(), isCumulative: false, category: .environment),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "air_pressure", displayName: "Lufttryck", unit: .millimeterOfMercury(), isCumulative: false, category: .environment),
        ])
        
        // MARK: - Body
        types.append(contentsOf: [
            HealthDataConfig(id: .bodyMass, name: "weight", displayName: "Vikt", unit: .gramUnit(with: .kilo), isCumulative: false, category: .body),
            HealthDataConfig(id: .bodyMassIndex, name: "bmi", displayName: "BMI", unit: .count(), isCumulative: false, category: .body),
            HealthDataConfig(id: .bodyFatPercentage, name: "body_fat", displayName: "Kroppsfett", unit: .percent(), isCumulative: false, category: .body),
            HealthDataConfig(id: .leanBodyMass, name: "lean_body_mass", displayName: "Muskelmassa", unit: .gramUnit(with: .kilo), isCumulative: false, category: .body),
            HealthDataConfig(id: .height, name: "height", displayName: "Längd", unit: .meter(), isCumulative: false, category: .body),
            HealthDataConfig(id: .waistCircumference, name: "waist_circumference", displayName: "Midjemått", unit: .meter(), isCumulative: false, category: .body),
            HealthDataConfig(id: .waistCircumference, name: "hip_circumference", displayName: "Höftmått", unit: .meter(), isCumulative: false, category: .body),
            HealthDataConfig(id: .bodyMass, name: "body_weight_trend", displayName: "Viktkurva", unit: .gramUnit(with: .kilo), isCumulative: false, category: .body),
            HealthDataConfig(id: .bodyMassIndex, name: "bmr", displayName: "BMR (Basa metabolism)", unit: .kilocalorie(), isCumulative: false, category: .body),
        ])
        
        // MARK: - Vitals
        types.append(contentsOf: [
            HealthDataConfig(id: .heartRate, name: "heart_rate", displayName: "Puls", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .restingHeartRate, name: "resting_heart_rate", displayName: "Vilopuls", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .walkingHeartRateAverage, name: "walking_hr_avg", displayName: "Puls (gång)", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .heartRateVariabilitySDNN, name: "hrv_sdnn", displayName: "HRV", unit: .secondUnit(with: .milli), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .oxygenSaturation, name: "spo2", displayName: "Syremättnad", unit: .percent(), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .bodyTemperature, name: "body_temp", displayName: "Kroppstemperatur", unit: .degreeCelsius(), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .respiratoryRate, name: "respiratory_rate", displayName: "Andningsfrekvens", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .bloodPressureSystolic, name: "bp_systolic", displayName: "Blodtryck (sys)", unit: .millimeterOfMercury(), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .bloodPressureDiastolic, name: "bp_diastolic", displayName: "Blodtryck (dia)", unit: .millimeterOfMercury(), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .bloodGlucose, name: "blood_glucose", displayName: "Blodsocker", unit: .moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter()), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .bloodPressureSystolic, name: "blood_pressure_avg", displayName: "Blodtryck (medel)", unit: .millimeterOfMercury(), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .heartRateVariabilitySDNN, name: "hrv_rmssd", displayName: "HRV (RMSSD)", unit: .secondUnit(with: .milli), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .oxygenSaturation, name: "oxygen_saturation_trend", displayName: "Syremättnad (trend)", unit: .percent(), isCumulative: false, category: .vitals),
            HealthDataConfig(id: .bodyTemperature, name: "wrist_temperature", displayName: "Handledstemperatur", unit: .degreeCelsius(), isCumulative: false, category: .vitals),
        ])
        
        // MARK: - Mobility
        types.append(contentsOf: [
            HealthDataConfig(id: .appleWalkingSteadiness, name: "walking_steadiness", displayName: "Gångstabilitet", unit: .percent(), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .walkingSpeed, name: "walking_speed", displayName: "Gånghastighet", unit: .meter().unitDivided(by: .second()), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .walkingStepLength, name: "step_length", displayName: "Steglängd", unit: .meter(), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .walkingAsymmetryPercentage, name: "walking_asymmetry", displayName: "Gång-asymmetri", unit: .percent(), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .walkingDoubleSupportPercentage, name: "double_support", displayName: "Dubbel-stöd", unit: .percent(), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .stairAscentSpeed, name: "stair_ascent", displayName: "Trappuppgång", unit: .meter().unitDivided(by: .second()), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .stairDescentSpeed, name: "stair_descent", displayName: "Trappnedgång", unit: .meter().unitDivided(by: .second()), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .appleWalkingSteadiness, name: "balance_score", displayName: "Balans-poäng", unit: .count(), isCumulative: false, category: .mobility),
            HealthDataConfig(id: .appleWalkingSteadiness, name: "fall_risk", displayName: "Fall-risk", unit: .percent(), isCumulative: false, category: .mobility),
        ])
        
        // MARK: - Running
        types.append(contentsOf: [
            HealthDataConfig(id: .runningPower, name: "running_power", displayName: "Löpeffekt", unit: .watt(), isCumulative: false, category: .running),
            HealthDataConfig(id: .runningSpeed, name: "running_speed", displayName: "Löphastighet", unit: .meter().unitDivided(by: .second()), isCumulative: false, category: .running),
            HealthDataConfig(id: .runningGroundContactTime, name: "ground_contact_time", displayName: "Markkontakt", unit: .secondUnit(with: .milli), isCumulative: false, category: .running),
            HealthDataConfig(id: .runningVerticalOscillation, name: "vertical_oscillation", displayName: "Vertikal rörelse", unit: .meterUnit(with: .centi), isCumulative: false, category: .running),
            HealthDataConfig(id: .runningStrideLength, name: "stride_length", displayName: "Stridlängd", unit: .meter(), isCumulative: false, category: .running),
            HealthDataConfig(id: .runningPower, name: "running_cadence", displayName: "Kadens", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .running),
            HealthDataConfig(id: .runningSpeed, name: "running_vertical_ratio", displayName: "Vertikal ratio", unit: .percent(), isCumulative: false, category: .running),
        ])
        
        // MARK: - Heart Health
        types.append(contentsOf: [
            HealthDataConfig(id: .heartRate, name: "heart_rate_max", displayName: "Max puls", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .heart),
            HealthDataConfig(id: .heartRate, name: "heart_rate_min", displayName: "Min puls", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .heart),
            HealthDataConfig(id: .heartRate, name: "heart_rate_avg", displayName: "Genomsnittlig puls", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .heart),
            HealthDataConfig(id: .heartRateVariabilitySDNN, name: "heart_rate_recovery", displayName: "Puls-återhämtning", unit: .count().unitDivided(by: .minute()), isCumulative: false, category: .heart),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "cardio_fitness", displayName: "Kardio-fitness", unit: .count(), isCumulative: false, category: .heart),
            HealthDataConfig(id: .heartRate, name: "low_heart_rate_events", displayName: "Låga pulshändelser", unit: .count(), isCumulative: true, category: .heart),
            HealthDataConfig(id: .heartRate, name: "high_heart_rate_events", displayName: "Höga pulshändelser", unit: .count(), isCumulative: true, category: .heart),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "heart_arrhythmia", displayName: "Hjärtrytm-störning", unit: .count(), isCumulative: false, category: .heart),
        ])
        
        // MARK: - Hearing
        types.append(contentsOf: [
            HealthDataConfig(id: .environmentalAudioExposure, name: "headphone_exposure", displayName: "Hörlursexponering", unit: .percent(), isCumulative: true, category: .hearing),
            HealthDataConfig(id: .environmentalAudioExposure, name: "noise_exposure_level", displayName: "Bullerexponering", unit: .percent(), isCumulative: true, category: .hearing),
            HealthDataConfig(id: .environmentalAudioExposure, name: "hearing_health", displayName: "Hälso-hörsel", unit: .percent(), isCumulative: false, category: .hearing),
        ])
        
        // MARK: - Mind & Mental Health
        types.append(contentsOf: [
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "mindful_minutes", displayName: "Mindfulness (minuter)", unit: .minute(), isCumulative: true, category: .mind),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "mood", displayName: "Stämning", unit: .count(), isCumulative: false, category: .mind),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "stress_level", displayName: "Stress-nivå", unit: .count(), isCumulative: false, category: .mind),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "energy_level", displayName: "Energinivå", unit: .count(), isCumulative: false, category: .mind),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "focus_time", displayName: "Fokus-tid", unit: .minute(), isCumulative: true, category: .mind),
        ])
        
        // MARK: - Nutrition
        types.append(contentsOf: [
            HealthDataConfig(id: .dietaryEnergyConsumed, name: "calories_consumed", displayName: "Kalorier intag", unit: .kilocalorie(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryProtein, name: "protein", displayName: "Protein", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryCarbohydrates, name: "carbs", displayName: "Kolhydrater", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryFiber, name: "fiber", displayName: "Fiber", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietarySugar, name: "sugar", displayName: "Socker", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryFatTotal, name: "fat_total", displayName: "Fett", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryFatSaturated, name: "fat_saturated", displayName: "Mättat fett", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryCholesterol, name: "cholesterol", displayName: "Kolesterol", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietarySodium, name: "sodium", displayName: "Natrium", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryWater, name: "water", displayName: "Vatten", unit: .liter(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryCaffeine, name: "caffeine", displayName: "Koffein", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryVitaminC, name: "vitamin_c", displayName: "Vitamin C", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryVitaminD, name: "vitamin_d", displayName: "Vitamin D", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryCalcium, name: "calcium", displayName: "Kalcium", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryIron, name: "iron", displayName: "Järn", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryPotassium, name: "potassium", displayName: "Kalium", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryEnergyConsumed, name: "meal_count", displayName: "Antal måltider", unit: .count(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryEnergyConsumed, name: "snack_count", displayName: "Antal mellanmål", unit: .count(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryFatMonounsaturated, name: "fat_monounsaturated", displayName: "Enkelomättat fett", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryFatPolyunsaturated, name: "fat_polyunsaturated", displayName: "Fleromättat fett", unit: .gram(), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryVitaminA, name: "beta_carotene", displayName: "Beta-karoten", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryVitaminE, name: "vitamin_e", displayName: "Vitamin E", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryVitaminK, name: "vitamin_k", displayName: "Vitamin K", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryThiamin, name: "thiamin", displayName: "Tiamin (B1)", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryRiboflavin, name: "riboflavin", displayName: "Riboflavin (B2)", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryNiacin, name: "niacin", displayName: "Niacin", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryVitaminB6, name: "vitamin_b6", displayName: "Vitamin B6", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryFolate, name: "folate", displayName: "Folat", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryVitaminB12, name: "vitamin_b12", displayName: "Vitamin B12", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryBiotin, name: "biotin", displayName: "Biotin", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryPantothenicAcid, name: "pantothenic_acid", displayName: "Pantotensyra", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryPhosphorus, name: "phosphorus", displayName: "Fosfor", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryIodine, name: "iodine", displayName: "Jod", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryMagnesium, name: "magnesium", displayName: "Magnesium", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryZinc, name: "zinc", displayName: "Zink", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietarySelenium, name: "selenium", displayName: "Selen", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryCopper, name: "copper", displayName: "Koppar", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryManganese, name: "manganese", displayName: "Mangan", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryChromium, name: "chromium", displayName: "Krom", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryMolybdenum, name: "molybdenum", displayName: "Molybden", unit: .gramUnit(with: .micro), isCumulative: true, category: .nutrition),
            HealthDataConfig(id: .dietaryChloride, name: "chloride", displayName: "Klorid", unit: .gramUnit(with: .milli), isCumulative: true, category: .nutrition),
        ])
        
        // MARK: - Medical
        types.append(contentsOf: [
            HealthDataConfig(id: .peakExpiratoryFlowRate, name: "peak_flow", displayName: "Peak Flow", unit: .liter().unitDivided(by: .minute()), isCumulative: false, category: .medical),
            HealthDataConfig(id: .forcedExpiratoryVolume1, name: "fev1", displayName: "FEV1", unit: .liter(), isCumulative: false, category: .medical),
            HealthDataConfig(id: .forcedVitalCapacity, name: "fvc", displayName: "FVC", unit: .liter(), isCumulative: false, category: .medical),
            HealthDataConfig(id: .inhalerUsage, name: "inhaler_usage", displayName: "Inhalator-användning", unit: .count(), isCumulative: true, category: .medical),
            HealthDataConfig(id: .insulinDelivery, name: "insulin_delivery", displayName: "Insulin", unit: .internationalUnit(), isCumulative: true, category: .medical),
            HealthDataConfig(id: .bloodGlucose, name: "insulin_sensitivity", displayName: "Insulin-känslighet", unit: .gramUnit(with: .milli), isCumulative: false, category: .medical),
            HealthDataConfig(id: .bloodGlucose, name: "time_in_range", displayName: "Tid inom mål", unit: .percent(), isCumulative: true, category: .medical),
        ])
        
        // MARK: - Reproductive Health
        types.append(contentsOf: [
            HealthDataConfig(id: .bodyTemperature, name: "basal_body_temp", displayName: "Basal kroppstemperatur", unit: .degreeCelsius(), isCumulative: false, category: .reproductive),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "menstrual_cycle", displayName: "Menstruationscykel", unit: .day(), isCumulative: false, category: .reproductive),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "ovulation_date", displayName: "Ägglossning", unit: .day(), isCumulative: false, category: .reproductive),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "menstrual_flow", displayName: "Menstruationsflöde", unit: .count(), isCumulative: false, category: .reproductive),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sexual_activity", displayName: "Sexuell aktivitet", unit: .count(), isCumulative: true, category: .reproductive),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "pregnancy", displayName: "Graviditet", unit: .count(), isCumulative: false, category: .reproductive),
        ])
        
        // MARK: - Habits
        types.append(contentsOf: [
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "mindful_minutes", displayName: "Mindfulness (minuter)", unit: .minute(), isCumulative: true, category: .habits),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "handwashing_count", displayName: "Handtvätt (antal)", unit: .count(), isCumulative: true, category: .habits),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "teeth_brushing", displayName: "Tandborstning", unit: .count(), isCumulative: true, category: .habits),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "medication_reminder", displayName: "Medicin-påminnelse", unit: .count(), isCumulative: true, category: .habits),
            HealthDataConfig(id: .appleSleepingWristTemperature, name: "sleep_schedule", displayName: "Sömn-schema", unit: .count(), isCumulative: true, category: .habits),
        ])
        
        return types
    }
}

// Convenience accessor
var allHealthTypes: [HealthDataConfig] {
    HealthDataConfiguration.shared.allHealthTypes
}

// MARK: - Data Models

struct LogMessage: Identifiable, Equatable, Sendable {
    let id = UUID()
    let time = Date()
    let message: String
    let isError: Bool

    var fullString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "[\(formatter.string(from: time))] \(message)"
    }
    
    static func == (lhs: LogMessage, rhs: LogMessage) -> Bool {
        lhs.id == rhs.id
    }
}

enum LogFilter: String, CaseIterable {
    case all = "Alla"
    case errors = "Endast fel"
    case success = "Framgångsrika"
}

struct HAServerConfig: Identifiable, Equatable, Sendable {
    let id = UUID()
    let name: String
    let url: String
    let token: String
    
    var isValid: Bool {
        !url.isEmpty && !token.isEmpty && URL(string: url) != nil
    }
    
    var cleanURL: String {
        url.hasSuffix("/") ? String(url.dropLast()) : url
    }
}

// MARK: - ADDED

struct HomeAssistantStatePayload: Encodable, Sendable {
    let state: Double
    let attributes: HomeAssistantStateAttributes
}

// MARK: - ADDED

struct HomeAssistantStateAttributes: Encodable, Sendable {
    let unitOfMeasurement: String
    let friendlyName: String
    let icon: String
    let source: String
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case unitOfMeasurement = "unit_of_measurement"
        case friendlyName = "friendly_name"
        case icon
        case source
        case lastUpdated = "last_updated"
    }
}

// MARK: - Errors

enum HealthExportError: LocalizedError, Equatable, Sendable {
    case noServersConfigured
    case healthKitUnauthorized
    case networkFailure(String)
    case invalidResponse(Int)
    case noData(String)
    case encodingError

    var errorDescription: String? {
        switch self {
        case .noServersConfigured:
            return "Inga servrar konfigurerade"
        case .healthKitUnauthorized:
            return "HealthKit-behörighet saknas"
        case .networkFailure(let msg):
            return "Nätverksfel: \(msg)"
        case .invalidResponse(let code):
            return "Ogiltig svarskod: \(code)"
        case .noData(let metric):
            return "Ingen data tillgänglig för: \(metric)"
        case .encodingError:
            return "Kodningsfel"
        }
    }
}

// MARK: - Workout Summary

struct WorkoutSummary: Equatable, Sendable {
    let count: Double
    let minutes: Double
    let kcal: Double
    let meters: Double
    
    static let zero = WorkoutSummary(count: 0, minutes: 0, kcal: 0, meters: 0)
}

// MARK: - ADDED

struct HeartRateSummary: Equatable, Sendable {
    let min: Double
    let max: Double
    let average: Double
}

// MARK: - Export Result

struct ExportResult: Equatable, Sendable {
    let successCount: Int
    let totalCount: Int
    let timestamp: Date
    
    var isSuccess: Bool { successCount > 0 }
    var successRate: Double { totalCount > 0 ? Double(successCount) / Double(totalCount) : 0 }
}

// MARK: - App Storage Keys

enum AppStorageKey: String, Sendable {
    case haURL = "ha_url"
    case haToken = "ha_token"
    case haURL2 = "ha_url_2"
    case haToken2 = "ha_token_2"
    case entityPrefix = "entity_prefix"
    case lookbackDays = "lookback_days"
    case autoExport = "auto_export"
    case enabledMetrics = "enabled_metrics"
    case lastExportTimestamp = "last_export_timestamp"
    case lastExportSuccess = "last_export_success"
    case lastExportCount = "last_export_count"
}

// MARK: - Background Task Handler (BGTaskScheduler)

/// Registrerar och schemalägger periodiska bakgrundskörningar.
/// BGAppRefreshTask: ungefär var 20:e minut (iOS bestämmer exakt när).
/// BGProcessingTask: längre körningar, kräver nätverk, körs när iOS tillåter.
final class BackgroundTaskHandler: @unchecked Sendable {
    private let healthStore: HKHealthStore
    private var lastRunTime: Date = .distantPast
    private let cooldownInterval: TimeInterval = 900 // 15 minutes
    
    // Stored values for background tasks
    var entityPrefix: String = ""
    var servers: [HAServerConfig] = []
    var isAuthorized: Bool = false
    var lookbackDays: Int = 30
    
    private let config = HealthDataConfiguration.shared
    private let maxLogs = 200
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - Task-identifierare (måste matcha Info.plist)
    static let refreshTaskID = "fatalv.Health-Export.refresh"
    static let processingTaskID = "fatalv.Health-Export.processing"
    
    // MARK: - Registrering (en gång per process, före didFinishLaunching slutar)
    private static let registrationLock = NSLock()
    private static var didRegister = false
    
    static func registerTasksIfNeeded() {
        registrationLock.lock()
        defer { registrationLock.unlock() }
        guard !didRegister else { return }
        didRegister = true
        
        let scheduler = BGTaskScheduler.shared
        
        scheduler.register(forTaskWithIdentifier: refreshTaskID, using: nil) { task in
            // Alltid boka nästa körning direkt (iOS-krav: innan tasken avslutas)
            scheduleNextRunIfEnabled()
            handle(task: task)
        }
        
        scheduler.register(forTaskWithIdentifier: processingTaskID, using: nil) { task in
            scheduleNextRunIfEnabled()
            handle(task: task)
        }
    }
    
    // MARK: - Schemaläggning
    
    /// Bokar nästa refresh- (~20 min) och processing-körning (~2 h). No-op om autoExport är av.
    static func scheduleNextRunIfEnabled() {
        guard UserDefaults.standard.bool(forKey: AppStorageKey.autoExport.rawValue) else { return }
        
        let scheduler = BGTaskScheduler.shared
        
        let refresh = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        refresh.earliestBeginDate = Date(timeIntervalSinceNow: 20 * 60)
        try? scheduler.submit(refresh)
        
        let processing = BGProcessingTaskRequest(identifier: processingTaskID)
        processing.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60)
        processing.requiresNetworkConnectivity = true
        processing.requiresExternalPower = false
        try? scheduler.submit(processing)
    }
    
    static func cancelScheduledRuns() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskID)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: processingTaskID)
    }
    
    // MARK: - Task-hantering
    
    private static func handle(task: BGTask) {
        let box = TaskCompletionBox()
        task.expirationHandler = {
            guard !box.isDone else { return }
            box.isDone = true
            task.setTaskCompleted(success: false)
        }
        
        Task { @MainActor in
            let ok = await HealthManager.shared.runBackgroundExport()
            guard !box.isDone else { return }
            box.isDone = true
            task.setTaskCompleted(success: ok)
        }
    }
    
    func canRun() -> Bool {
        return Date().timeIntervalSince(lastRunTime) > cooldownInterval
    }
    
    func recordRun() {
        lastRunTime = Date()
    }
    
    func runExport() async {
        guard canRun() else { return }
        recordRun()
        
        // This would be called from HealthManager
    }
}

/// Trådsäker flagga för "task redan avslutad" (setTaskCompleted får bara anropas en gång).
private final class TaskCompletionBox: @unchecked Sendable {
    var isDone = false
}

// MARK: - ADDED

private struct ModernHeroCard: View {
    let isAuthorized: Bool
    let isExporting: Bool
    let connectionStatus: String
    let exportedMetricsCount: Int
    let lastExportDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Health Export")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Synkar Apple Health till Home Assistant")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
                    .padding(12)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            HStack(spacing: 10) {
                ModernStatusPill(
                    title: isAuthorized ? "HealthKit" : "Behörighet",
                    value: isAuthorized ? "OK" : "Saknas",
                    systemImage: isAuthorized ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    color: isAuthorized ? .green : .orange
                )

                ModernStatusPill(
                    title: "Anslutning",
                    value: connectionStatus,
                    systemImage: "network",
                    color: connectionStatus.localizedCaseInsensitiveContains("ok") ? .green : .blue
                )
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(exportedMetricsCount)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("senast exporterade")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let lastExportDate {
                        Text(lastExportDate, style: .relative)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("senaste export")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    } else {
                        Text(isExporting ? "Aktiv" : "Ej körd")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("status")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.27, blue: 0.95),
                            Color(red: 0.56, green: 0.22, blue: 0.92),
                            Color(red: 0.00, green: 0.72, blue: 0.86)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: Color.blue.opacity(0.22), radius: 22, x: 0, y: 14)
        }
        .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

// MARK: - ADDED

private struct ModernStatusPill: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.62))

                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.14), in: Capsule())
    }
}

// MARK: - ADDED

private struct ModernMetricRow: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isEnabled ? Color.accentColor : Color.secondary.opacity(0.28))
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))

                Text(subtitle)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - MODIFIED (Main View & UI Sections)

struct ContentView: View {
    // MARK: - AppStorage Properties
    @AppStorage(AppStorageKey.haURL.rawValue) private var haURL: String = "http://homeassistant.local:8123"
    @AppStorage(AppStorageKey.haToken.rawValue) private var haToken: String = ""
    @AppStorage(AppStorageKey.haURL2.rawValue) private var haURL2: String = ""
    @AppStorage(AppStorageKey.haToken2.rawValue) private var haToken2: String = ""
    @AppStorage(AppStorageKey.entityPrefix.rawValue) private var entityPrefix: String = "sensor.health_"
    @AppStorage(AppStorageKey.lookbackDays.rawValue) private var lookbackDays: Int = 30
    @AppStorage(AppStorageKey.autoExport.rawValue) private var autoExport: Bool = false
    @AppStorage(AppStorageKey.enabledMetrics.rawValue) private var enabledMetricsData: Data = Data()
    
    // MARK: - State
    @StateObject private var healthManager = HealthManager.shared
    @State private var logFilter: LogFilter = .all
    
    // MARK: - Computed Properties
    private var enabledMetrics: Set<String> {
        get {
            guard let decoded = try? JSONDecoder().decode(Set<String>.self, from: enabledMetricsData) else {
                return Set(allHealthTypes.map { $0.name })
            }
            return decoded
        }
    }
    
    private func updateEnabledMetrics(_ newValue: Set<String>) {
        if let encoded = try? JSONEncoder().encode(newValue) {
            enabledMetricsData = encoded
        }
    }
    
    private func syncSettings() {
        var servers: [HAServerConfig] = []
        
        if !haURL.isEmpty && !haToken.isEmpty {
            servers.append(HAServerConfig(name: "Server 1", url: haURL, token: haToken))
        }
        if !haURL2.isEmpty && !haToken2.isEmpty {
            servers.append(HAServerConfig(name: "Server 2", url: haURL2, token: haToken2))
        }
        
        healthManager.configure(
            servers: servers,
            entityPrefix: entityPrefix,
            lookbackDays: lookbackDays
        )
    }
    
    // MARK: - MODIFIED
    var body: some View {
        NavigationStack {
            Form {
                ModernHeroCard(
                    isAuthorized: healthManager.isAuthorized,
                    isExporting: healthManager.isExporting,
                    connectionStatus: healthManager.connectionStatus,
                    exportedMetricsCount: healthManager.exportedMetricsCount,
                    lastExportDate: healthManager.lastExportDate
                )

                configurationWarningsSection
                healthKitStatusSection
                serverConfigurationSection
                commonSettingsSection
                automationSection
                
                if let lastExport = healthManager.lastExportDate {
                    exportStatusSection(lastExport: lastExport)
                }
                
                exportActionsSection
                logsSection
            }
            .scrollContentBackground(.hidden)
            .background {
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemBackground),
                        Color.accentColor.opacity(0.08),
                        Color(uiColor: .secondarySystemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .navigationTitle("Health Export")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.accentColor)
            .onAppear(perform: onAppear)
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private var configurationWarningsSection: some View {
        if !healthManager.configurationWarnings.isEmpty {
            Section {
                ForEach(healthManager.configurationWarnings, id: \.self) { warning in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(warning)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var healthKitStatusSection: some View {
        Section {
            HStack {
                Text("Behörighetsstatus")
                Spacer()
                Text(healthManager.isAuthorized ? "Beviljad" : "Ej beviljad")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(healthManager.isAuthorized ? Color.green : Color.red)
                    .clipShape(Capsule())
            }
            
            if !healthManager.isAuthorized {
                Button(action: {
                    healthManager.requestAuthorization()
                }) {
                    Label("Be om behörighet", systemImage: "hand.tap.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        } header: {
            Label("HealthKit", systemImage: "heart.text.square.fill")
        }
    }
    
    @ViewBuilder
    private var serverConfigurationSection: some View {
        Section {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField("URL", text: $haURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                SecureField("Token", text: $haToken)
            }
        } header: {
            Label("Server 1 (Primär)", systemImage: "server.rack")
        }
        
        Section {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField("URL", text: $haURL2)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                SecureField("Token", text: $haToken2)
            }
        } header: {
            Label("Server 2 (Valfri)", systemImage: "server.rack")
        }
    }
    
    private var commonSettingsSection: some View {
        Section {
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField("Prefix", text: $entityPrefix)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            
            Stepper(value: $lookbackDays, in: 1...365) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Sökperiod: \(lookbackDays) dagar")
                }
            }
            
            NavigationLink {
                MetricsSelectionView(
                    enabledMetrics: enabledMetrics,
                    onUpdate: updateEnabledMetrics
                )
            } label: {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Välj datapunkter")
                    Spacer()
                    Text("\(enabledMetrics.count)/\(allHealthTypes.count)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        } header: {
            Label("Gemensamma Inställningar", systemImage: "gearshape.fill")
        }
    }
    
    private var automationSection: some View {
        Section {
            Toggle(isOn: $autoExport) {
                Label("Auto-export (Bakgrund)", systemImage: "arrow.triangle.2.circlepath")
            }
            .onChange(of: autoExport) { _, newValue in
                syncSettings()
                if newValue {
                    healthManager.enableBackgroundDelivery()
                    BackgroundTaskHandler.scheduleNextRunIfEnabled()
                } else {
                    healthManager.disableBackgroundDelivery()
                    BackgroundTaskHandler.cancelScheduledRuns()
                }
            }
            
            Text("Använder Background Delivery. Uppdateras automatiskt när ny data finns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
        } header: {
            Label("Automation", systemImage: "bolt.fill")
        }
    }
    
    private func exportStatusSection(lastExport: Date) -> some View {
        Section {
            HStack {
                Text("Senaste export")
                Spacer()
                Text(lastExport, style: .relative)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Status")
                Spacer()
                Label(healthManager.lastExportSuccess ? "Slutförd" : "Misslyckades",
                      systemImage: healthManager.lastExportSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(healthManager.lastExportSuccess ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((healthManager.lastExportSuccess ? Color.green : Color.red).opacity(0.15))
                    .clipShape(Capsule())
            }
            HStack {
                Text("Exporterade värden")
                Spacer()
                Text("\(healthManager.exportedMetricsCount)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        } header: {
            Label("Export-status", systemImage: "chart.bar.doc.horizontal")
        }
    }
    
    private var recentValuesSection: some View {
        Section {
            ForEach(healthManager.lastSentValues.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.2f", value))
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        } header: {
            Label("Senaste Exporterade Värden", systemImage: "list.number")
        }
    }
    
    private var exportActionsSection: some View {
        Section {
            Button(action: {
                syncSettings()
                healthManager.testConnection()
            }) {
                Label("Testa anslutningar", systemImage: "network")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(healthManager.isExporting)
            
            HStack {
                Text("Anslutning:")
                Spacer()
                Text(healthManager.connectionStatus)
                    .font(.caption.bold())
                    .foregroundColor(healthManager.connectionColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(healthManager.connectionColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // MARK: - MODIFIED
            Button(action: performExport) {
                if healthManager.isExporting {
                    VStack(spacing: 10) {
                        HStack {
                            Label("Exporterar", systemImage: "arrow.up.heart.fill")
                                .font(.headline)

                            Spacer()

                            ProgressView()
                                .tint(.white)
                        }

                        if !healthManager.currentMetric.isEmpty {
                            Text(healthManager.currentMetric)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                        }

                        ProgressView(value: healthManager.exportProgress)
                            .progressViewStyle(.linear)
                            .tint(.white)
                    }
                    .padding(.vertical, 6)
                } else {
                    Label("Kör export nu", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(healthManager.isExporting || !healthManager.hasValidConfiguration)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.accentColor.opacity(0.10))
            )
            .padding(.vertical, 4)
            
        } header: {
            Label("Manuell Körning", systemImage: "play.circle.fill")
        }
    }
    
    private var logsSection: some View {
        Section {
            Picker("Filter", selection: $logFilter) {
                ForEach(LogFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 4)
            
            if filteredLogs.isEmpty {
                Text("Inga loggar")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredLogs.reversed()) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Text(log.time, style: .time)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                
                                Text(log.message)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(log.isError ? .red : .primary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 250)
            }
        } header: {
            HStack {
                Label("Logg (\(filteredLogs.count))", systemImage: "terminal.fill")
                Spacer()
                Menu {
                    Button(action: {
                        let allLogs = healthManager.logs.map { $0.fullString }.joined(separator: "\n")
                        UIPasteboard.general.string = allLogs
                    }) {
                        Label("Kopiera alla", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive, action: {
                        healthManager.clearLogs()
                    }) {
                        Label("Rensa", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func performExport() {
        Task {
            syncSettings()
            await healthManager.exportData(enabledMetrics: enabledMetrics)
        }
    }
    
    private func onAppear() {
        healthManager.requestAuthorization()
        syncSettings()
        if autoExport {
            healthManager.enableBackgroundDelivery()
            BackgroundTaskHandler.scheduleNextRunIfEnabled()
        }
    }
    
    private var filteredLogs: [LogMessage] {
        switch logFilter {
        case .all:
            return healthManager.logs
        case .errors:
            return healthManager.logs.filter { $0.isError }
        case .success:
            return healthManager.logs.filter { !$0.isError && $0.message.contains("✅") }
        }
    }
}

// MARK: - MODIFIED (Metrics Selection View)

struct MetricsSelectionView: View {
    let enabledMetrics: Set<String>
    let onUpdate: (Set<String>) -> Void
    
    @State private var searchText = ""
    @State private var localEnabledMetrics: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    init(enabledMetrics: Set<String>, onUpdate: @escaping (Set<String>) -> Void) {
        self.enabledMetrics = enabledMetrics
        self.onUpdate = onUpdate
        _localEnabledMetrics = State(initialValue: enabledMetrics)
    }
    
    var body: some View {
        // MARK: - MODIFIED
        List {
            ForEach(HealthCategory.allCases) { category in
                Section(header: categoryHeader(for: category)) {
                    ForEach(metricsFor(category), id: \.name) { config in
                        if matchesSearch(config) {
                            Toggle(isOn: Binding(
                                get: { localEnabledMetrics.contains(config.name) },
                                set: { isEnabled in
                                    if isEnabled {
                                        localEnabledMetrics.insert(config.name)
                                    } else {
                                        localEnabledMetrics.remove(config.name)
                                    }
                                    onUpdate(localEnabledMetrics)
                                }
                            )) {
                                ModernMetricRow(
                                    title: config.displayName,
                                    subtitle: config.name,
                                    isEnabled: localEnabledMetrics.contains(config.name)
                                )
                            }
                            .tint(.accentColor)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color.accentColor.opacity(0.06),
                    Color(uiColor: .secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .searchable(text: $searchText, prompt: "Sök datapunkter")
        .navigationTitle("Välj datapunkter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        localEnabledMetrics = Set(allHealthTypes.map { $0.name })
                        onUpdate(localEnabledMetrics)
                    }) {
                        Label("Markera alla", systemImage: "checkmark.square.fill")
                    }
                    Button(action: {
                        localEnabledMetrics = []
                        onUpdate(localEnabledMetrics)
                    }) {
                        Label("Avmarkera alla", systemImage: "square")
                    }
                } label: {
                    Image(systemName: "checklist")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Klar") {
                    dismiss()
                }
                .font(.body.bold())
            }
        }
    }
    
    private func categoryHeader(for category: HealthCategory) -> some View {
        HStack {
            Label(category.rawValue, systemImage: category.icon)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                toggleCategory(category)
            }) {
                Text(categoryEnabled(category) ? "Av" : "På")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func metricsFor(_ category: HealthCategory) -> [HealthDataConfig] {
        allHealthTypes.filter { $0.category == category }
    }
    
    private func matchesSearch(_ config: HealthDataConfig) -> Bool {
        searchText.isEmpty
        || config.displayName.localizedCaseInsensitiveContains(searchText)
        || config.name.localizedCaseInsensitiveContains(searchText)
    }
    
    private func categoryEnabled(_ category: HealthCategory) -> Bool {
        let categoryMetrics = metricsFor(category)
        return categoryMetrics.allSatisfy { localEnabledMetrics.contains($0.name) }
    }
    
    private func toggleCategory(_ category: HealthCategory) {
        let categoryMetrics = metricsFor(category)
        let allEnabled = categoryEnabled(category)
        
        for metric in categoryMetrics {
            if allEnabled {
                localEnabledMetrics.remove(metric.name)
            } else {
                localEnabledMetrics.insert(metric.name)
            }
        }
        onUpdate(localEnabledMetrics)
    }
}

// MARK: - Health Manager

@MainActor
final class HealthManager: ObservableObject {
    // MARK: - Shared (BGTaskScheduler lansering kräver en nåbar instans)
    static let shared = HealthManager()
    
    // MARK: - Dependencies
    private let healthStore: HKHealthStore
    
    // Background task handler - thread-safe wrapper
    private let backgroundHandler: BackgroundTaskHandler
    
    // MARK: - UI State
    @Published private(set) var isAuthorized = false
    @Published private(set) var isExporting = false
    @Published private(set) var connectionStatus: String = "Ej testad"
    @Published private(set) var connectionColor: Color = .gray
    @Published private(set) var logs: [LogMessage] = []
    
    // MARK: - Export Progress
    @Published private(set) var exportProgress: Double = 0.0
    @Published private(set) var currentMetric: String = ""
    @Published private(set) var lastExportDate: Date?
    @Published private(set) var lastExportSuccess: Bool = false
    @Published private(set) var lastSentValues: [String: Double] = [:]
    @Published private(set) var exportedMetricsCount: Int = 0
    
    // MARK: - Configuration (thread-safe access via MainActor)
    private var servers: [HAServerConfig] = []
    private var entityPrefix: String = ""
    private var lookbackDays: Int = 30
    
    // MARK: - Constants
    private let maxLogs = 200
    private let config = HealthDataConfiguration.shared
    
    // MARK: - MODIFIED
    private let specialMetricKeys: Set<String> = [
        "sleep_total",
        "sleep_rem",
        "sleep_deep",
        "sleep_light",
        "sleep_awake",
        "sleep_efficiency",
        "sleep_in_bed",
        "mindful_minutes",
        "handwashing_count",
        "workouts_count_today",
        "workouts_minutes_today",
        "workouts_energy_today",
        "workouts_distance_today",
        "workout_streak",
        "weekly_exercise_minutes",
        "heart_rate_max",
        "heart_rate_min",
        "heart_rate_avg"
    ]
    
    // MARK: - ADDED
    private let unsupportedSyntheticMetricKeys: Set<String> = [
        "daily_quotes",
        "goal_calories",
        "goal_steps",
        "distance_indoor",
        "distance_treadmill",
        "ambient_temp",
        "air_pressure",
        "hip_circumference",
        "body_weight_trend",
        "bmr",
        "blood_pressure_avg",
        "hrv_rmssd",
        "oxygen_saturation_trend",
        "wrist_temperature",
        "balance_score",
        "fall_risk",
        "running_cadence",
        "running_vertical_ratio",
        "cardio_fitness",
        "low_heart_rate_events",
        "high_heart_rate_events",
        "heart_arrhythmia",
        "headphone_exposure",
        "noise_exposure_level",
        "hearing_health",
        "mood",
        "stress_level",
        "energy_level",
        "focus_time",
        "meal_count",
        "snack_count",
        "insulin_sensitivity",
        "time_in_range",
        "menstrual_cycle",
        "ovulation_date",
        "menstrual_flow",
        "sexual_activity",
        "pregnancy",
        "teeth_brushing",
        "medication_reminder",
        "sleep_schedule"
    ]
    
    // MARK: - Initialization
    init() {
        self.healthStore = HKHealthStore()
        self.backgroundHandler = BackgroundTaskHandler(healthStore: healthStore)
        loadLastExportStatus()
    }
    
    // MARK: - Computed Properties
    var hasValidConfiguration: Bool {
        !servers.isEmpty && isAuthorized
    }
    
    var configurationWarnings: [String] {
        var warnings: [String] = []
        
        if servers.isEmpty {
            warnings.append("Inga servrar konfigurerade")
        }
        
        if !isAuthorized {
            warnings.append("HealthKit-behörighet saknas")
        }
        
        if entityPrefix.isEmpty {
            warnings.append("Entity-prefix är tomt")
        }
        
        return warnings
    }
    
    // MARK: - Configuration
    func configure(servers: [HAServerConfig], entityPrefix: String, lookbackDays: Int) {
        self.servers = servers
        self.entityPrefix = entityPrefix
        self.lookbackDays = lookbackDays
        
        // Update background handler
        backgroundHandler.servers = servers
        backgroundHandler.entityPrefix = entityPrefix
        backgroundHandler.lookbackDays = lookbackDays
    }
    
    // MARK: - Persistence
    private func loadLastExportStatus() {
        let timestamp = UserDefaults.standard.double(forKey: AppStorageKey.lastExportTimestamp.rawValue)
        if timestamp > 0 {
            lastExportDate = Date(timeIntervalSince1970: timestamp)
            lastExportSuccess = UserDefaults.standard.bool(forKey: AppStorageKey.lastExportSuccess.rawValue)
            exportedMetricsCount = UserDefaults.standard.integer(forKey: AppStorageKey.lastExportCount.rawValue)
        }
    }
    
    private func saveLastExportStatus(success: Bool, count: Int) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: AppStorageKey.lastExportTimestamp.rawValue)
        UserDefaults.standard.set(success, forKey: AppStorageKey.lastExportSuccess.rawValue)
        UserDefaults.standard.set(count, forKey: AppStorageKey.lastExportCount.rawValue)
    }
    
    // MARK: - Logging
    func log(_ message: String, isError: Bool = false) {
        let newLog = LogMessage(message: message, isError: isError)
        logs.append(newLog)
        
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
        
        #if DEBUG
        print("LOG: \(message)")
        #endif
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func setConnectionStatus(_ status: String, color: Color) {
        connectionStatus = status
        connectionColor = color
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        let typesToRead = buildReadTypes()
        
        guard !typesToRead.isEmpty else {
            log("Inga typer att läsa", isError: true)
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            Task { @MainActor [weak self] in
                self?.isAuthorized = success
                
                if let error = error {
                    self?.log("Behörighetsfel: \(error.localizedDescription)", isError: true)
                }
                
                // Observer-queries måste återskapas vid varje appstart (de överlever inte
                // processdöd). Utan detta registreras aldrig bakgrundsleverans efter omstart.
                if success, UserDefaults.standard.bool(forKey: AppStorageKey.autoExport.rawValue) {
                    self?.enableBackgroundDelivery()
                    BackgroundTaskHandler.scheduleNextRunIfEnabled()
                }
            }
        }
    }
    
    private func buildReadTypes() -> Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        
        // Quantity types
        for config in config.allHealthTypes {
            if let type = HKObjectType.quantityType(forIdentifier: config.id) {
                types.insert(type)
            }
        }
        
        // Category types
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        if let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulType)
        }
        if let handwashingType = HKObjectType.categoryType(forIdentifier: .handwashingEvent) {
            types.insert(handwashingType)
        }
        
        // Workout type
        types.insert(HKObjectType.workoutType())
        
        return types
    }
    
    // MARK: - Background Delivery
    func enableBackgroundDelivery() {
        guard isAuthorized else { return }
        log("🔔 Aktiverar bakgrundsleverans...")
        
        backgroundHandler.isAuthorized = true
        
        let typesToObserve: [HKQuantityTypeIdentifier] = [
            .stepCount, .heartRate, .activeEnergyBurned, .bodyMass
        ]
        
        for id in typesToObserve {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }
            
            healthStore.enableBackgroundDelivery(for: type, frequency: .hourly) { [weak self] success, error in
                Task { @MainActor [weak self] in
                    if success {
                        self?.log("✅ Bakgrund aktiverad för \(id.rawValue)")
                    } else if let error = error {
                        self?.log("❌ Bakgrundfel för \(id.rawValue): \(error.localizedDescription)", isError: true)
                    }
                }
            }
            
            // Create observer query with proper MainActor handling
            let handler = backgroundHandler
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                guard let self = self else {
                    completionHandler()
                    return
                }
                
                if error != nil {
                    completionHandler()
                    return
                }
                
                Task { @MainActor [weak self] in
                    guard let self = self else {
                        completionHandler()
                        return
                    }
                    
                    if handler.canRun() {
                        handler.recordRun()
                        let enabledMetrics = Self.loadEnabledMetricsFromDefaults()
                        await self.exportData(isBackground: true, enabledMetrics: enabledMetrics)
                    }
                    completionHandler()
                }
            }
            healthStore.execute(query)
        }
    }
    
    func disableBackgroundDelivery() {
        healthStore.disableAllBackgroundDelivery { [weak self] success, _ in
            Task { @MainActor [weak self] in
                if success {
                    self?.log("🔕 Bakgrundsleverans avstängd.")
                }
            }
        }
    }
    
    // MARK: - Bakgrundsexport (anropas av BGTaskScheduler)
    
    /// Kör en fullständig bakgrundsexport. Återanvänder lagrade inställningar
    /// (servers/token/prefix/lookback/metrics) så att den fungerar även när
    /// iOS lanserar appen direkt i bakgrunden utan att ContentView hunnit köras.
    func runBackgroundExport() async -> Bool {
        guard UserDefaults.standard.bool(forKey: AppStorageKey.autoExport.rawValue) else { return true }
        guard backgroundHandler.canRun() else { return true }
        backgroundHandler.recordRun()
        
        // Återläs inställningar om de inte är satta (bakgrundslansering)
        if servers.isEmpty {
            loadSettingsFromStorage()
        }
        
        guard !servers.isEmpty else {
            log("❌ Bakgrundsexport: inga servrar konfigurerade", isError: true)
            return false
        }
        
        let enabled = Self.loadEnabledMetricsFromDefaults()
        await exportData(isBackground: true, enabledMetrics: enabled)
        return lastExportSuccess
    }
    
    /// Bygger server/prefix/lookback-konfiguration direkt från UserDefaults
    /// (samma nycklar som ContentView använder). Körs vid bakgrundslansering.
    private func loadSettingsFromStorage() {
        let d = UserDefaults.standard
        var serverList: [HAServerConfig] = []
        
        if let url = d.string(forKey: AppStorageKey.haURL.rawValue), !url.isEmpty,
           let token = d.string(forKey: AppStorageKey.haToken.rawValue), !token.isEmpty {
            serverList.append(HAServerConfig(name: "Server 1", url: url, token: token))
        }
        if let url = d.string(forKey: AppStorageKey.haURL2.rawValue), !url.isEmpty,
           let token = d.string(forKey: AppStorageKey.haToken2.rawValue), !token.isEmpty {
            serverList.append(HAServerConfig(name: "Server 2", url: url, token: token))
        }
        
        let prefix = d.string(forKey: AppStorageKey.entityPrefix.rawValue) ?? "sensor.health_"
        let days = d.object(forKey: AppStorageKey.lookbackDays.rawValue) as? Int ?? 30
        
        configure(servers: serverList, entityPrefix: prefix, lookbackDays: days)
    }
    
    /// Läser användarens val av datapunkter (enabled_metrics). Tomt/okänt → alla typer.
    static func loadEnabledMetricsFromDefaults() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKey.enabledMetrics.rawValue),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data),
              !decoded.isEmpty else {
            return Set(HealthDataConfiguration.shared.allHealthTypes.map { $0.name })
        }
        return decoded
    }
    
    // MARK: - Connection Test
    func testConnection() {
        guard !servers.isEmpty else {
            setConnectionStatus("Inga servrar", color: .red)
            log("❌ Inga servrar konfigurerade", isError: true)
            return
        }
        
        setConnectionStatus("Testar...", color: .orange)
        
        // Capture current servers for closure
        let currentServers = servers
        
        Task {
            var hasFailure = false
            
            for server in currentServers {
                guard let url = URL(string: "\(server.cleanURL)/api/") else {
                    hasFailure = true
                    log("❌ \(server.name): Ogiltig URL", isError: true)
                    continue
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(server.token)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 10
                
                let serverName = server.name
                
                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        log("✅ \(serverName): Anslutning OK!")
                    } else {
                        hasFailure = true
                        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                        log("❌ \(serverName): HTTP \(code)", isError: true)
                    }
                } catch {
                    hasFailure = true
                    log("❌ \(serverName): \(error.localizedDescription)", isError: true)
                }
            }
            
            setConnectionStatus(hasFailure ? "Fel" : "Alla OK", color: hasFailure ? .red : .green)
        }
    }
    
    // MARK: - Export Data
    func exportData(isBackground: Bool = false, enabledMetrics: Set<String>) async {
        guard !servers.isEmpty else {
            if !isBackground { log("❌ Inga servrar konfigurerade!", isError: true) }
            return
        }
        
        // Capture current values for async operations
        let currentServers = servers
        let currentEntityPrefix = entityPrefix
        let currentLookbackDays = lookbackDays
        let currentConfig = config
        
        if !isBackground {
            isExporting = true
            exportProgress = 0.0
            currentMetric = ""
            exportedMetricsCount = 0
            lastSentValues.removeAll()
            log("🚀 Startar export till \(currentServers.count) server(ar)...")
        }
        
        // MARK: - MODIFIED
        let standardMetrics = currentConfig.allHealthTypes.filter {
            enabledMetrics.contains($0.name)
            && $0.category != .sleep
            && !specialMetricKeys.contains($0.name)
            && !unsupportedSyntheticMetricKeys.contains($0.name)
        }
        
        // MARK: - ADDED
        let skippedUnsupportedMetrics = enabledMetrics.intersection(unsupportedSyntheticMetricKeys)
        if !isBackground && !skippedUnsupportedMetrics.isEmpty {
            log("ℹ️ \(skippedUnsupportedMetrics.count) syntetiska datapunkter hoppas över tills säker HealthKit-källa finns.")
        }
        
        let totalCategories = standardMetrics.count + 7
        var completed: Double = 0
        var successCount = 0
        
        // 1. Standard HealthKit data
        for config in standardMetrics {
            if !isBackground {
                currentMetric = config.displayName
                exportProgress = completed / Double(totalCategories)
            }
            
            do {
                let value = try await fetchQuantityData(
                    for: config.id,
                    unit: config.unit,
                    isCumulative: config.isCumulative,
                    lookbackDays: currentLookbackDays
                )
                
                let entityID = sanitizeEntityID(config.name, prefix: currentEntityPrefix)
                
                for server in currentServers {
                    try await sendToHomeAssistant(
                        server: server,
                        entityID: entityID,
                        state: value,
                        unit: config.unit.unitString,
                        friendlyName: config.displayName,
                        maxRetries: 3
                    )
                }
                
                successCount += 1
                lastSentValues[config.displayName] = value
                if !isBackground { log("✅ \(config.displayName): \(String(format: "%.2f", value))") }
            } catch {
                if !isBackground {
                    if !(error is URLError) {
                        log("⚠️ \(config.displayName): \(error.localizedDescription)", isError: false)
                    }
                }
            }
            
            completed += 1
        }
        
        // MARK: - MODIFIED
        // 2. Sleep
        let sleepKeys: Set<String> = [
            "sleep_total",
            "sleep_rem",
            "sleep_deep",
            "sleep_light",
            "sleep_awake",
            "sleep_in_bed",
            "sleep_efficiency"
        ]

        let hasSleepEnabled = !enabledMetrics.isDisjoint(with: sleepKeys)

        if hasSleepEnabled {
            currentMetric = "Sömn"
            do {
                let sleepData = try await fetchSleepBreakdown()

                for (key, value) in sleepData where enabledMetrics.contains(key) {
                    let entityID = sanitizeEntityID(key, prefix: currentEntityPrefix)
                    let friendlyName = currentConfig.allHealthTypes.first(where: { $0.name == key })?.displayName ?? key.capitalized
                    let unit = key == "sleep_efficiency" ? "%" : "h"

                    for server in currentServers {
                        try await sendToHomeAssistant(
                            server: server,
                            entityID: entityID,
                            state: value,
                            unit: unit,
                            friendlyName: friendlyName,
                            maxRetries: 3
                        )
                    }

                    lastSentValues[friendlyName] = value
                }

                successCount += 1
                if !isBackground { log("✅ Sömn exporterad") }
            } catch {
                if !isBackground { log("⚠️ Fel vid sömnhämtning: \(error.localizedDescription)", isError: true) }
            }
        }

        completed += 1
        
        // 3. Mindfulness
        if enabledMetrics.contains("mindful_minutes") {
            currentMetric = "Mindfulness"
            do {
                let mindful = try await fetchMindfulMinutes()
                let entityID = sanitizeEntityID("mindful_minutes", prefix: currentEntityPrefix)
                
                for server in currentServers {
                    try await sendToHomeAssistant(
                        server: server,
                        entityID: entityID,
                        state: mindful,
                        unit: "min",
                        friendlyName: "Mindfulness (minuter)",
                        maxRetries: 3
                    )
                }
                successCount += 1
                lastSentValues["Mindfulness (minuter)"] = mindful
                if !isBackground { log("✅ Mindfulness: \(String(format: "%.0f", mindful)) min") }
            } catch {
                if !isBackground { log("⚠️ Mindfulness: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1
        
        // 4. Handwashing
        if enabledMetrics.contains("handwashing_count") {
            currentMetric = "Handtvätt"
            do {
                let count = try await fetchHandwashingCountToday()
                let entityID = sanitizeEntityID("handwashing_count", prefix: currentEntityPrefix)
                
                for server in currentServers {
                    try await sendToHomeAssistant(
                        server: server,
                        entityID: entityID,
                        state: count,
                        unit: "st",
                        friendlyName: "Handtvätt (antal)",
                        maxRetries: 3
                    )
                }
                successCount += 1
                lastSentValues["Handtvätt (antal)"] = count
                if !isBackground { log("✅ Handtvätt: \(Int(count))") }
            } catch {
                if !isBackground { log("⚠️ Handtvätt: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1
        
        // 5. Workouts
        let workoutKeys: Set<String> = [
            "workouts_count_today", "workouts_minutes_today",
            "workouts_energy_today", "workouts_distance_today"
        ]
        
        if !enabledMetrics.isDisjoint(with: workoutKeys) {
            currentMetric = "Träning (Workouts)"
            do {
                let summary = try await fetchWorkoutSummaryToday()
                
                let mapping: [(key: String, value: Double, unit: String, friendly: String)] = [
                    ("workouts_count_today", summary.count, "st", "Träningspass (antal idag)"),
                    ("workouts_minutes_today", summary.minutes, "min", "Träningstid (min idag)"),
                    ("workouts_energy_today", summary.kcal, "kcal", "Träning (kcal idag)"),
                    ("workouts_distance_today", summary.meters, "m", "Träning (meter idag)")
                ]
                
                for item in mapping where enabledMetrics.contains(item.key) {
                    let entityID = sanitizeEntityID(item.key, prefix: currentEntityPrefix)
                    for server in currentServers {
                        try await sendToHomeAssistant(
                            server: server,
                            entityID: entityID,
                            state: item.value,
                            unit: item.unit,
                            friendlyName: item.friendly,
                            maxRetries: 3
                        )
                    }
                    lastSentValues[item.friendly] = item.value
                }
                
                successCount += 1
                if !isBackground {
                    log("✅ Workouts: \(Int(summary.count)) pass, \(Int(summary.minutes)) min, \(Int(summary.kcal)) kcal, \(Int(summary.meters)) m")
                }
            } catch {
                if !isBackground { log("⚠️ Workouts: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1
        
        // MARK: - ADDED
        // 6. Heart rate summary
        let heartSummaryKeys: Set<String> = [
            "heart_rate_min",
            "heart_rate_max",
            "heart_rate_avg"
        ]

        if !enabledMetrics.isDisjoint(with: heartSummaryKeys) {
            currentMetric = "Pulsstatistik"

            do {
                let summary = try await fetchHeartRateSummaryToday()

                let mapping: [(key: String, value: Double, unit: String, friendly: String)] = [
                    ("heart_rate_min", summary.min, "count/min", "Min puls"),
                    ("heart_rate_max", summary.max, "count/min", "Max puls"),
                    ("heart_rate_avg", summary.average, "count/min", "Genomsnittlig puls")
                ]

                for item in mapping where enabledMetrics.contains(item.key) {
                    let entityID = sanitizeEntityID(item.key, prefix: currentEntityPrefix)

                    for server in currentServers {
                        try await sendToHomeAssistant(
                            server: server,
                            entityID: entityID,
                            state: item.value,
                            unit: item.unit,
                            friendlyName: item.friendly,
                            maxRetries: 3
                        )
                    }

                    lastSentValues[item.friendly] = item.value
                }

                successCount += 1
                if !isBackground {
                    log("✅ Pulsstatistik exporterad")
                }
            } catch {
                if !isBackground {
                    log("⚠️ Pulsstatistik: \(error.localizedDescription)", isError: true)
                }
            }
        }
        completed += 1

        // MARK: - ADDED
        // 7. Workout streak
        if enabledMetrics.contains("workout_streak") {
            currentMetric = "Tränings-serie"

            do {
                let streak = try await fetchWorkoutStreak(maxDays: 90)
                let entityID = sanitizeEntityID("workout_streak", prefix: currentEntityPrefix)

                for server in currentServers {
                    try await sendToHomeAssistant(
                        server: server,
                        entityID: entityID,
                        state: Double(streak),
                        unit: "d",
                        friendlyName: "Tränings-serie",
                        maxRetries: 3
                    )
                }

                successCount += 1
                lastSentValues["Tränings-serie"] = Double(streak)
                if !isBackground {
                    log("✅ Tränings-serie: \(streak) dagar")
                }
            } catch {
                if !isBackground {
                    log("⚠️ Tränings-serie: \(error.localizedDescription)", isError: true)
                }
            }
        }
        completed += 1

        // MARK: - ADDED
        // 8. Weekly exercise minutes
        if enabledMetrics.contains("weekly_exercise_minutes") {
            currentMetric = "Veckovis träning"

            do {
                let minutes = try await fetchWeeklyExerciseMinutes()
                let entityID = sanitizeEntityID("weekly_exercise_minutes", prefix: currentEntityPrefix)

                for server in currentServers {
                    try await sendToHomeAssistant(
                        server: server,
                        entityID: entityID,
                        state: minutes,
                        unit: "min",
                        friendlyName: "Veckovis träning (min)",
                        maxRetries: 3
                    )
                }

                successCount += 1
                lastSentValues["Veckovis träning (min)"] = minutes
                if !isBackground {
                    log("✅ Veckovis träning: \(Int(minutes)) min")
                }
            } catch {
                if !isBackground {
                    log("⚠️ Veckovis träning: \(error.localizedDescription)", isError: true)
                }
            }
        }
        completed += 1
        
        // Update status
        isExporting = false
        exportProgress = 1.0
        currentMetric = ""
        lastExportDate = Date()
        lastExportSuccess = successCount > 0
        exportedMetricsCount = successCount
        
        saveLastExportStatus(success: successCount > 0, count: successCount)
        
        if !isBackground {
            log("🏁 Export klar! \(successCount)/\(Int(totalCategories)) kategorier behandlade.")
        }
    }
    
    // MARK: - HealthKit Fetchers
    
    private func fetchQuantityData(
        for typeIdentifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        isCumulative: Bool,
        lookbackDays: Int
    ) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            throw HealthExportError.healthKitUnauthorized
        }
        
        if isCumulative && type.aggregationStyle != .cumulative {
            return 0.0
        }
        
        let now = Date()
        
        // MARK: - MODIFIED
        let fallbackStartDate = Calendar.current.startOfDay(for: now)
        let calculatedStartDate = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now)

        let startDate = isCumulative
            ? fallbackStartDate
            : calculatedStartDate ?? fallbackStartDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            if isCumulative {
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let quantity = result?.sumQuantity(), quantity.is(compatibleWith: unit) {
                        continuation.resume(returning: quantity.doubleValue(for: unit))
                    } else {
                        continuation.resume(returning: 0.0)
                    }
                }
                healthStore.execute(query)
            } else {
                let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate,
                    limit: 1,
                    sortDescriptors: [sort]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample, sample.quantity.is(compatibleWith: unit) else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: sample.quantity.doubleValue(for: unit))
                }
                healthStore.execute(query)
            }
        }
    }
    
    // MARK: - MODIFIED
    private func fetchSleepBreakdown() async throws -> [String: Double] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return [:]
        }

        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .hour, value: -36, to: endDate) else {
            return [:]
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                var total = 0.0
                var rem = 0.0
                var core = 0.0
                var deep = 0.0
                var awake = 0.0
                var inBed = 0.0

                if let samples = results as? [HKCategorySample] {
                    for sample in samples {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0

                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.inBed.rawValue:
                            inBed += duration

                        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                            total += duration

                        case HKCategoryValueSleepAnalysis.awake.rawValue:
                            awake += duration

                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                            core += duration
                            total += duration

                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            deep += duration
                            total += duration

                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            rem += duration
                            total += duration

                        default:
                            break
                        }
                    }
                }

                let effectiveInBed = max(inBed, total + awake)
                let efficiency = effectiveInBed > 0 ? (total / effectiveInBed) * 100.0 : 0.0

                continuation.resume(returning: [
                    "sleep_total": total,
                    "sleep_rem": rem,
                    "sleep_light": core,
                    "sleep_deep": deep,
                    "sleep_awake": awake,
                    "sleep_in_bed": effectiveInBed,
                    "sleep_efficiency": efficiency
                ])
            }

            healthStore.execute(query)
        }
    }
    
    private func fetchMindfulMinutes() async throws -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return 0
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let totalSeconds = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: totalSeconds / 60.0)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchHandwashingCountToday() async throws -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .handwashingEvent) else {
            return 0
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: Double(samples?.count ?? 0))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - MODIFIED
    private func fetchWorkoutSummaryToday() async throws -> WorkoutSummary {
        let workoutType = HKObjectType.workoutType()

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []

                let count = Double(workouts.count)
                let minutes = workouts.reduce(0.0) { $0 + ($1.duration / 60.0) }

                let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
                let walkingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
                let cyclingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceCycling)
                let swimmingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceSwimming)

                let kcal = workouts.reduce(0.0) { partialResult, workout in
                    guard let energyType else { return partialResult }
                    return partialResult + (workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0)
                }

                let meters = workouts.reduce(0.0) { partialResult, workout in
                    var total = 0.0

                    if let walkingDistanceType {
                        total += workout.statistics(for: walkingDistanceType)?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                    }

                    if let cyclingDistanceType {
                        total += workout.statistics(for: cyclingDistanceType)?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                    }

                    if let swimmingDistanceType {
                        total += workout.statistics(for: swimmingDistanceType)?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                    }

                    return partialResult + total
                }

                continuation.resume(returning: WorkoutSummary(count: count, minutes: minutes, kcal: kcal, meters: meters))
            }

            healthStore.execute(query)
        }
    }
    
    // MARK: - ADDED
    private func fetchHeartRateSummaryToday() async throws -> HeartRateSummary {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthExportError.healthKitUnauthorized
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: [.discreteMin, .discreteMax, .discreteAverage]
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())

                let minValue = result?.minimumQuantity()?.doubleValue(for: unit) ?? 0.0
                let maxValue = result?.maximumQuantity()?.doubleValue(for: unit) ?? 0.0
                let avgValue = result?.averageQuantity()?.doubleValue(for: unit) ?? 0.0

                continuation.resume(returning: HeartRateSummary(
                    min: minValue,
                    max: maxValue,
                    average: avgValue
                ))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - ADDED
    private func fetchWorkoutCountForDay(_ date: Date) async throws -> Int {
        let workoutType = HKObjectType.workoutType()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples?.count ?? 0)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - ADDED
    private func fetchWorkoutStreak(maxDays: Int) async throws -> Int {
        let calendar = Calendar.current
        var streak = 0

        for offset in 0..<maxDays {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                continue
            }

            let count = try await fetchWorkoutCountForDay(date)

            if count > 0 {
                streak += 1
            } else if offset == 0 {
                continue
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - ADDED
    private func fetchWeeklyExerciseMinutes() async throws -> Double {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            throw HealthExportError.healthKitUnauthorized
        }

        let now = Date()

        guard let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) else {
            return 0.0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let minutes = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0.0
                continuation.resume(returning: minutes)
            }

            healthStore.execute(query)
        }
    }
    
    // MARK: - Helpers
    
    private func sanitizeEntityID(_ rawName: String, prefix: String) -> String {
        let rawString = "\(prefix)\(rawName)"
        let lower = rawString.lowercased()
        let spaced = lower
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
        let safeChars = Set("abcdefghijklmnopqrstuvwxyz0123456789_.")
        return String(spaced.filter { safeChars.contains($0) })
    }
    
    private func sendToHomeAssistant(
        server: HAServerConfig,
        entityID: String,
        state: Double,
        unit: String,
        friendlyName: String,
        maxRetries: Int = 3
    ) async throws {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                guard let url = URL(string: "\(server.cleanURL)/api/states/\(entityID)") else {
                    throw HealthExportError.networkFailure("Ogiltig URL")
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(server.token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 15
                
                // MARK: - MODIFIED
                let roundedState = (state * 100).rounded() / 100

                let payload = HomeAssistantStatePayload(
                    state: roundedState,
                    attributes: HomeAssistantStateAttributes(
                        unitOfMeasurement: unit,
                        friendlyName: friendlyName,
                        icon: getIcon(for: entityID),
                        source: "iOS Health Export",
                        lastUpdated: ISO8601DateFormatter().string(from: Date())
                    )
                )

                request.httpBody = try JSONEncoder().encode(payload)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HealthExportError.networkFailure("Inget svar")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw HealthExportError.invalidResponse(httpResponse.statusCode)
                }
                
                return
                
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let delay = UInt64(attempt * 2_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        throw lastError ?? HealthExportError.networkFailure("Okänt fel")
    }
    
    private func getIcon(for entityID: String) -> String {
        if entityID.contains("heart") || entityID.contains("cardio") || entityID.contains("arrhythmia") { return "mdi:heart-pulse" }
        if entityID.contains("step") || entityID.contains("walk") { return "mdi:walk" }
        if entityID.contains("sleep") || entityID.contains("bed") || entityID.contains("schedule") { return "mdi:sleep" }
        if entityID.contains("weight") || entityID.contains("bmi") || entityID.contains("mass") { return "mdi:weight" }
        if entityID.contains("energy") || entityID.contains("calor") || entityID.contains("bmr") { return "mdi:fire" }
        if entityID.contains("distance") { return "mdi:map-marker-distance" }
        if entityID.contains("blood") { return "mdi:water" }
        if entityID.contains("oxygen") || entityID.contains("spo2") || entityID.contains("respiratory") { return "mdi:lungs" }
        if entityID.contains("temp") { return "mdi:thermometer" }
        if entityID.contains("glucose") || entityID.contains("insulin") { return "mdi:diabetes" }
        if entityID.contains("mindful") || entityID.contains("focus") { return "mdi:meditation" }
        if entityID.contains("handwashing") { return "mdi:hand-wash" }
        if entityID.contains("workouts") || entityID.contains("exercise") { return "mdi:dumbbell" }
        if entityID.contains("cycling") { return "mdi:bicycle" }
        if entityID.contains("swim") || entityID.contains("water") || entityID.contains("depth") { return "mdi:swim" }
        if entityID.contains("fall") || entityID.contains("balance") { return "mdi:account-alert" }
        if entityID.contains("uv") || entityID.contains("sun") || entityID.contains("daylight") { return "mdi:weather-sunny" }
        if entityID.contains("noise") || entityID.contains("audio") || entityID.contains("hearing") { return "mdi:ear-hearing" }
        if entityID.contains("alcohol") { return "mdi:glass-cocktail" }
        if entityID.contains("vitamin") || entityID.contains("magnesium") || entityID.contains("zinc") || entityID.contains("iron") || entityID.contains("potassium") || entityID.contains("calcium") || entityID.contains("sodium") || entityID.contains("iodine") || entityID.contains("selenium") || entityID.contains("copper") || entityID.contains("manganese") || entityID.contains("chromium") || entityID.contains("molybdenum") || entityID.contains("chloride") || entityID.contains("phosphorus") { return "mdi:pill" }
        if entityID.contains("protein") || entityID.contains("carbs") || entityID.contains("fat") || entityID.contains("fiber") || entityID.contains("sugar") || entityID.contains("meal") || entityID.contains("snack") { return "mdi:food-apple" }
        if entityID.contains("caffeine") { return "mdi:coffee" }
        if entityID.contains("tooth") || entityID.contains("teeth") { return "mdi:tooth-outline" }
        if entityID.contains("symptom") { return "mdi:alert-circle-outline" }
        if entityID.contains("menstrual") || entityID.contains("ovulation") || entityID.contains("pregnancy") || entityID.contains("sexual") { return "mdi:calendar-heart" }
        if entityID.contains("mood") || entityID.contains("stress") || entityID.contains("energy_level") { return "mdi:brain" }
        if entityID.contains("pressure") { return "mdi:gauge" }
        
        return "mdi:heart-pulse"
    }
}

// MARK: - App Entry Point

@main
struct HealthExportApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Måste registreras före didFinishLaunching är klar
        BackgroundTaskHandler.registerTasksIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        // Boka nästa körning när appen lämnar förgrunden
                        BackgroundTaskHandler.scheduleNextRunIfEnabled()
                    }
                }
        }
    }
}
