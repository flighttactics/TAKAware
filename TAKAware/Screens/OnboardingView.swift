//
//  OnboardingView.swift
//  TAKTracker
//
//  Created by Cory Foy on 9/26/23.
//

import Foundation
import SwiftUI

enum OnboardingStep {
    case AskPermissions
    case SetUserInformation
    case ConnectToServer
    case Finished
}

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var locationManager: LocationManager
    var takManager: TAKManager
    
    @State var currentStep: OnboardingStep = OnboardingStep.AskPermissions
    @State var hasAskedPermissions = false
    @State var hasTriedToConnect = false
    @State var isProcessingDataPackage = false
    @State var buttonNavText = "Next"
    
    var permissionsButtonText: String {
        switch(locationManager.statusString) {
        case "notDetermined":
            return "Skip"
        default:
            return "Next"
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                switch(currentStep) {
                case .AskPermissions:
                    HStack {
                        Spacer()
                        Text("Welcome to TAK Aware!")
                            .bold()
                            .listRowSeparator(.hidden)
                        Spacer()
                    }
                    if(!hasAskedPermissions) {
                        Text("Let's start by granting permissions to track and broadcast your location")
                            .listRowSeparator(.hidden)
                        HStack {
                            Spacer()
                            Button("Next") {
                                locationManager.requestAlwaysAuthorization()
                                hasAskedPermissions = true
                            }
                            .buttonStyle(.borderedProminent)
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    } else {
                        switch(locationManager.statusString) {
                        case "notDetermined":
                            Text("Requesting permissions")
                                .listRowSeparator(.hidden)
                        case "authorizedWhenInUse":
                            Text("You can also grant permissions for TAK Aware to continue to broadcast your information in the background")
                                .listRowSeparator(.hidden)
                            HStack {
                                Spacer()
                                Button("Enable") {
                                    locationManager.requestAlwaysAuthorization()
                                }
                                .buttonStyle(.borderedProminent)
                                Spacer()
                            }
                        case "authorizedAlways":
                            Text("Location Permissions granted. Now let's set up your user information")
                                .listRowSeparator(.hidden)
                        default:
                            Text("No Location Permissions were granted. You will need to change this in your device settings to enable location tracking.")
                                .listRowSeparator(.hidden)
                        }
                        
                        HStack {
                            Spacer()
                            Button(permissionsButtonText) {
                                currentStep = OnboardingStep.SetUserInformation
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(locationManager.statusString == "notDetermined")
                        }
                        .padding(.bottom, 20)
                    }
                case .SetUserInformation:
                    HStack {
                        Spacer()
                        Text("User Information")
                            .bold()
                            .listRowSeparator(.hidden)
                        Spacer()
                    }
                    UserInformation()
                        .listRowSeparator(.hidden)
                    HStack {
                        Spacer()
                        Button("Next") {
                            currentStep = OnboardingStep.ConnectToServer
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.bottom, 20)
                case .ConnectToServer:
                    HStack {
                        Spacer()
                        Text("Would you like to connect to a TAK Server?")
                            .bold()
                            .listRowSeparator(.hidden)
                        Spacer()
                    }
                    ConnectionOptions(isProcessingDataPackage: $isProcessingDataPackage)
                        .listRowSeparator(.hidden)
                    
                    if(isProcessingDataPackage) {
                        Text("Processing Data Package...")
                    } else if(!SettingsStore.global.takServerUrl.isEmpty) {
                        Text("Configured TAK Server \(SettingsStore.global.takServerUrl)")
                    } else {
                        Text("You can add a server later in Settings")
                    }
                    
                    HStack {
                        Button("Previous") {
                            currentStep = OnboardingStep.SetUserInformation
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        if(isProcessingDataPackage) {
                            Button("Next") {
                                currentStep = OnboardingStep.Finished
                            }
                            .buttonStyle(.borderedProminent)
                        } else if(!SettingsStore.global.takServerUrl.isEmpty) {
                            Button("Next") {
                                currentStep = OnboardingStep.Finished
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Skip") {
                                currentStep = OnboardingStep.Finished
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.bottom, 20)
                case .Finished:
                    Text("And we're all done! You can update these settings at any time through the menu on the main screen. You'll also find the support contact information there if you have any problems. Happy TAK'ing!")
                        .listRowSeparator(.hidden)
                    HStack {
                        Spacer()
                        Button("Previous") {
                            currentStep = OnboardingStep.ConnectToServer
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button("Close Onboarding", role: .none) {
                            SettingsStore.global.hasOnboarded = true
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
            HStack {
                Spacer()
                Image("taklogo").resizable().frame(width: 100, height: 100)
                Spacer()
            }
        }
        .navigationViewStyle(.stack)
    }
}
