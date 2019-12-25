//
//  DepartureTimeBadge.swift
//  OBAKit
//
//  Created by Alan Chu on 12/22/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit

/// A rounded time badge representing the provided upcoming departure time and deviation status.
public class OBADepartureTimeBadge: UILabel {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 13.0, *) {
            self.textColor = .systemGray6
        } else {
            self.textColor = .white
        }
        
        self.textAlignment = .center
        self.font = OBATheme.boldFootnoteFont
        
        self.backgroundColor = .clear
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 8
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - parameter departure: If `departure` is nil, then this view will be hidden. A non-nil value will unhide this view.
    public func apply(upcomingDeparture departure: OBAArrivalAndDepartureV2?) {
        if let departure = departure {
            self.accessibilityLabel = OBADateHelpers.formatAccessibilityLabelMinutes(until: departure.bestArrivalDepartureDate)
            self.text = OBADateHelpers.formatMinutes(until: departure.bestArrivalDepartureDate)
            self.backgroundColor = OBADepartureCellHelpers.color(for: departure.departureStatus)

            self.isHidden = false
        } else {
            self.accessibilityLabel = nil
            self.isHidden = true
        }
    }
}
