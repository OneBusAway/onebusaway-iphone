//
//  OBAFloatingButton.swift
//  org.onebusaway.iphone
//
//  Created by Alan Chu on 1/6/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit

@IBDesignable
open class OBAFloatingButton: UIButton {
    @IBInspectable var normalBackgroundColor = UIColor(red:0.97, green:0.96, blue:0.96, alpha:1.0)
    @IBInspectable var pressedBackgroundColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.0)
    @IBInspectable var selectedImage: UIImage?
    @IBInspectable var normalImage: UIImage? {
        didSet {
            iconImageView.image = normalImage
        }
    }
    
    private var iconImageView: UIImageView!
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: 48, height: 48)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    // Configures the view
    private func configure() {
        // super.center doesn't seem to work, so calculate our own
        let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        iconImageView = UIImageView(frame: CGRect(origin: center, size: CGSize(width: 24, height: 24)))
        iconImageView.center = center
        addSubview(iconImageView)

        layer.backgroundColor = normalBackgroundColor.cgColor
        layer.cornerRadius = 5
        
        // Dope shadow
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 2
        layer.shadowOpacity = 0.25
    }
    
    /// This method behaves a bit unexpected, you will provide a UIControlState, but only as a reference.
    /// It will **not** mutate any part of the superclass. See parameter description.
    /// - parameter state:  State to change this button to. `.selected` will make `iconImageView` use `selectedImage`.
    ///                     Otherwise, `iconImageView` will default to `normalImage`
    open func changeState(to state: UIControlState) {
        iconImageView.image = state == .selected ? selectedImage : normalImage
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        layer.backgroundColor = pressedBackgroundColor.cgColor
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        layer.backgroundColor = normalBackgroundColor.cgColor
    }
}
