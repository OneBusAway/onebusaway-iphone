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

    public let todaySummary: String
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
}

@objc(OBACurrentForecast)
public class CurrentForecast: NSObject, Codable {
    public let icon: String
    public let precipPerHour: Double
    public let precipProbability: Double
    public let summary: String
    public let temperature: Double
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
}

extension WeatherForecast: ListDiffable {
    public func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let other = object as? WeatherForecast else {
            return false
        }

        return
            other.latitude == latitude &&
            other.longitude == longitude &&
            other.regionIdentifier == regionIdentifier &&
            other.regionName == regionName &&
            other.forecastRetrievedAt == forecastRetrievedAt &&
            other.units == units &&
            other.todaySummary == todaySummary &&
            other.currentForecast == currentForecast
    }
}
