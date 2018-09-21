//
//  StopAnnotationView.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 7/22/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

@objc(OBAStopAnnotationView)
class StopAnnotationView: MKAnnotationView {

    /// Scale and add a drop shadow to the annotation view when it
    /// is tapped to depict that it has been selected.
    @objc var showsSelectionState = false

    // MARK: - View Properties
    private let stopImageView: UIImageView = {
        let img = UIImageView(frame: .zero)
        img.contentMode = .scaleAspectFit
        img.layer.shadowColor = UIColor.black.cgColor
        img.layer.shadowRadius = 4.0
        img.layer.shadowOffset = .zero
        return img
    }()

    // MARK: - Initialization

    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        canShowCallout = true

        addSubview(stopImageView)

        bounds = CGRect(x: 0, y: 0, width: OBADefaultAnnotationSize, height: OBADefaultAnnotationSize)
        frame = frame.integral
    }

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()

        stopImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        stopImageView.frame = bounds
    }
}

// MARK: - Data Loading
extension StopAnnotationView {
    override var annotation: MKAnnotation? {
        didSet {
            configureUI()
        }
    }

    private func configureUI() {
        // swiftlint:disable force_cast
        switch annotation {
        case is OBABookmarkV2: configure(bookmark: annotation as! OBABookmarkV2)
        case is OBAStopV2: configure(stop: annotation as! OBAStopV2)
        default:
            configureNop()
        }
        // swiftlint:enable force_cast
    }

    private func configure(bookmark: OBABookmarkV2) {
        var stopImage: UIImage
        if let stop = bookmark.stop {
            let icon = OBAStopIconFactory.getIconForStop(stop, stroke: strokeColor)
            stopImage = OBAImageHelpers.colorizeImage(icon, with: OBATheme.mapBookmarkTintColor)
        }
        else {
            stopImage = UIImage(named: "Bookmarks")!
        }

        stopImageView.image = stopImage

        setNeedsLayout()
    }

    private func configure(stop: OBAStopV2) {
        let image = OBAStopIconFactory.getIconForStop(stop, stroke: strokeColor)
        stopImageView.image = image
    }

    private func configureNop() {
        // nop?
    }
}

// MARK: - Visual Treatment
extension StopAnnotationView {
    private var strokeColor: UIColor {
        if isSelected {
            return OBATheme.obaDarkGreen
        }
        else {
            return UIColor.black
        }
    }
}

// MARK: - Selection State
extension StopAnnotationView {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if showsSelectionState {
            OBAAnimation.perform(animated: animated) {
                self.configureUI()
                self.updateShadow()
                self.updateTransform()
            }
        }
    }

    private func updateShadow() {
        let opacity: Float = isSelected ? 0.3 : 0.0
        self.stopImageView.layer.shadowOpacity = opacity
    }

    private func updateTransform() {
        transform = isSelected ? CGAffineTransform.init(scaleX: 1.1, y: 1.1) : .identity
    }
}
