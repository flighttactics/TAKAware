//
//  COTData+Extension.swift
//  TAKAware
//
//  Created by Cory Foy on 1/4/25.
//

import Foundation

extension COTData {
    public override func didSave() {
        super.didSave()
        if isDeleted {
            NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_COT_REMOVED), object: nil)
        } else {
            NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_COT_UPDATED), object: nil)
        }
    }
}
