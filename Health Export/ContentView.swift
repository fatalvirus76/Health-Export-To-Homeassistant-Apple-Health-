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
    /// false = appen kan inte läsa värdet ur HealthKit (saknar källa i iOS,
    /// kräver tredjepartsapp eller är en aggregering som saknar API).
    let isAvailable: Bool

    /// Datapunkter utan läsbar HealthKit-källa. De visas i urvalslistan men
    /// kan inte aktiveras och exporteras aldrig (tidigare skickades 0 till HA).
    static let unavailableMetricNames: Set<String> = [
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

    init(id: HKQuantityTypeIdentifier, name: String, displayName: String? = nil, unit: HKUnit, isCumulative: Bool, category: HealthCategory) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name.replacingOccurrences(of: "_", with: " ").capitalized
        self.unit = unit
        self.isCumulative = isCumulative
        self.category = category
        self.isAvailable = !Self.unavailableMetricNames.contains(name)
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

    // En delad formatterare i stället för en ny per anrop/rad (loggen renderas ofta).
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var fullString: String {
        "[\(Self.timeFormatter.string(from: time))] \(message)"
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
    case theme = "app_theme"
    case showLastValues = "show_last_values"
}

// MARK: - Themes

/// Ett färgtema. Lägg till ett nytt tema genom att lägga en `case` här och
/// fylla i `palette` – resten av appen läser bara paletten och behöver inte röras.
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case glass
    case dracula
    case synthwave
    case nord
    case midnight
    case sunset

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .glass: return "Glas"
        case .dracula: return "Dracula"
        case .synthwave: return "Synthwave"
        case .nord: return "Nord"
        case .midnight: return "Midnatt"
        case .sunset: return "Solnedgång"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .system:
            return ThemePalette(
                gradient: [
                    Color(uiColor: .systemBackground),
                    Color.accentColor.opacity(0.08),
                    Color(uiColor: .secondarySystemBackground)
                ],
                heroGradient: [
                    Color(red: 0.10, green: 0.27, blue: 0.95),
                    Color(red: 0.56, green: 0.22, blue: 0.92),
                    Color(red: 0.00, green: 0.72, blue: 0.86)
                ],
                heroShadow: Color.blue.opacity(0.22),
                accent: .accentColor,
                colorScheme: nil,
                rowMaterial: .regularMaterial
            )

        case .glass:
            return ThemePalette(
                gradient: [
                    Color(red: 0.06, green: 0.08, blue: 0.15),
                    Color(red: 0.12, green: 0.16, blue: 0.28),
                    Color(red: 0.04, green: 0.05, blue: 0.10)
                ],
                heroGradient: [
                    Color(red: 0.30, green: 0.51, blue: 0.95),
                    Color(red: 0.55, green: 0.36, blue: 0.92),
                    Color(red: 0.36, green: 0.86, blue: 0.95)
                ],
                heroShadow: Color(red: 0.36, green: 0.60, blue: 1.00).opacity(0.35),
                accent: Color(red: 0.62, green: 0.80, blue: 1.00),
                colorScheme: .dark,
                rowMaterial: .ultraThinMaterial
            )

        case .dracula:
            return ThemePalette(
                gradient: [
                    Color(red: 0.16, green: 0.16, blue: 0.21),
                    Color(red: 0.12, green: 0.12, blue: 0.16),
                    Color(red: 0.09, green: 0.09, blue: 0.13)
                ],
                heroGradient: [
                    Color(red: 0.74, green: 0.58, blue: 0.98),
                    Color(red: 1.00, green: 0.47, blue: 0.78),
                    Color(red: 0.55, green: 0.91, blue: 0.99)
                ],
                heroShadow: Color(red: 0.74, green: 0.58, blue: 0.98).opacity(0.30),
                accent: Color(red: 0.74, green: 0.58, blue: 0.98),
                colorScheme: .dark,
                rowMaterial: .ultraThinMaterial
            )

        case .synthwave:
            return ThemePalette(
                gradient: [
                    Color(red: 0.10, green: 0.04, blue: 0.18),
                    Color(red: 0.18, green: 0.04, blue: 0.31),
                    Color(red: 0.06, green: 0.04, blue: 0.10)
                ],
                heroGradient: [
                    Color(red: 1.00, green: 0.18, blue: 0.59),
                    Color(red: 0.48, green: 0.18, blue: 0.97),
                    Color(red: 0.00, green: 0.85, blue: 1.00)
                ],
                heroShadow: Color(red: 1.00, green: 0.18, blue: 0.59).opacity(0.35),
                accent: Color(red: 1.00, green: 0.18, blue: 0.59),
                colorScheme: .dark,
                rowMaterial: .ultraThinMaterial
            )

        case .nord:
            return ThemePalette(
                gradient: [
                    Color(red: 0.18, green: 0.20, blue: 0.25),
                    Color(red: 0.23, green: 0.26, blue: 0.32),
                    Color(red: 0.14, green: 0.16, blue: 0.20)
                ],
                heroGradient: [
                    Color(red: 0.37, green: 0.51, blue: 0.67),
                    Color(red: 0.53, green: 0.75, blue: 0.82),
                    Color(red: 0.64, green: 0.75, blue: 0.55)
                ],
                heroShadow: Color(red: 0.53, green: 0.75, blue: 0.82).opacity(0.28),
                accent: Color(red: 0.53, green: 0.75, blue: 0.82),
                colorScheme: .dark,
                rowMaterial: .ultraThinMaterial
            )

        case .midnight:
            return ThemePalette(
                gradient: [
                    Color(red: 0.04, green: 0.06, blue: 0.13),
                    Color(red: 0.07, green: 0.11, blue: 0.20),
                    Color(red: 0.03, green: 0.04, blue: 0.08)
                ],
                heroGradient: [
                    Color(red: 0.23, green: 0.05, blue: 0.64),
                    Color(red: 0.26, green: 0.38, blue: 0.93),
                    Color(red: 0.30, green: 0.79, blue: 0.94)
                ],
                heroShadow: Color(red: 0.26, green: 0.38, blue: 0.93).opacity(0.30),
                accent: Color(red: 0.30, green: 0.79, blue: 0.94),
                colorScheme: .dark,
                rowMaterial: .ultraThinMaterial
            )

        case .sunset:
            return ThemePalette(
                gradient: [
                    Color(red: 0.15, green: 0.07, blue: 0.20),
                    Color(red: 0.32, green: 0.10, blue: 0.26),
                    Color(red: 0.08, green: 0.05, blue: 0.12)
                ],
                heroGradient: [
                    Color(red: 1.00, green: 0.42, blue: 0.42),
                    Color(red: 1.00, green: 0.72, blue: 0.01),
                    Color(red: 1.00, green: 0.56, blue: 0.67)
                ],
                heroShadow: Color(red: 1.00, green: 0.55, blue: 0.40).opacity(0.30),
                accent: Color(red: 1.00, green: 0.72, blue: 0.01),
                colorScheme: .dark,
                rowMaterial: .ultraThinMaterial
            )
        }
    }
}

struct ThemePalette {
    let gradient: [Color]
    let heroGradient: [Color]
    let heroShadow: Color
    let accent: Color
    /// nil = följ systemets ljusa/mörka läge.
    let colorScheme: ColorScheme?
    /// Material för radkorten – tätare i ljust läge så korten syns mot ljus bakgrund.
    let rowMaterial: Material

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var heroBackground: LinearGradient {
        LinearGradient(colors: heroGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Håller valt tema och persisterar det. Delad instans så att alla vyer
/// (även ark/urvalslistan) byter utseende samtidigt.
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: AppStorageKey.theme.rawValue)
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: AppStorageKey.theme.rawValue) ?? ""
        theme = AppTheme(rawValue: stored) ?? .system
    }
}

/// Radbakgrund i listorna: glasmaterial + svag ton av temats accentfärg, så att
/// temat syns i varje rad och inte bara i gradienten bakom.
struct ThemeRowBackground: View {
    let palette: ThemePalette

    var body: some View {
        ZStack {
            Rectangle().fill(palette.rowMaterial)
            Rectangle().fill(palette.accent.opacity(0.12))
        }
        .overlay {
            Rectangle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        }
    }
}

/// Färgprov i temaväljaren.
private struct ThemeSwatch: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.palette.heroBackground)
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 1))

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                }
                .overlay {
                    Circle()
                        .stroke(isSelected ? theme.palette.accent : .clear, lineWidth: 3)
                        .frame(width: 60, height: 60)
                }

                Text(theme.displayName)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? theme.palette.accent : Color.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
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
    let palette: ThemePalette

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
                .fill(palette.heroBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: palette.heroShadow, radius: 22, x: 0, y: 14)
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
    var badge: String? = nil
    var accent: Color = .accentColor

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isEnabled ? accent : Color.secondary.opacity(0.28))
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body.weight(.medium))

                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }

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
    @AppStorage(AppStorageKey.showLastValues.rawValue) private var showLastValues: Bool = true
    
    // MARK: - State
    @StateObject private var healthManager = HealthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var logFilter: LogFilter = .all
    
    // MARK: - Computed Properties
    /// Datapunkter som faktiskt går att läsa ur HealthKit.
    private var availableMetricNames: Set<String> {
        Set(allHealthTypes.filter { $0.isAvailable }.map { $0.name })
    }

    private var localWarnings: [String] {
        enabledMetrics.intersection(availableMetricNames).isEmpty
            ? ["Inga datapunkter valda – välj minst en under Gemensamma Inställningar"]
            : []
    }

    private var enabledMetrics: Set<String> {
        get {
            guard let decoded = try? JSONDecoder().decode(Set<String>.self, from: enabledMetricsData) else {
                return availableMetricNames
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
        let palette = themeManager.theme.palette

        NavigationStack {
            Form {
                ModernHeroCard(
                    isAuthorized: healthManager.isAuthorized,
                    isExporting: healthManager.isExporting,
                    connectionStatus: healthManager.connectionStatus,
                    exportedMetricsCount: healthManager.exportedMetricsCount,
                    lastExportDate: healthManager.lastExportDate,
                    palette: palette
                )

                configurationWarningsSection
                healthKitStatusSection
                serverConfigurationSection
                commonSettingsSection
                automationSection
                appearanceSection
                
                if let lastExport = healthManager.lastExportDate {
                    exportStatusSection(lastExport: lastExport)
                }

                if showLastValues && !healthManager.lastSentValues.isEmpty {
                    recentValuesSection
                }
                
                exportActionsSection
                logsSection
            }
            .scrollContentBackground(.hidden)
            .listRowBackground(ThemeRowBackground(palette: palette))
            .background {
                palette.backgroundGradient
                    .ignoresSafeArea()
            }
            .navigationTitle("Health Export")
            .navigationBarTitleDisplayMode(.inline)
            .tint(palette.accent)
            .preferredColorScheme(palette.colorScheme)
            .animation(.easeInOut(duration: 0.25), value: themeManager.theme)
            .onAppear(perform: onAppear)
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private var configurationWarningsSection: some View {
        let warnings = healthManager.configurationWarnings + localWarnings
        if !warnings.isEmpty {
            Section {
                ForEach(warnings, id: \.self) { warning in
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
            .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
        
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
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
                    Text("\(enabledMetrics.intersection(availableMetricNames).count)/\(availableMetricNames.count)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if allHealthTypes.count > availableMetricNames.count {
                Text("\(allHealthTypes.count - availableMetricNames.count) datapunkter saknar läsbar källa i HealthKit och kan inte aktiveras.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Label("Gemensamma Inställningar", systemImage: "gearshape.fill")
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
    }

    private var appearanceSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeSwatch(theme: theme, isSelected: themeManager.theme == theme) {
                            themeManager.theme = theme
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))

            Toggle(isOn: $showLastValues) {
                Label("Visa senaste exporterade värden", systemImage: "list.number")
            }
        } header: {
            Label("Utseende", systemImage: "paintpalette.fill")
                .foregroundStyle(themeManager.theme.palette.accent)
        } footer: {
            Text("Temat sparas och slår igenom direkt i hela appen.")
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
    }
    
    private var recentValuesSection: some View {
        let values = healthManager.lastSentValues.sorted(by: { $0.key < $1.key })

        return Section {
            ForEach(Array(values.prefix(15)), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.2f", value))
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                        .foregroundColor(themeManager.theme.palette.accent)
                }
            }

            if values.count > 15 {
                Text("+ \(values.count - 15) värden till")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Label("Senaste Exporterade Värden (\(values.count))", systemImage: "list.number")
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
                    .fill(themeManager.theme.palette.accent.opacity(0.10))
            )
            .padding(.vertical, 4)
            
        } header: {
            Label("Manuell Körning", systemImage: "play.circle.fill")
                .foregroundStyle(themeManager.theme.palette.accent)
        }
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
                    .foregroundStyle(themeManager.theme.palette.accent)
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
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
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
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(enabledMetrics: Set<String>, onUpdate: @escaping (Set<String>) -> Void) {
        self.enabledMetrics = enabledMetrics
        self.onUpdate = onUpdate
        _localEnabledMetrics = State(initialValue: enabledMetrics)
    }
    
    var body: some View {
        // MARK: - MODIFIED
        List {
            if visibleMetricCount == 0 {
                Text("Inga träffar på ”\(searchText)”")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
            }

            ForEach(HealthCategory.allCases) { category in
                let metrics = visibleMetrics(category)
                if !metrics.isEmpty {
                    Section(header: categoryHeader(for: category)) {
                        ForEach(metrics, id: \.name) { config in
                            metricRow(config)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(ThemeRowBackground(palette: themeManager.theme.palette))
        .background {
            themeManager.theme.palette.backgroundGradient
                .ignoresSafeArea()
        }
        .searchable(text: $searchText, prompt: "Sök datapunkter")
        .navigationTitle("Välj datapunkter")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.theme.palette.accent)
        .preferredColorScheme(themeManager.theme.palette.colorScheme)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        localEnabledMetrics = Set(allHealthTypes.filter { $0.isAvailable }.map { $0.name })
                        onUpdate(localEnabledMetrics)
                    }) {
                        Label("Markera alla läsbara", systemImage: "checkmark.square.fill")
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
        let available = metricsFor(category).filter { $0.isAvailable }
        let enabledCount = available.filter { localEnabledMetrics.contains($0.name) }.count

        return HStack {
            Label(category.rawValue, systemImage: category.icon)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Spacer()
            Text("\(enabledCount)/\(available.count)")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
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
            .disabled(available.isEmpty)
        }
        .padding(.vertical, 4)
    }

    /// En rad per datapunkt: växlare för läsbara, gråmarkerad etikett för övriga.
    @ViewBuilder
    private func metricRow(_ config: HealthDataConfig) -> some View {
        if config.isAvailable {
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
                    isEnabled: localEnabledMetrics.contains(config.name),
                    accent: themeManager.theme.palette.accent
                )
            }
            .tint(themeManager.theme.palette.accent)
        } else {
            ModernMetricRow(
                title: config.displayName,
                subtitle: config.name,
                isEnabled: false,
                badge: "Saknar källa"
            )
            .opacity(0.5)
        }
    }
    
    private func metricsFor(_ category: HealthCategory) -> [HealthDataConfig] {
        allHealthTypes.filter { $0.category == category }
    }

    private func visibleMetrics(_ category: HealthCategory) -> [HealthDataConfig] {
        metricsFor(category).filter(matchesSearch)
    }

    private var visibleMetricCount: Int {
        allHealthTypes.filter(matchesSearch).count
    }
    
    private func matchesSearch(_ config: HealthDataConfig) -> Bool {
        searchText.isEmpty
        || config.displayName.localizedCaseInsensitiveContains(searchText)
        || config.name.localizedCaseInsensitiveContains(searchText)
    }
    
    private func categoryEnabled(_ category: HealthCategory) -> Bool {
        let available = metricsFor(category).filter { $0.isAvailable }
        guard !available.isEmpty else { return false }
        return available.allSatisfy { localEnabledMetrics.contains($0.name) }
    }
    
    private func toggleCategory(_ category: HealthCategory) {
        let available = metricsFor(category).filter { $0.isAvailable }
        let allEnabled = categoryEnabled(category)
        
        for metric in available {
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
    /// Datapunkter som har egen hämtningsväg (kategori-samples, workouts, m.m.)
    /// i stället för den vanliga quantity-queryn.
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
        "heart_rate_avg",
        "heart_rate_recovery"
    ]

    // MARK: - Export-skydd
    /// Ser till att bara en export körs åt gången (knapp + BGTask + observer).
    private var isExportInFlight = false
    /// Antal fel i rad per server – en server som strular hoppas över resten av körningen.
    private var serverFailureStreak: [UUID: Int] = [:]
    private var disabledServers: Set<UUID> = []
    private let maxConsecutiveServerFailures = 3
    
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
    
    /// Läser användarens val av datapunkter (enabled_metrics). Tomt/okänt → alla läsbara typer.
    static func loadEnabledMetricsFromDefaults() -> Set<String> {
        let available = Set(HealthDataConfiguration.shared.allHealthTypes.filter { $0.isAvailable }.map { $0.name })
        guard let data = UserDefaults.standard.data(forKey: AppStorageKey.enabledMetrics.rawValue),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data),
              !decoded.isEmpty else {
            return available
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

        // Bara en export åt gången (knapp + BGTask + HealthKit-observer kan krocka).
        guard !isExportInFlight else {
            if !isBackground { log("ℹ️ En export körs redan – hoppar över denna körning.") }
            return
        }
        isExportInFlight = true
        defer { isExportInFlight = false }

        serverFailureStreak.removeAll()
        disabledServers.removeAll()

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
            && $0.isAvailable
            && $0.category != .sleep
            && !specialMetricKeys.contains($0.name)
        }

        // Datapunkter som användaren kryssat men som saknar källa i HealthKit.
        let skippedUnavailable = enabledMetrics.subtracting(
            Set(currentConfig.allHealthTypes.filter { $0.isAvailable }.map { $0.name })
        )
        if !isBackground && !skippedUnavailable.isEmpty {
            log("ℹ️ \(skippedUnavailable.count) datapunkter saknar källa i HealthKit och hoppas över.")
        }

        let sleepKeys: Set<String> = [
            "sleep_total", "sleep_rem", "sleep_deep", "sleep_light",
            "sleep_awake", "sleep_in_bed", "sleep_efficiency"
        ]
        let workoutKeys: Set<String> = [
            "workouts_count_today", "workouts_minutes_today",
            "workouts_energy_today", "workouts_distance_today"
        ]
        let heartSummaryKeys: Set<String> = ["heart_rate_min", "heart_rate_max", "heart_rate_avg"]

        let hasSleepEnabled = !enabledMetrics.isDisjoint(with: sleepKeys)
        let hasWorkoutsEnabled = !enabledMetrics.isDisjoint(with: workoutKeys)
        let hasHeartSummaryEnabled = !enabledMetrics.isDisjoint(with: heartSummaryKeys)
        let hasMindfulEnabled = enabledMetrics.contains("mindful_minutes")
        let hasHandwashingEnabled = enabledMetrics.contains("handwashing_count")
        let hasStreakEnabled = enabledMetrics.contains("workout_streak")
        let hasWeeklyEnabled = enabledMetrics.contains("weekly_exercise_minutes")
        let hasRecoveryEnabled = enabledMetrics.contains("heart_rate_recovery")

        let totalSteps = standardMetrics.count
            + [hasSleepEnabled, hasMindfulEnabled, hasHandwashingEnabled, hasWorkoutsEnabled,
               hasHeartSummaryEnabled, hasStreakEnabled, hasWeeklyEnabled, hasRecoveryEnabled]
                .filter { $0 }.count

        let startedAt = Date()
        var completed: Double = 0
        var sentMetrics = 0
        var noDataMetrics = 0
        var failedMetrics = 0
        
        // 1. Standard HealthKit-data (dagssumma för kumulativa, senaste värdet för diskreta)
        for metricConfig in standardMetrics {
            if !isBackground {
                updateProgress(step: completed, of: totalSteps, metric: metricConfig.displayName)
            }

            do {
                guard let value = try await fetchQuantityData(
                    for: metricConfig.id,
                    unit: metricConfig.unit,
                    isCumulative: metricConfig.isCumulative,
                    lookbackDays: currentLookbackDays
                ) else {
                    noDataMetrics += 1
                    if !isBackground { log("➖ \(metricConfig.displayName): ingen data i HealthKit") }
                    completed += 1
                    continue
                }

                let okCount = await sendToAllServers(
                    servers: currentServers,
                    key: metricConfig.name,
                    value: value,
                    unit: metricConfig.unit.unitString,
                    friendlyName: metricConfig.displayName,
                    entityPrefix: currentEntityPrefix,
                    isBackground: isBackground
                )

                if okCount > 0 { sentMetrics += 1 } else { failedMetrics += 1 }
            } catch {
                failedMetrics += 1
                if !isBackground {
                    log("⚠️ \(metricConfig.displayName): \(error.localizedDescription)", isError: true)
                }
            }

            completed += 1
        }
        
        // 2. Sömn (kategori-samples → uträkning per natt)
        if hasSleepEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Sömn") }
            do {
                let sleepData = try await fetchSleepBreakdown()
                let hasData = sleepData.contains { $0.key != "sleep_efficiency" && $0.value > 0 }
                var anySuccess = false

                if hasData {
                    for (key, value) in sleepData where enabledMetrics.contains(key) {
                        let friendlyName = currentConfig.allHealthTypes.first(where: { $0.name == key })?.displayName ?? key.capitalized
                        let unit = key == "sleep_efficiency" ? "%" : "h"

                        let okCount = await sendToAllServers(
                            servers: currentServers,
                            key: key,
                            value: value,
                            unit: unit,
                            friendlyName: friendlyName,
                            entityPrefix: currentEntityPrefix,
                            isBackground: isBackground
                        )
                        anySuccess = anySuccess || okCount > 0
                    }
                } else {
                    noDataMetrics += 1
                    if !isBackground { log("➖ Sömn: inga sömnsamples senaste 36 h") }
                }

                if anySuccess { sentMetrics += 1 } else if hasData { failedMetrics += 1 }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Sömn: \(error.localizedDescription)", isError: true) }
            }
        }

        completed += 1
        
        // 3. Mindfulness
        if hasMindfulEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Mindfulness") }
            do {
                let mindful = try await fetchMindfulMinutes()
                let okCount = await sendToAllServers(
                    servers: currentServers,
                    key: "mindful_minutes",
                    value: mindful,
                    unit: "min",
                    friendlyName: "Mindfulness (minuter)",
                    entityPrefix: currentEntityPrefix,
                    isBackground: isBackground
                )
                if okCount > 0 { sentMetrics += 1 } else { failedMetrics += 1 }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Mindfulness: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1
        
        // 4. Handwashing
        if hasHandwashingEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Handtvätt") }
            do {
                let count = try await fetchHandwashingCountToday()
                let okCount = await sendToAllServers(
                    servers: currentServers,
                    key: "handwashing_count",
                    value: count,
                    unit: "st",
                    friendlyName: "Handtvätt (antal)",
                    entityPrefix: currentEntityPrefix,
                    isBackground: isBackground
                )
                if okCount > 0 { sentMetrics += 1 } else { failedMetrics += 1 }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Handtvätt: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1
        
        // 5. Workouts
        if hasWorkoutsEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Träning (Workouts)") }
            do {
                let summary = try await fetchWorkoutSummaryToday()
                
                let mapping: [(key: String, value: Double, unit: String, friendly: String)] = [
                    ("workouts_count_today", summary.count, "st", "Träningspass (antal idag)"),
                    ("workouts_minutes_today", summary.minutes, "min", "Träningstid (min idag)"),
                    ("workouts_energy_today", summary.kcal, "kcal", "Träning (kcal idag)"),
                    ("workouts_distance_today", summary.meters, "m", "Träning (meter idag)")
                ]
                var anySuccess = false
                for item in mapping where enabledMetrics.contains(item.key) {
                    let okCount = await sendToAllServers(
                        servers: currentServers,
                        key: item.key,
                        value: item.value,
                        unit: item.unit,
                        friendlyName: item.friendly,
                        entityPrefix: currentEntityPrefix,
                        isBackground: isBackground
                    )
                    anySuccess = anySuccess || okCount > 0
                }
                
                if anySuccess { sentMetrics += 1 } else { failedMetrics += 1 }
                if !isBackground {
                    log("✅ Workouts: \(Int(summary.count)) pass, \(Int(summary.minutes)) min, \(Int(summary.kcal)) kcal, \(Int(summary.meters)) m")
                }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Workouts: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1
        
        // 6. Pulsstatistik (min/max/snitt idag)
        if hasHeartSummaryEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Pulsstatistik") }
            do {
                let summary = try await fetchHeartRateSummaryToday()

                let mapping: [(key: String, value: Double, unit: String, friendly: String)] = [
                    ("heart_rate_min", summary.min, "count/min", "Min puls"),
                    ("heart_rate_max", summary.max, "count/min", "Max puls"),
                    ("heart_rate_avg", summary.average, "count/min", "Genomsnittlig puls")
                ]

                var anySuccess = false
                for item in mapping where enabledMetrics.contains(item.key) {
                    let okCount = await sendToAllServers(
                        servers: currentServers,
                        key: item.key,
                        value: item.value,
                        unit: item.unit,
                        friendlyName: item.friendly,
                        entityPrefix: currentEntityPrefix,
                        isBackground: isBackground
                    )
                    anySuccess = anySuccess || okCount > 0
                }

                if anySuccess { sentMetrics += 1 } else { failedMetrics += 1 }
                if !isBackground { log("✅ Pulsstatistik exporterad") }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Pulsstatistik: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1

        // 7. Puls-återhämtning (pulsfall 1–2 min efter dagens senaste pass)
        if hasRecoveryEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Puls-återhämtning") }
            do {
                if let recovery = try await fetchHeartRateRecoveryToday() {
                    let okCount = await sendToAllServers(
                        servers: currentServers,
                        key: "heart_rate_recovery",
                        value: recovery,
                        unit: "count/min",
                        friendlyName: "Puls-återhämtning",
                        entityPrefix: currentEntityPrefix,
                        isBackground: isBackground
                    )
                    if okCount > 0 { sentMetrics += 1 } else { failedMetrics += 1 }
                } else {
                    noDataMetrics += 1
                    if !isBackground { log("➖ Puls-återhämtning: inget avslutat pass (eller för lite pulldata) idag") }
                }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Puls-återhämtning: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1

        // 8. Tränings-serie
        if hasStreakEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Tränings-serie") }
            do {
                let streak = try await fetchWorkoutStreak(maxDays: 90)
                let okCount = await sendToAllServers(
                    servers: currentServers,
                    key: "workout_streak",
                    value: Double(streak),
                    unit: "d",
                    friendlyName: "Tränings-serie",
                    entityPrefix: currentEntityPrefix,
                    isBackground: isBackground
                )
                if okCount > 0 { sentMetrics += 1 } else { failedMetrics += 1 }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Tränings-serie: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1

        // 9. Veckovis träningstid (rullande 7 dagar)
        if hasWeeklyEnabled {
            if !isBackground { updateProgress(step: completed, of: totalSteps, metric: "Veckovis träning") }
            do {
                let minutes = try await fetchWeeklyExerciseMinutes()
                let okCount = await sendToAllServers(
                    servers: currentServers,
                    key: "weekly_exercise_minutes",
                    value: minutes,
                    unit: "min",
                    friendlyName: "Veckovis träning (min)",
                    entityPrefix: currentEntityPrefix,
                    isBackground: isBackground
                )
                if okCount > 0 { sentMetrics += 1 } else { failedMetrics += 1 }
            } catch {
                failedMetrics += 1
                if !isBackground { log("⚠️ Veckovis träning: \(error.localizedDescription)", isError: true) }
            }
        }
        completed += 1

        // Update status
        isExporting = false
        exportProgress = 1.0
        currentMetric = ""
        lastExportDate = Date()
        lastExportSuccess = sentMetrics > 0
        exportedMetricsCount = sentMetrics

        saveLastExportStatus(success: lastExportSuccess, count: sentMetrics)

        if !isBackground {
            let seconds = Date().timeIntervalSince(startedAt)
            log("🏁 Klart på \(String(format: "%.1f", seconds))s – \(sentMetrics) skickade, \(noDataMetrics) utan data, \(failedMetrics) misslyckade.")
        }
    }

    /// Uppdaterar progressraden (anropas i början av varje steg).
    private func updateProgress(step: Double, of total: Int, metric: String) {
        currentMetric = metric
        exportProgress = total > 0 ? min(1.0, step / Double(total)) : 0
    }

    /// Skickar ett värde till alla aktiva servrar. Servrar som failar
    /// `maxConsecutiveServerFailures` gånger i rad hoppas över resten av körningen
    /// (undviker hundratals felrader när en server ligger nere).
    /// - Returns: antal servrar som tog emot värdet.
    private func sendToAllServers(
        servers: [HAServerConfig],
        key: String,
        value: Double,
        unit: String,
        friendlyName: String,
        entityPrefix: String,
        isBackground: Bool
    ) async -> Int {
        let entityID = sanitizeEntityID(key, prefix: entityPrefix)
        var okCount = 0
        var failureText: String?

        for server in servers where !disabledServers.contains(server.id) {
            do {
                try await sendToHomeAssistant(
                    server: server,
                    entityID: entityID,
                    state: value,
                    unit: unit,
                    friendlyName: friendlyName,
                    maxRetries: 3
                )
                okCount += 1
                serverFailureStreak[server.id] = 0
            } catch {
                failureText = "\(server.name): \(error.localizedDescription)"
                let streak = (serverFailureStreak[server.id] ?? 0) + 1
                serverFailureStreak[server.id] = streak

                if streak >= maxConsecutiveServerFailures {
                    disabledServers.insert(server.id)
                    log("⛔️ \(server.name) hoppas över resten av körningen efter \(streak) fel i rad: \(error.localizedDescription)", isError: true)
                }
            }
        }

        if okCount > 0 {
            lastSentValues[friendlyName] = value
            if !isBackground { log("✅ \(friendlyName): \(formatted(value)) \(unit)") }
        } else if let failureText {
            log("❌ \(friendlyName): \(failureText)", isError: true)
        }

        return okCount
    }

    /// Kompakt talformat: heltal utan decimaler, annars två decimaler.
    private func formatted(_ value: Double) -> String {
        abs(value - value.rounded()) < 0.005 ? String(format: "%.0f", value) : String(format: "%.2f", value)
    }
    
    // MARK: - HealthKit Fetchers
    
    /// - Returns: värdet, eller nil när datapunkten saknar samples/enheten inte
    ///   stämmer (då skickas inget till HA – tidigare skrevs 0 och förstörde historiken).
    private func fetchQuantityData(
        for typeIdentifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        isCumulative: Bool,
        lookbackDays: Int
    ) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            throw HealthExportError.healthKitUnauthorized
        }
        
        // Kumulativ datapunkt mot en diskret HealthKit-typ = fel mappning, inte 0.
        if isCumulative && type.aggregationStyle != .cumulative {
            return nil
        }
        
        let now = Date()
        
        // MARK: - MODIFIED
        let fallbackStartDate = Calendar.current.startOfDay(for: now)
        let calculatedStartDate = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now)

        let startDate = isCumulative
            ? fallbackStartDate
            : calculatedStartDate ?? fallbackStartDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        if isCumulative {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // Ingen sample ännu idag = legitim nolla för en dagssumma.
                    guard let quantity = result?.sumQuantity() else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    
                    guard quantity.is(compatibleWith: unit) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    continuation.resume(returning: quantity.doubleValue(for: unit))
                }
                healthStore.execute(query)
            }
        } else {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
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
                    
                    guard let sample = samples?.first as? HKQuantitySample,
                          sample.quantity.is(compatibleWith: unit) else {
                        continuation.resume(returning: nil)
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
    
    // MARK: - ADDED
    /// Puls-återhämtning: snittpuls under sista minuten av dagens senaste
    /// träningspass minus snittpulsen 1–2 min efter passet (slag/min).
    /// Returnerar nil när pass eller pulldata saknas (skickas då inte alls).
    private func fetchHeartRateRecoveryToday() async throws -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            healthStore.execute(query)
        }

        guard let workout = workouts.first else { return nil }

        // Passet måste ha hunnit få 1–2 min efterdata innan vi kan mäta fallet.
        let afterStart = workout.endDate.addingTimeInterval(60)
        let afterEnd = workout.endDate.addingTimeInterval(120)
        guard afterEnd <= now else { return nil }

        let duringStart = max(workout.endDate.addingTimeInterval(-60), workout.startDate)
        guard let during = try await averageHeartRate(of: hrType, from: duringStart, to: workout.endDate),
              let after = try await averageHeartRate(of: hrType, from: afterStart, to: afterEnd) else {
            return nil
        }

        return max(0, during - after)
    }

    /// Snittpuls (slag/min) i intervallet, nil om inga samples finns.
    private func averageHeartRate(of type: HKQuantityType, from start: Date, to end: Date) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let unit = HKUnit.count().unitDivided(by: .minute())

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantity = result?.averageQuantity(), quantity.is(compatibleWith: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: quantity.doubleValue(for: unit))
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

                // Klientfel (401/403/404/…) går inte över av sig själva – försök inte igen.
                if case HealthExportError.invalidResponse(let code) = error,
                   (400..<500).contains(code),
                   code != 429 {
                    throw error
                }

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
