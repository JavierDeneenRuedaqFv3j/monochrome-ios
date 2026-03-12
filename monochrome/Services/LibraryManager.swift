import Foundation
import Observation

@Observable
class LibraryManager {
    static let shared = LibraryManager()

    var favoriteTracks: [Track] = []
    var favoriteAlbums: [Album] = []

    private let tracksKey = "monochrome_favorite_tracks"
    private let albumsKey = "monochrome_favorite_albums"

    init() {
        loadFavorites()
    }

    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: tracksKey),
           let tracks = try? JSONDecoder().decode([Track].self, from: data) {
            self.favoriteTracks = tracks
        }

        if let data = UserDefaults.standard.data(forKey: albumsKey),
           let albums = try? JSONDecoder().decode([Album].self, from: data) {
            self.favoriteAlbums = albums
        }
    }

    func saveTracks() {
        if let data = try? JSONEncoder().encode(favoriteTracks) {
            UserDefaults.standard.set(data, forKey: tracksKey)
        }
    }

    func saveAlbums() {
        if let data = try? JSONEncoder().encode(favoriteAlbums) {
            UserDefaults.standard.set(data, forKey: albumsKey)
        }
    }

    func toggleFavorite(track: Track) {
        let wasAdded: Bool
        if let index = favoriteTracks.firstIndex(where: { $0.id == track.id }) {
            favoriteTracks.remove(at: index)
            wasAdded = false
        } else {
            favoriteTracks.insert(track, at: 0)
            wasAdded = true
        }
        saveTracks()
        syncItemInBackground(type: "track", track: track, added: wasAdded)
    }

    func isFavorite(trackId: Int) -> Bool {
        return favoriteTracks.contains(where: { $0.id == trackId })
    }

    func toggleFavorite(album: Album) {
        let wasAdded: Bool
        if let index = favoriteAlbums.firstIndex(where: { $0.id == album.id }) {
            favoriteAlbums.remove(at: index)
            wasAdded = false
        } else {
            favoriteAlbums.insert(album, at: 0)
            wasAdded = true
        }
        saveAlbums()
        syncItemInBackground(type: "album", album: album, added: wasAdded)
    }

    func isFavorite(albumId: Int) -> Bool {
        return favoriteAlbums.contains(where: { $0.id == albumId })
    }

    // MARK: - Cloud Sync

    /// Fetch cloud data and replace local (cloud = source of truth)
    func syncFromCloud(uid: String) async {
        do {
            let cloud = try await PocketBaseService.shared.fullSync(uid: uid)

            // Replace local with cloud data
            favoriteTracks = cloud.tracks
            saveTracks()

            favoriteAlbums = cloud.albums
            saveAlbums()

            print("[Sync] Cloud sync completed: \(favoriteTracks.count) tracks, \(favoriteAlbums.count) albums")
        } catch {
            print("[Sync] Cloud sync error: \(error.localizedDescription)")
        }
    }

    /// Sync a single item change in background (fire-and-forget)
    private func syncItemInBackground(type: String, track: Track? = nil, album: Album? = nil, added: Bool) {
        guard let uid = AuthService.shared.currentUser?.uid else { return }

        Task.detached(priority: .utility) {
            do {
                try await PocketBaseService.shared.syncLibraryItem(
                    uid: uid, type: type, track: track, album: album, added: added
                )
            } catch {
                print("[Sync] Item sync error: \(error.localizedDescription)")
            }
        }
    }
}
