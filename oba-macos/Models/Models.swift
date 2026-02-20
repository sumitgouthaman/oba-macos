import Foundation

// MARK: - API Response Wrappers
struct OBAResponse<T: Codable>: Codable {
    let code: Int
    let version: Int
    let text: String
    let data: T
}

struct OBAStopsForLocationData: Codable {
    let limitExceeded: Bool
    let list: [OBAStop]
    let references: OBAReferences
}

struct OBAArrivalsAndDeparturesForStopData: Codable {
    let entry: OBAStopWithArrivals
    let references: OBAReferences
}

struct OBAReferences: Codable {
    let routes: [OBARoute]
    let agencies: [OBAAgency]?
    // Can add stops, trips, situations if needed
}

// MARK: - Core Entities
struct OBAAgency: Codable, Identifiable {
    let id: String
    let name: String
    let url: String
    let timezone: String
    let lang: String
    let phone: String?
    let disclaimer: String?
    let privateService: Bool?
}

struct OBAStop: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double
    let direction: String
    let code: String
    let locationType: Int
    let routeIds: [String]
}

struct OBARoute: Codable, Identifiable, Hashable {
    let id: String
    let shortName: String?
    let longName: String?
    let description: String?
    let type: Int
    let agencyId: String
    
    var displayName: String {
        if let shortName = shortName, !shortName.isEmpty {
            return shortName
        }
        return longName ?? "Unknown Route"
    }
}

struct OBAStopWithArrivals: Codable {
    let stopId: String
    let arrivalsAndDepartures: [OBAArrivalAndDeparture]
    let nearbyStopIds: [String]?
}

struct OBAArrivalAndDeparture: Codable, Identifiable {
    var id: String { tripId + stopId }
    
    let routeId: String
    let tripId: String
    let serviceDate: Int64
    let vehicleId: String?
    let stopId: String
    let stopSequence: Int
    
    let blockTripSequence: Int
    let routeShortName: String
    let tripHeadsign: String
    
    let scheduledArrivalTime: Int64
    let predictedArrivalTime: Int64
    let scheduledDepartureTime: Int64
    let predictedDepartureTime: Int64
    
    let status: String?
    
    var bestArrivalTime: Date {
        let time = predictedArrivalTime > 0 ? predictedArrivalTime : scheduledArrivalTime
        return Date(timeIntervalSince1970: TimeInterval(time) / 1000.0)
    }
    
    var minutesUntilArrival: Int {
        let diff = bestArrivalTime.timeIntervalSinceNow
        return max(0, Int(diff / 60.0))
    }
}

// MARK: - App Models (For persisting user selection)
struct SavedStop: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let routeIds: [String] // IDs of the routes the user wants to see for this stop
}
