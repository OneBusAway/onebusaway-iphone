//
//  ServiceAlertDetailsViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 11/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit
import SafariServices

class ServiceAlertDetailsViewController: UIViewController, UITextViewDelegate {
    var serviceAlert: OBASituationV2
    var textView: UITextView!

    init(serviceAlert: OBASituationV2) {
        self.serviceAlert = serviceAlert
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        self.serviceAlert = OBASituationV2.init()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.serviceAlert.summary

        self.textView = UITextView.init(frame: self.view.bounds)
        self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.textView.dataDetectorTypes = .all
        self.textView.isEditable = false
        self.textView.font = OBATheme.bodyFont()
        self.textView.delegate = self

        self.textView.text = self.serviceAlert.formattedDetails

        self.view.addSubview(self.textView)

        var toolbarItems: [UIBarButtonItem] = []

        let shareButton = UIBarButtonItem.init(barButtonSystemItem: .action, target: self, action: #selector(shareAlert))
        toolbarItems.append(shareButton)

        if self.serviceAlert.diversionPath != nil {
            toolbarItems.append(UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            let diversionButton = UIBarButtonItem.init(title: NSLocalizedString("View Reroute", comment: "Toolbar button item on the Service Alert Details controller"), style: .plain, target: self, action: #selector(viewReroute))
            toolbarItems.append(diversionButton)
        }

        self.toolbarItems = toolbarItems
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    // MARK: - Toolbar Actions

    func shareAlert() {
        let activityController = UIActivityViewController.init(activityItems: [self.serviceAlert.formattedDetails], applicationActivities: nil)
        activityController.completionWithItemsHandler = { type, completed, returnedItems, error in
            activityController.dismiss(animated: true, completion: nil)
        }

        self.present(activityController, animated: true, completion: nil)
    }

    func viewReroute() {
        let diversionController = OBADiversionViewController.load(fromNibWithappDelegate: UIApplication.shared.delegate as! OBAApplicationDelegate)
        diversionController.diversionPath = (self.serviceAlert.diversionPath)!
        self.navigationController?.pushViewController(diversionController, animated: true)
    }

    // MARK: - UITextViewDelegate

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let safari = SFSafariViewController.init(url: URL)
        self.present(safari, animated: true, completion: nil)

        return false
    }
}
