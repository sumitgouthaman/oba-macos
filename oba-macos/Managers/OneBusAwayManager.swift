import Foundation
import OSLog

enum OBAError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError(Error)
    case missingAPIKey
}

class OneBusAwayManager {
    static let shared = OneBusAwayManager()
    private let logger = Logger(subsystem: "com.oba-macos", category: "Network")
    private let baseURL = "https://api.pugetsound.onebusaway.org/api/where"
    
    private init() {}
    
    // MARK: - Endpoints
    
    func getStopsForLocation(lat: Double, lon: Double, radius: Int = 500, apiKey: String) async throws -> OBAStopsForLocationData {
        guard !apiKey.isEmpty else { throw OBAError.missingAPIKey }
        
        let path = "/stops-for-location.json"
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "radius", value: String(radius))
        ]
        
        guard let url = components.url else { throw OBAError.invalidURL }
        
        let data: OBAStopsForLocationData = try await performRequest(url: url)
        return data
    }
    
    func searchStops(query: String, apiKey: String) async throws -> OBAStopsForLocationData {
        guard !apiKey.isEmpty else { throw OBAError.missingAPIKey }
        
        let path = "/search/stop.json"
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "input", value: query)
        ]
        
        guard let url = components.url else { throw OBAError.invalidURL }
        
        let data: OBAStopsForLocationData = try await performRequest(url: url)
        return data
    }
    
    func getArrivalsAndDeparturesForStop(stopId: String, minutesBefore: Int = 5, minutesAfter: Int = 30, apiKey: String) async throws -> OBAArrivalsAndDeparturesForStopData {
        guard !apiKey.isEmpty else { throw OBAError.missingAPIKey }
        
        let path = "/arrivals-and-departures-for-stop/\(stopId).json"
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "minutesBefore", value: String(minutesBefore)),
            URLQueryItem(name: "minutesAfter", value: String(minutesAfter))
        ]
        
        guard let url = components.url else { throw OBAError.invalidURL }
        
        let data: OBAArrivalsAndDeparturesForStopData = try await performRequest(url: url)
        return data
    }
    
    // MARK: - Helper
    
    private func performRequest<T: Codable>(url: URL) async throws -> T {
        logger.debug("Fetching URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OBAError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error("HTTP Error: \(httpResponse.statusCode)")
            throw OBAError.apiError("Status code \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            let obaResponse = try decoder.decode(OBAResponse<T>.self, from: data)
            
            if obaResponse.code != 200 {
                throw OBAError.apiError(obaResponse.text)
            }
            
            return obaResponse.data
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            throw OBAError.decodingError(error)
        }
    }
}
