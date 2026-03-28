//
//  GoToLocationSheet.swift
//  TAKAware
//

import CoreLocation
import MapKit
import SwiftUI
import mgrs_ios

struct GoToLocationSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager

    enum FormatTab: String, CaseIterable, Identifiable {
        case dms    = "DMS"
        case ddm    = "DDM"
        case mgrs   = "MGRS"
        case decimal = "Dec"
        case utm    = "UTM"
        case address = "Addr"

        var id: String { rawValue }
    }

    @State private var selectedTab: FormatTab = .decimal
    @State private var resolvedCoordinate: CLLocationCoordinate2D?

    // DMS
    @State private var dmsLatDir = "N"
    @State private var dmsLatDeg = ""
    @State private var dmsLatMin = ""
    @State private var dmsLatSec = ""
    @State private var dmsLonDir = "W"
    @State private var dmsLonDeg = ""
    @State private var dmsLonMin = ""
    @State private var dmsLonSec = ""

    // DDM
    @State private var ddmLatDir = "N"
    @State private var ddmLatDeg = ""
    @State private var ddmLatMin = ""
    @State private var ddmLonDir = "W"
    @State private var ddmLonDeg = ""
    @State private var ddmLonMin = ""

    // MGRS
    @State private var mgrsText = ""

    // Decimal
    @State private var decLat = ""
    @State private var decLon = ""

    // UTM
    @State private var utmText = ""

    // Address
    @State private var addressText = ""
    @StateObject private var addressSearcher = AddressSearcher()

    private var hasCoordinate: Bool { resolvedCoordinate != nil }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Format", selection: $selectedTab) {
                    ForEach(FormatTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .dms:     dmsFields
                        case .ddm:     ddmFields
                        case .mgrs:    mgrsField
                        case .decimal: decimalFields
                        case .utm:     utmField
                        case .address: addressFields
                        }
                    }
                    .padding()
                }

                Divider()

                HStack(spacing: 10) {
                    Button("Cancel") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)

                    Button {
                        guard let coord = resolvedCoordinate else { return }
                        NotificationCenter.default.post(
                            name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_COORDINATE),
                            object: coord
                        )
                        dismiss()
                    } label: {
                        Text("Go")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .disabled(!hasCoordinate)

                    Button {
                        guard let coord = resolvedCoordinate else { return }
                        NotificationCenter.default.post(
                            name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_COORDINATE),
                            object: coord
                        )
                        DataController.shared.createMarker(latitude: coord.latitude, longitude: coord.longitude)
                        dismiss()
                    } label: {
                        Text("Drop Point")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasCoordinate)
                }
                .padding()
            }
            .navigationTitle("Go To Location")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedTab) { _ in resolvedCoordinate = nil }
            .onAppear {
                if let coord = locationManager.lastLocation?.coordinate {
                    addressSearcher.setRegionCenter(coord)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - DMS

    private var dmsFields: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Picker("", selection: $dmsLatDir) {
                    Text("N").tag("N")
                    Text("S").tag("S")
                }
                .pickerStyle(.segmented)
                .frame(width: 70)

                TextField("DD", text: $dmsLatDeg)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: dmsLatDeg) { _ in resolveDMS() }
                Text("°")
                TextField("MM", text: $dmsLatMin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: dmsLatMin) { _ in resolveDMS() }
                Text("'")
                TextField("SS.SSS", text: $dmsLatSec)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: dmsLatSec) { _ in resolveDMS() }
                Text("\"")
            }

            HStack(spacing: 6) {
                Picker("", selection: $dmsLonDir) {
                    Text("E").tag("E")
                    Text("W").tag("W")
                }
                .pickerStyle(.segmented)
                .frame(width: 70)

                TextField("DDD", text: $dmsLonDeg)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: dmsLonDeg) { _ in resolveDMS() }
                Text("°")
                TextField("MM", text: $dmsLonMin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: dmsLonMin) { _ in resolveDMS() }
                Text("'")
                TextField("SS.SSS", text: $dmsLonSec)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: dmsLonSec) { _ in resolveDMS() }
                Text("\"")
            }

            if let coord = resolvedCoordinate {
                coordinatePreview(coord)
            }
        }
    }

    private func resolveDMS() {
        guard let latDeg = Double(dmsLatDeg), let latMin = Double(dmsLatMin), let latSec = Double(dmsLatSec),
              let lonDeg = Double(dmsLonDeg), let lonMin = Double(dmsLonMin), let lonSec = Double(dmsLonSec)
        else { resolvedCoordinate = nil; return }

        var lat = latDeg + latMin / 60.0 + latSec / 3600.0
        var lon = lonDeg + lonMin / 60.0 + lonSec / 3600.0
        if dmsLatDir == "S" { lat = -lat }
        if dmsLonDir == "W" { lon = -lon }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        resolvedCoordinate = CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }

    // MARK: - DDM

    private var ddmFields: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Picker("", selection: $ddmLatDir) {
                    Text("N").tag("N")
                    Text("S").tag("S")
                }
                .pickerStyle(.segmented)
                .frame(width: 70)

                TextField("DD", text: $ddmLatDeg)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: ddmLatDeg) { _ in resolveDDM() }
                Text("°")
                TextField("MM.MMM", text: $ddmLatMin)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: ddmLatMin) { _ in resolveDDM() }
                Text("'")
            }

            HStack(spacing: 6) {
                Picker("", selection: $ddmLonDir) {
                    Text("E").tag("E")
                    Text("W").tag("W")
                }
                .pickerStyle(.segmented)
                .frame(width: 70)

                TextField("DDD", text: $ddmLonDeg)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: ddmLonDeg) { _ in resolveDDM() }
                Text("°")
                TextField("MM.MMM", text: $ddmLonMin)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onChange(of: ddmLonMin) { _ in resolveDDM() }
                Text("'")
            }

            if let coord = resolvedCoordinate {
                coordinatePreview(coord)
            }
        }
    }

    private func resolveDDM() {
        guard let latDeg = Double(ddmLatDeg), let latMin = Double(ddmLatMin),
              let lonDeg = Double(ddmLonDeg), let lonMin = Double(ddmLonMin)
        else { resolvedCoordinate = nil; return }

        var lat = latDeg + latMin / 60.0
        var lon = lonDeg + lonMin / 60.0
        if ddmLatDir == "S" { lat = -lat }
        if ddmLonDir == "W" { lon = -lon }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        resolvedCoordinate = CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }

    // MARK: - MGRS

    private var mgrsField: some View {
        VStack(spacing: 12) {
            TextField("e.g. 38SMB 4927 2362", text: $mgrsText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onChange(of: mgrsText) { _ in resolveMGRS() }

            if let coord = resolvedCoordinate {
                coordinatePreview(coord)
            }
        }
    }

    private func resolveMGRS() {
        guard MGRS.isMGRS(mgrsText) else { resolvedCoordinate = nil; return }
        let coord = MGRS.parseToCoordinate(mgrsText)
        resolvedCoordinate = CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }

    // MARK: - Decimal

    private var decimalFields: some View {
        VStack(spacing: 12) {
            TextField("Latitude  (e.g. 38.3706)", text: $decLat)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: decLat) { _ in resolveDecimal() }

            TextField("Longitude  (e.g. -122.4373)", text: $decLon)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: decLon) { _ in resolveDecimal() }

            if let coord = resolvedCoordinate {
                coordinatePreview(coord)
            }
        }
    }

    private func resolveDecimal() {
        guard let lat = Double(decLat), let lon = Double(decLon) else { resolvedCoordinate = nil; return }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        resolvedCoordinate = CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }

    // MARK: - UTM

    private var utmField: some View {
        VStack(spacing: 12) {
            TextField("e.g. 18N 594934 4654233", text: $utmText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onChange(of: utmText) { _ in resolveUTM() }

            Text("Zone + Hemisphere  Easting  Northing")
                .font(.caption)
                .foregroundColor(.secondary)

            if let coord = resolvedCoordinate {
                coordinatePreview(coord)
            }
        }
    }

    private func resolveUTM() {
        guard UTM.isUTM(utmText) else { resolvedCoordinate = nil; return }
        let coord = UTM.parseToCoordinate(utmText)
        resolvedCoordinate = CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }

    // MARK: - Address

    private var addressFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search address…", text: $addressText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: addressText) { query in
                    resolvedCoordinate = nil
                    addressSearcher.search(query: query)
                }

            if !addressSearcher.completions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(addressSearcher.completions.enumerated()), id: \.offset) { _, completion in
                        Button {
                            let full = completion.subtitle.isEmpty
                                ? completion.title
                                : "\(completion.title), \(completion.subtitle)"
                            addressText = full
                            addressSearcher.completions = []
                            addressSearcher.geocode(completion: completion) { coord in
                                resolvedCoordinate = coord
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                    .foregroundColor(.primary)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            if let coord = resolvedCoordinate {
                coordinatePreview(coord)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func coordinatePreview(_ coord: CLLocationCoordinate2D) -> some View {
        Text(String(format: "%.6f°,  %.6f°", coord.latitude, coord.longitude))
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }
}

// MARK: - AddressSearcher

class AddressSearcher: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()
    private var debounceTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    func setRegionCenter(_ center: CLLocationCoordinate2D) {
        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
    }

    func search(query: String) {
        debounceTask?.cancel()
        guard !query.isEmpty else { completions = []; return }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { completer.queryFragment = query }
        }
    }

    func geocode(completion: MKLocalSearchCompletion, callback: @escaping (CLLocationCoordinate2D?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                callback(response?.mapItems.first?.placemark.coordinate)
            }
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = Array(completer.results.prefix(5))
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async { self.completions = [] }
    }
}
