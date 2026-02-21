import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var store: Store
    @Environment(\.openWindow) private var openWindow
    @State private var arrivalsByStop: [String: [OBAArrivalAndDeparture]] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            HStack {
                Text("Incoming Buses")
                    .font(.headline)
                Spacer()
                Button(action: refreshData) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(isLoading)
            }
            .padding([.horizontal, .top])
            
            if store.apiKey.isEmpty {
                Text("Please configure API Key in Settings.")
                    .foregroundColor(.secondary)
                    .padding()
            } else if store.savedStops.isEmpty {
                Text("No stops saved. Add them in Settings.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                if isLoading && arrivalsByStop.isEmpty {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(store.savedStops) { savedStop in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(savedStop.name)
                                        .font(.subheadline)
                                        .bold()
                                    
                                    if let arrivals = arrivalsByStop[savedStop.id] {
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
                                                    Text("\(arrival.minutesUntilArrival) min")
                                                        .bold()
                                                        .foregroundColor(arrival.minutesUntilArrival <= 5 ? .red : .primary)
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
    }
    
    private func refreshData() {
        guard !store.apiKey.isEmpty, !store.savedStops.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            var newArrivals: [String: [OBAArrivalAndDeparture]] = [:]
            var currentError: String?
            
            for stop in store.savedStops {
                do {
                    let data = try await OneBusAwayManager.shared.getArrivalsAndDeparturesForStop(stopId: stop.id, apiKey: store.apiKey)
                    
                    // Filter and sort arrivals
                    let enabledRouteIds = stop.routes.filter { $0.isEnabled }.map { $0.id }
                    let sorted = data.entry.arrivalsAndDepartures
                        .filter { enabledRouteIds.contains($0.routeId) }
                        .sorted { $0.bestArrivalTime < $1.bestArrivalTime }
                    
                    newArrivals[stop.id] = sorted
                } catch {
                    currentError = error.localizedDescription
                }
            }
            
            await MainActor.run {
                self.arrivalsByStop = newArrivals
                self.errorMessage = currentError
                self.isLoading = false
            }
        }
    }
    
    private func openSettings() {
        openWindow(id: "settings")
        NSApp.activate(ignoringOtherApps: true)
    }
}
