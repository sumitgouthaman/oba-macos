import SwiftUI
import Combine

struct PopoverView: View {
    @EnvironmentObject var store: Store
    @Environment(\.openWindow) private var openWindow
    @State private var arrivalsByStop: [String: [OBAArrivalAndDeparture]] = [:]
    @State private var arrivalErrors: [String: String] = [:]
    @State private var isLoading = false
    @State private var globalErrorMessage: String?
    
    // Auto-refresh every 30 seconds
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            HStack {
                Text("Incoming Buses")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Button(action: refreshData) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(isLoading)
            }
            .padding([.horizontal, .top])
            
            if store.apiKey.isEmpty {
                Spacer()
                Text("Please configure API Key in Settings.")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else if store.savedStops.isEmpty {
                Spacer()
                Text("No stops saved. Add them in Settings.")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                if let globalError = globalErrorMessage {
                    Text(globalError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding([.horizontal, .top])
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(store.savedStops) { savedStop in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(savedStop.name)
                                    .font(.subheadline)
                                    .bold()
                                
                                if let stopError = arrivalErrors[savedStop.id] {
                                    Text(stopError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else if let arrivals = arrivalsByStop[savedStop.id] {
                                    if arrivals.isEmpty {
                                        Text("No incoming buses.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        ForEach(arrivals) { arrival in
                                            HStack {
                                                Text(arrival.routeShortName)
                                                    .frame(width: 40, alignment: .leading)
                                                    .font(.system(.body, design: .monospaced))
                                                Text(arrival.tripHeadsign)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                Spacer()
                                                if let minutes = arrival.minutesUntilArrival {
                                                    Text("\(minutes) min")
                                                        .bold()
                                                        .foregroundColor(minutes <= 5 ? .red : .primary)
                                                }
                                            }
                                            .font(.caption)
                                        }
                                    }
                                } else {
                                    ProgressView().controlSize(.small)
                                }
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
            }
            
            HStack {
                Button("Settings") {
                    openSettings()
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 320, height: 400)
        .onAppear {
            refreshData()
        }
        .onReceive(refreshTimer) { _ in
            refreshData()
        }
    }
    
    private func refreshData() {
        guard !store.apiKey.isEmpty, !store.savedStops.isEmpty else { return }
        
        isLoading = true
        globalErrorMessage = nil
        
        Task {
            var newArrivals: [String: [OBAArrivalAndDeparture]] = [:]
            var newErrors: [String: String] = [:]
            let now = Date()
            
            for stop in store.savedStops {
                do {
                    let data = try await OneBusAwayManager.shared.getArrivalsAndDeparturesForStop(
                        stopId: stop.id,
                        apiKey: store.apiKey,
                        serverURL: store.serverURL
                    )
                    
                    // Filter to enabled routes, drop past arrivals, then sort
                    let enabledRouteIds = stop.routes.filter { $0.isEnabled }.map { $0.id }
                    let sorted = data.entry.arrivalsAndDepartures
                        .filter { enabledRouteIds.contains($0.routeId) }
                        .filter { $0.bestArrivalTime > now }
                        .sorted { $0.bestArrivalTime < $1.bestArrivalTime }
                    
                    newArrivals[stop.id] = sorted
                } catch {
                    newErrors[stop.id] = error.localizedDescription
                }
            }
            
            await MainActor.run {
                self.arrivalsByStop = newArrivals
                self.arrivalErrors = newErrors
                self.isLoading = false
            }
        }
    }
    
    private func openSettings() {
        openWindow(id: "settings")
        NSApp.activate(ignoringOtherApps: true)
    }
}
