//
//  KMLFile+Extension.swift
//  TAKAware
//
//  Created by Cory Foy on 12/22/24.
//

import Foundation

extension KMLFile {
    public override func didSave() {
        super.didSave()
        NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_KML_FILE_UPDATED), object: nil)
    }
}
