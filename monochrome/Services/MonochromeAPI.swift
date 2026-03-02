import Foundation
import Observation

@Observable
class MonochromeAPI {
    // We default to the public instance from the Web app
    var baseURL = "https://api.monochrome.tf"
    private var urlSession = URLSession.shared
    
    func searchTracks(query: String) async throws -> [Track] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/?s=\(encodedQuery)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Monochrome-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        return apiResponse.data?.items ?? []
    }
    
    struct TrackResponse: Codable {
        let version: String?
        let data: TrackData?
    }
    
    struct TrackData: Codable {
        let trackId: Int
        let manifest: String?
    }
    
    struct ManifestData: Codable {
        let urls: [String]
    }
    
    func fetchStreamUrl(trackId: Int) async throws -> String? {
        guard let url = URL(string: "\(baseURL)/track/?id=\(trackId)&quality=HIGH") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Monochrome-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("API returned \((response as? HTTPURLResponse)?.statusCode ?? 0) for track \(trackId)")
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(TrackResponse.self, from: data)
        guard let manifestBase64 = apiResponse.data?.manifest,
              let manifestData = Data(base64Encoded: manifestBase64),
              let manifest = try? JSONDecoder().decode(ManifestData.self, from: manifestData) else {
            return nil
        }
        
        return manifest.urls.first
    }
    
    func getImageUrl(id: String?, size: Int = 320) -> URL? {
        guard let id = id, !id.isEmpty else { return nil }
        if id.hasPrefix("http") {
            return URL(string: id)
        }
        let formattedId = id.replacingOccurrences(of: "-", with: "/")
        return URL(string: "https://resources.tidal.com/images/\(formattedId)/\(size)x\(size).jpg")
    }
}
