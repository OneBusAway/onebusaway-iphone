//
//  CreditsViewController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/19/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import OBAKit
import UIKit

class CreditRow: OBATableRow {
    fileprivate let licenseText: String
    fileprivate let isHTML: Bool

    init(title: String, licenseText: String, isHTML: Bool, action: @escaping OBARowAction) {
        self.licenseText = licenseText
        self.isHTML = isHTML

        super.init(title: title, action: action)
    }

    init(title: String, data: Any, action: @escaping OBARowAction) {
        if let data = data as? [String: Any] {
            licenseText = data["license"] as? String ?? ""
            isHTML = data["isHTML"] as? Bool ?? false
        }
        else if let text = data as? String {
            licenseText = text
            isHTML = false
        }
        else {
            licenseText = ""
            isHTML = false
        }

        super.init(title: title, action: action)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return CreditRow(title: title, licenseText: licenseText, isHTML: isHTML, action: action)
    }
}

@objc(OBACreditsViewController)
class CreditsViewController: OBAStaticTableViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)

        title = NSLocalizedString("msg_credits", comment: "Title of credits view controller")

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard
            let path = Bundle.main.path(forResource: "credits", ofType: "plist"),
            let credits = NSDictionary(contentsOfFile: path) else {
            return
        }

        let action: OBARowAction = { row in
            guard let row = row as? CreditRow else {
                return
            }
            let creditViewer = CreditViewerController(credit: row)
            self.navigationController?.pushViewController(creditViewer, animated: true)
        }

        var rows = [OBABaseRow]()

        for (key, value) in credits {
            guard let key = key as? String else { continue }
            let credit = CreditRow(title: key, data: value, action: action)
            rows.append(credit)
        }

        sections = [OBATableSection(title: nil, rows: rows)]
    }
}

class CreditViewerController: UIViewController {
    private let credit: CreditRow
    private let webView = UIWebView()

    init(credit: CreditRow) {
        self.credit = credit
        super.init(nibName: nil, bundle: nil)

        title = credit.title
    }

    override func viewDidLoad() {
        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        webView.loadHTMLString(buildHTML(), baseURL: nil)
    }

    private func buildHTML() -> String {
        var template = ""

        if let path = Bundle.main.path(forResource: "credits", ofType: "html"),
           let tpl = try? String(contentsOfFile: path) {
            template = tpl
        }

        let mungedCredits: String
        if credit.isHTML {
            mungedCredits = credit.licenseText
        }
        else {
            mungedCredits = "<code>\(credit.licenseText.replacingOccurrences(of: "\n", with: "<br>"))</code>"
        }

        return template.replacingOccurrences(of: "{{{credits}}}", with: mungedCredits)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
