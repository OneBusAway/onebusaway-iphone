//
//  ForecastCell.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/22/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import OBAKit
import UIKit
import SnapKit

class ForecastCell: SelfSizingCollectionCell {

    let foregroundColor = UIColor.darkText

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        let topStack = UIStackView.init(arrangedSubviews: [weatherImageView, temperatureLabel, UIView()])
        topStack.axis = .horizontal
        let topStackWrapper = topStack.oba_embedInWrapper()

        let labelStack = UIStackView.init(arrangedSubviews: [topStackWrapper, summaryLabel])
        labelStack.axis = .vertical

        let outerWrapper = labelStack.oba_embedInWrapper()
        contentView.addSubview(outerWrapper)
        outerWrapper.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview().inset(UIEdgeInsetsMake(0, 0, OBATheme.compactPadding, OBATheme.defaultPadding))
        }

        weatherImageView.tintColor = foregroundColor
        temperatureLabel.textColor = foregroundColor
        summaryLabel.textColor = foregroundColor

        outerWrapper.backgroundColor = OBATheme.mapTableBackgroundColor.withAlphaComponent(0.8)
        outerWrapper.layer.cornerRadius = OBATheme.compactPadding

        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Data Loading

    var forecast: WeatherForecast? {
        didSet {
            guard let forecast = forecast else {
                return
            }
            let truncatedTemperature = Int(forecast.currentTemperature)
            temperatureLabel.text = "\(truncatedTemperature)º"
            summaryLabel.text = forecast.currentSummary
            weatherImageView.image = UIImage(named: forecast.currentSummaryIconName)
        }
    }

    // MARK: - Properties
    fileprivate static let titleFont = OBATheme.boldBodyFont!
    fileprivate static let summaryFont = OBATheme.footnoteFont!

    fileprivate let temperatureLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.font = ForecastCell.titleFont
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()

    fileprivate let summaryLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.font = ForecastCell.summaryFont
        return label
    }()

    fileprivate let weatherImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return imageView
    }()
}
