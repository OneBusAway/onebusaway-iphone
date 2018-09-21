//
//  ButtonSectionController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/15/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit
import SnapKit
import OBAKit

class ButtonSectionCell: SelfSizingCollectionCell {

    private let kDebugColors = false

    fileprivate let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.tintColor = OBATheme.obaDarkGreen

        return imageView
    }()

    fileprivate let label: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(.required, for: .vertical)
        label.font = OBATheme.boldFootnoteFont
        label.textColor = OBATheme.obaDarkGreen

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stack = UIStackView.oba_horizontalStack(withArrangedSubviews: [imageView, label])
        stack.spacing = OBATheme.compactPadding
        let stackWrapper = stack.oba_embedInWrapper()
        contentView.addSubview(stackWrapper)

        imageView.snp.makeConstraints { (make) in
            make.height.equalTo(label)
            make.width.equalTo(imageView.snp.height)
        }

        stackWrapper.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: OBATheme.defaultMargin, left: 0, bottom: 0, right: 0))
        }

        if kDebugColors {
            imageView.backgroundColor = .red
            stackWrapper.backgroundColor = .magenta
            label.backgroundColor = .green
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        label.text = nil
        imageView.image = nil
    }
}

class ButtonSection: NSObject, ListDiffable {
    fileprivate let title: String
    fileprivate let image: UIImage?
    fileprivate let action: (_ cell: UICollectionViewCell) -> Void

    init(title: String, image: UIImage?, action: @escaping (_ cell: UICollectionViewCell) -> Void) {
        self.title = title
        self.image = image
        self.action = action
    }

    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? ButtonSection else {
            return false
        }

        return self == object
    }
}

class ButtonSectionController: ListSectionController {
    var data: ButtonSection?

    override init() {
        super.init()
        inset = .zero
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 55)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard
            let ctx = collectionContext,
            let cell = ctx.dequeueReusableCell(of: ButtonSectionCell.self, for: self, at: index) as? ButtonSectionCell
            else {
                fatalError()
        }

        cell.label.text = data?.title
        cell.imageView.image = data?.image

        return cell
    }

    override func didSelectItem(at index: Int) {
        guard let cell = collectionContext?.cellForItem(at: index, sectionController: self),
              let data = data else {
            return
        }

        data.action(cell)
    }

    override func didUpdate(to object: Any) {
        precondition(object is ButtonSection)
        data = object as? ButtonSection
    }
}
