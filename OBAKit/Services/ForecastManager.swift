//
//  ForecastManager.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 9/15/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit

@objc(OBAForecastManager)
public class ForecastManager: NSObject {
    private let application: OBAApplication

    @objc
    public private(set) var weatherForecast: WeatherForecast? {
        didSet {
            guard let forecast = weatherForecast else {
                return
            }

            application.userDefaults.set(WeatherForecast.encode(forecast), forKey: OBAForecastDataDefaultsKey)
            NotificationCenter.default.post(name: NSNotification.Name.OBAForecastUpdated, object: self)
        }
    }
    private var timer: Timer?
    private var promiseWrapper: PromiseWrapper?
    private var lastUpdated: Date = Date.distantPast {
        didSet {
            application.userDefaults.set(lastUpdated, forKey: OBAForecastUpdatedAtDefaultsKey)
        }
    }
    private let updateInterval: TimeInterval = 900 // 15 minutes in seconds.
    private let acceptableForecastStaleness: TimeInterval = 3600 // 1 hour in seconds.

    @objc
    init(application: OBAApplication) {
        self.application = application

        if let serializedForecast = application.userDefaults.object(forKey: OBAForecastDataDefaultsKey) as? Data,
           let forecast = WeatherForecast.decode(serializedForecast),
           abs(forecast.forecastRetrievedAt.timeIntervalSinceNow) < acceptableForecastStaleness {
            self.weatherForecast = forecast
        }

        lastUpdated = application.userDefaults.object(forKey: OBAForecastUpdatedAtDefaultsKey) as? Date ?? Date.distantPast

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillBecomeActive(_:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)

        if dueForUpdate {
            loadForecast()
        }
    }

    @objc private func loadForecast() {
        guard let region = application.modelDao.currentRegion else {
            return
        }

        promiseWrapper?.cancel()

        timer?.invalidate()
        timer = nil

        let loc = application.locationManager.currentLocation
        let wrapper = application.modelService.requestWeather(in: region, location: loc)
        wrapper.promise.then { [weak self] networkResponse -> Void in
            // swiftlint:disable force_cast
            let forecast = networkResponse.object as! WeatherForecast
            // swiftlint:enable force_cast
            self?.weatherForecast = forecast
            self?.lastUpdated = Date()
        }.catch { error in
            DDLogError("Unable to retrieve forecast: \(error)")
        }.always { [weak self] in
            self?.createTimer()
        }

        promiseWrapper = wrapper
    }

    // MARK: - Timer

    private func createTimer() {
        timer?.invalidate()
        timer = nil
        timer = Timer(timeInterval: updateInterval, target: self, selector: #selector(loadForecast), userInfo: nil, repeats: true)
    }

    private var dueForUpdate: Bool {
        return
            weatherForecast == nil ||
            abs(lastUpdated.timeIntervalSinceNow) > updateInterval
    }

    // MARK: - Notifications

    @objc private func applicationWillResignActive(_ note: Notification) {
        timer?.invalidate()
        timer = nil
        promiseWrapper?.cancel()
    }

    @objc private func applicationWillBecomeActive(_ note: Notification) {
        createTimer()

        if let weatherForecast = weatherForecast,
           abs(weatherForecast.forecastRetrievedAt.timeIntervalSinceNow) >= acceptableForecastStaleness {
            self.weatherForecast = nil
        }

        if dueForUpdate {
            loadForecast()
        }
    }
}
