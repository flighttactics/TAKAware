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
        NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_COT_UPDATED), object: nil)
    }
}
