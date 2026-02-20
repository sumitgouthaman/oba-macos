import SwiftUI
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @StateObject private var locationManager = LocationManager()
    
    @State private var nearbyStops: [OBAStop] = []
    @State private var isLoadingStops = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("OneBusAway Settings")
                .font(.title)
                .bold()
            
            GroupBox("API Key") {
                SecureField("API Key", text: $store.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .help("Enter your OneBusAway API Key")
            }
            
            GroupBox("Nearby Stops") {
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
                
                List {
                    ForEach(nearbyStops) { stop in
                        StopRowView(stop: stop)
                    }
                }
                .frame(minHeight: 200)
            }
            
            GroupBox("Saved Stops") {
                List {
                    ForEach(store.savedStops) { savedStop in
                        HStack {
                            Text(savedStop.name)
                            Spacer()
                            Button("Remove") {
                                if let index = store.savedStops.firstIndex(where: { $0.id == savedStop.id }) {
                                    store.savedStops.remove(at: index)
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.red)
                        }
                    }
                }
                .frame(minHeight: 150)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
    
    private func fetchNearbyStops() {
        locationManager.requestLocation()
        
        // Wait a bit for location
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let loc = locationManager.location else {
                errorMessage = "Could not get current location."
                return
            }
            
            isLoadingStops = true
            errorMessage = nil
            
            Task {
                do {
                    let data = try await OneBusAwayManager.shared.getStopsForLocation(
                        lat: loc.coordinate.latitude,
                        lon: loc.coordinate.longitude,
                        apiKey: store.apiKey
                    )
                    await MainActor.run {
                        self.nearbyStops = data.list
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
}

struct StopRowView: View {
    @EnvironmentObject var store: Store
    let stop: OBAStop
    
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
                store.toggleStop(stop: stop, routeIds: stop.routeIds)
            }) {
                Image(systemName: isSaved ? "star.fill" : "star")
                    .foregroundColor(isSaved ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
