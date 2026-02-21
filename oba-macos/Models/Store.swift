import Foundation
import SwiftUI
import Combine

class Store: ObservableObject {
    @Published var apiKey: String = "" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
        }
    }
    
    @Published var savedStops: [SavedStop] = [] {
        didSet {
            saveStops()
        }
    }
    
    private let stopsKey = "OBASavedStops"
    private let apiKeyKey = "OBAApiKey"
    
    init() {
        if let storedApiKey = UserDefaults.standard.string(forKey: "OBAApiKey") {
            self.apiKey = storedApiKey
        }
        loadStops()
    }
    
    private func saveStops() {
        if let encoded = try? JSONEncoder().encode(savedStops) {
            UserDefaults.standard.set(encoded, forKey: stopsKey)
        }
    }
    
    private func loadStops() {
        if let data = UserDefaults.standard.data(forKey: stopsKey),
           let decoded = try? JSONDecoder().decode([SavedStop].self, from: data) {
            savedStops = decoded
        }
    }
    func toggleStop(stop: OBAStop, availableRoutes: [String: OBARoute]) {
        if let index = savedStops.firstIndex(where: { $0.id == stop.id }) {
            savedStops.remove(at: index)
        } else {
            let savedRoutes = stop.routeIds.map { routeId in
                SavedRoute(
                    id: routeId,
                    name: availableRoutes[routeId]?.displayName ?? "Route \(routeId)",
                    isEnabled: true
                )
            }
            let newStop = SavedStop(id: stop.id, name: stop.name, routes: savedRoutes)
            savedStops.append(newStop)
        }
    }
    
    func toggleRoute(stopId: String, routeId: String) {
        if let stopIndex = savedStops.firstIndex(where: { $0.id == stopId }),
           let routeIndex = savedStops[stopIndex].routes.firstIndex(where: { $0.id == routeId }) {
            savedStops[stopIndex].routes[routeIndex].isEnabled.toggle()
        }
    }
    
    func isStopSaved(_ stopId: String) -> Bool {
        return savedStops.contains(where: { $0.id == stopId })
    }
}
