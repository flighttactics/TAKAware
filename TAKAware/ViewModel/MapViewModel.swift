//
//  MapViewModel.swift
//  TAKAware
//
//  Created by Cory Foy on 11/16/24.
//

import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var isAcquiringBloodhoundTarget: Bool = false
    @Published var isDetailViewOpen: Bool = false
    @Published var isVideoPlayerOpen: Bool = false
    @Published var isDeconflictionViewOpen: Bool = false
    @Published var currentSelectedAnnotation: MapPointAnnotation? = nil
    @Published var conflictedItems: [MapPointAnnotation] = []
    var annotationSelectedCallback: (MapPointAnnotation) -> Void = { (_) in }
    var bloodhoundDeselectedCallback: () -> Void = { () in }
    var annotationUpdatedCallback: (MapPointAnnotation) -> Void = { (_) in }
    
    func annotationUpdated(_ annotation: MapPointAnnotation) {
        annotationUpdatedCallback(annotation)
    }
    
    func didSelectAnnotation(_ annotation: MapPointAnnotation) {
        currentSelectedAnnotation = annotation
        if isDeconflictionViewOpen {
            isDeconflictionViewOpen = false
        }
        annotationSelectedCallback(annotation)
    }
    
    func didDeleteAnnotation(_ annotation: MapPointAnnotation) {
        conflictedItems.removeAll(where: {$0.id == annotation.id})
        if(conflictedItems.isEmpty && isDeconflictionViewOpen) {
            isDeconflictionViewOpen = false
        }
        currentSelectedAnnotation = nil
        DispatchQueue.main.async {
            DataController.shared.deleteCot(cotId: annotation.id)
        }        
    }
    
    func toggleBloodhound() {
        if(isAcquiringBloodhoundTarget) {
            bloodhoundDeselectedCallback()
        }
    }
}
