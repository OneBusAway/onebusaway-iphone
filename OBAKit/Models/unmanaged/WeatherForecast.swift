//
//  WeatherForecast.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 7/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation
import IGListKit

@objc(OBAWeatherForecast)
public class WeatherForecast: NSObject, Codable {

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()

        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let codingPath: [String] = container.codingPath.compactMap({ $0.stringValue })

            // TODO: I bet I can improve these comparisons.
            if codingPath == ["retrieved_at"] {
                let dateString = try container.decode(String.self)

                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            else if codingPath == ["current_forecast", "time"] {
                let dateInt = try container.decode(Int.self)
                return Date(timeIntervalSince1970: Double(dateInt))
            }

            // I don't think this is the right error :-\
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "The value had an unexpected key path. Unable to decode.")
        }

        return decoder
    }()

    public let latitude: Double
    public let longitude: Double
    public let regionIdentifier: Int
    public let regionName: String
    public let forecastRetrievedAt: Date
    public let units: String

    @objc
    public let todaySummary: String

    @objc
    public let currentForecast: CurrentForecast

    override init() { fatalError() }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case regionIdentifier = "region_identifier"
        case regionName = "region_name"
        case forecastRetrievedAt = "retrieved_at"
        case units
        case todaySummary = "today_summary"
        case currentForecast = "current_forecast"
    }

    // MARK: - Coding

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(regionIdentifier, forKey: .regionIdentifier)
        try container.encode(regionName, forKey: .regionName)
        try container.encode(forecastRetrievedAt, forKey: .forecastRetrievedAt)
        try container.encode(units, forKey: .units)
        try container.encode(todaySummary, forKey: .todaySummary)
        try container.encode(currentForecast, forKey: .currentForecast)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        regionIdentifier = try container.decode(Int.self, forKey: .regionIdentifier)
        regionName = try container.decode(String.self, forKey: .regionName)
        forecastRetrievedAt = try container.decode(Date.self, forKey: .forecastRetrievedAt)
        units = try container.decode(String.self, forKey: .units)
        todaySummary = try container.decode(String.self, forKey: .todaySummary)
        currentForecast = try container.decode(CurrentForecast.self, forKey: .currentForecast)
    }

    // MARK: - Serialization

    public static func encode(_ forecast: WeatherForecast) -> Data? {
        do {
            let data = try PropertyListEncoder().encode(forecast)
            return data
        }
        catch {
            let err = error
            print("Error: \(err)")
        }

        return nil
    }

    public static func decode(_ data: Data) -> WeatherForecast? {
        do {
            let forecast = try PropertyListDecoder().decode(WeatherForecast.self, from: data)
            return forecast
        }
        catch {
            let err = error
            print("Error: \(err)")
        }

        return nil
    }
}

@objc(OBACurrentForecast)
public class CurrentForecast: NSObject, Codable {
    public let icon: String
    public let precipPerHour: Double
    public let precipProbability: Double
    public let summary: String
    @objc public let temperature: Double
    public let temperatureFeelsLike: Double
    public let date: Date
    public let windSpeed: Double

    enum CodingKeys: String, CodingKey {
        case icon
        case precipPerHour = "precip_per_hour"
        case precipProbability = "precip_probability"
        case summary
        case temperature
        case temperatureFeelsLike = "temperature_feels_like"
        case date = "time"
        case windSpeed = "wind_speed"
    }

    override init() { fatalError() }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CurrentForecast else {
            return false
        }

        return
            other.icon == icon &&
            other.precipPerHour == precipPerHour &&
            other.precipProbability == precipProbability &&
            other.summary == summary &&
            other.temperature == temperature &&
            other.temperatureFeelsLike == temperatureFeelsLike &&
            other.date == date &&
            other.windSpeed == windSpeed
    }

    // MARK: - Coding

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(icon, forKey: .icon)
        try container.encode(precipPerHour, forKey: .precipPerHour)
        try container.encode(precipProbability, forKey: .precipProbability)
        try container.encode(summary, forKey: .summary)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(temperatureFeelsLike, forKey: .temperatureFeelsLike)
        try container.encode(date, forKey: .date)
        try container.encode(windSpeed, forKey: .windSpeed)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        icon = try container.decode(String.self, forKey: .icon)
        precipPerHour = try container.decode(Double.self, forKey: .precipPerHour)
        precipProbability = try container.decode(Double.self, forKey: .precipProbability)
        summary = try container.decode(String.self, forKey: .summary)
        temperature = try container.decode(Double.self, forKey: .temperature)
        temperatureFeelsLike = try container.decode(Double.self, forKey: .temperatureFeelsLike)
        date = try container.decode(Date.self, forKey: .date)
        windSpeed = try container.decode(Double.self, forKey: .windSpeed)
    }
}
