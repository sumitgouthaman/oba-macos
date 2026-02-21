import SwiftUI
import CoreLocation
import Combine

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @StateObject private var locationManager = LocationManager()
    
    @State private var nearbyStops: [OBAStop] = []
    @State private var nearbyRoutes: [String: OBARoute] = [:]
    @State private var searchQuery: String = ""
    @State private var isLoadingStops = false
    @State private var errorMessage: String?
    @State private var pendingLocationSearch = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("OneBusAway Settings")
                    .font(.title)
                    .bold()
                
                GroupBox("API Configuration") {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("API Key", text: $store.apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .help("Enter your OneBusAway API Key")
                        
                        TextField("Server URL", text: $store.serverURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .help("Base URL of the OneBusAway server (without trailing slash)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(4)
                }
                
                GroupBox("Find Stops") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("Search by name or number", text: $searchQuery)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    performSearch()
                                }
                            
                            Button(action: performSearch) {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            .disabled(store.apiKey.isEmpty || isLoadingStops || searchQuery.isEmpty)
                        }
                        
                        HStack {
                            Button(action: fetchNearbyStops) {
                                Label("Find Nearby Stops", systemImage: "location.fill")
                            }
                            .disabled(store.apiKey.isEmpty || isLoadingStops)
                            
                            if isLoadingStops {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.leading, 8)
                            }
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if nearbyStops.isEmpty && !isLoadingStops && errorMessage == nil {
                                Text("No stops found.")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(nearbyStops) { stop in
                                    StopRowView(stop: stop, routes: nearbyRoutes)
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(8)
                }
                
                GroupBox("Saved Stops") {
                    VStack(alignment: .leading, spacing: 12) {
                        if store.savedStops.isEmpty {
                             Text("No saved stops.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(store.savedStops) { savedStop in
                                SavedStopRowView(savedStop: savedStop)
                                Divider()
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // React to location being updated after a "Find Nearby Stops" request
        .onReceive(locationManager.$location) { location in
            guard pendingLocationSearch, let loc = location else { return }
            pendingLocationSearch = false
            performNearbyFetch(with: loc)
        }
        // React to location errors surfaced from the delegate
        .onReceive(locationManager.$locationError) { error in
            guard pendingLocationSearch, let error = error else { return }
            pendingLocationSearch = false
            isLoadingStops = false
            errorMessage = error.localizedDescription
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isLoadingStops = true
        errorMessage = nil
        
        Task {
            do {
                let data = try await OneBusAwayManager.shared.searchStops(
                    query: searchQuery,
                    apiKey: store.apiKey,
                    serverURL: store.serverURL
                )
                await MainActor.run {
                    self.nearbyStops = data.list
                    for route in data.references.routes {
                        self.nearbyRoutes[route.id] = route
                    }
                    self.isLoadingStops = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingStops = false
                }
            }
        }
    }
    
    private func fetchNearbyStops() {
        pendingLocationSearch = true
        isLoadingStops = true
        errorMessage = nil
        locationManager.requestLocation()
        // Actual fetch is triggered via .onReceive(locationManager.$location)
    }
    
    private func performNearbyFetch(with loc: CLLocation) {
        Task {
            do {
                let data = try await OneBusAwayManager.shared.getStopsForLocation(
                    lat: loc.coordinate.latitude,
                    lon: loc.coordinate.longitude,
                    apiKey: store.apiKey,
                    serverURL: store.serverURL
                )
                await MainActor.run {
                    self.nearbyStops = data.list
                    for route in data.references.routes {
                        self.nearbyRoutes[route.id] = route
                    }
                    self.isLoadingStops = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingStops = false
                }
            }
        }
    }
}

struct StopRowView: View {
    @EnvironmentObject var store: Store
    let stop: OBAStop
    let routes: [String: OBARoute]
    
    var isSaved: Bool {
        store.isStopSaved(stop.id)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stop.name)
                    .font(.headline)
                Text("Direction: \(stop.direction) • Routes: \(stop.routeIds.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                store.toggleStop(stop: stop, availableRoutes: routes)
            }) {
                Image(systemName: isSaved ? "star.fill" : "star")
                    .foregroundColor(isSaved ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

struct SavedStopRowView: View {
    @EnvironmentObject var store: Store
    let savedStop: SavedStop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(savedStop.name)
                    .font(.headline)
                Spacer()
                Button("Remove") {
                    if let index = store.savedStops.firstIndex(where: { $0.id == savedStop.id }) {
                        store.savedStops.remove(at: index)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Routes to show:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(savedStop.routes) { route in
                    Toggle(isOn: Binding(
                        get: { route.isEnabled },
                        set: { _ in store.toggleRoute(stopId: savedStop.id, routeId: route.id) }
                    )) {
                        Text(route.name)
                            .font(.subheadline)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 8)
    }
}
