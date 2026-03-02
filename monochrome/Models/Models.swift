import Foundation

struct Track: Identifiable, Codable {
    let id: Int
    let title: String
    let duration: Int
    let artist: Artist?
    let album: Album?
    let streamStartDate: String?
    
    var releaseYear: String? {
        guard let dateStr = streamStartDate, dateStr.count >= 4 else { return nil }
        return String(dateStr.prefix(4))
    }
}

struct Artist: Identifiable, Codable {
    let id: Int
    let name: String
    let picture: String?
}

struct Album: Identifiable, Codable {
    let id: Int
    let title: String
    let cover: String?
}

// Wrapper structs to handle the API response structure from the backend
struct SearchResponse: Codable {
    let data: SearchData?
}

struct SearchData: Codable {
    let items: [Track]
}
