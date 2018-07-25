//
//  StopAnnotationView.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 7/22/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit

@objc(OBAStopAnnotationView)
class StopAnnotationView: MKAnnotationView {

    // MARK: - View Properties
    private let myImageView: UIImageView = {
        let img = UIImageView(frame: .zero)
        img.contentMode = .scaleAspectFit
        return img
    }()

    // MARK: - Initialization

    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        addSubview(myImageView)

        let size = 54
        bounds = CGRect(x: 0, y: 0, width: size, height: size)

        canShowCallout = false
    }

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()

        myImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        myImageView.frame = bounds
    }
}

// MARK: - Data Configuration
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
            stopImage = OBAImageHelpers.colorizeImage(OBAStopIconFactory.getIconForStop(stop), with: OBATheme.mapBookmarkTintColor)
        }
        else {
            stopImage = UIImage(named: "Bookmarks")!
        }

        myImageView.image = stopImage
    }

    private func configure(stop: OBAStopV2) {
        let image = OBAStopIconFactory.getIconForStop(stop)
        myImageView.image = image
    }

    private func configureNop() {
        // nop?
    }
}

// MARK: - Selection State
extension StopAnnotationView {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
