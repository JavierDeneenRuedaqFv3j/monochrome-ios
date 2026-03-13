import SwiftUI

struct LibraryView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(LibraryManager.self) private var libraryManager
    @Environment(AudioPlayerService.self) private var audioPlayer
    @State private var selectedFilter: LibraryFilter = .all
    @State private var sortNewest = true

    enum LibraryFilter: String, CaseIterable {
        case all = "All"
        case tracks = "Tracks"
        case albums = "Albums"
        case artists = "Artists"
        case playlists = "Playlists"
        case mixes = "Mixes"
    }

    private var isEmpty: Bool {
        libraryManager.favoriteTracks.isEmpty &&
        libraryManager.favoriteAlbums.isEmpty &&
        libraryManager.favoriteArtists.isEmpty &&
        libraryManager.favoritePlaylists.isEmpty &&
        libraryManager.favoriteMixes.isEmpty
    }

    private var availableFilters: [LibraryFilter] {
        var filters: [LibraryFilter] = [.all]
        if !libraryManager.favoriteTracks.isEmpty { filters.append(.tracks) }
        if !libraryManager.favoriteAlbums.isEmpty { filters.append(.albums) }
        if !libraryManager.favoriteArtists.isEmpty { filters.append(.artists) }
        if !libraryManager.favoritePlaylists.isEmpty { filters.append(.playlists) }
        if !libraryManager.favoriteMixes.isEmpty { filters.append(.mixes) }
        return filters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Library")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.foreground)

                Spacer()

                if selectedFilter == .tracks && !libraryManager.favoriteTracks.isEmpty {
                    sortButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if isEmpty {
                emptyState
            } else {
                // Filter chips
                if availableFilters.count > 2 {
                    filterChips
                        .padding(.bottom, 8)
                }

                // Content
                contentView
            }
        }
        .background(Theme.background)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableFilters, id: \.self) { filter in
                    Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedFilter = filter } }) {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedFilter == filter ? Theme.primaryForeground : Theme.foreground)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedFilter == filter ? Theme.foreground : Theme.secondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Content Router

    @ViewBuilder
    private var contentView: some View {
        switch selectedFilter {
        case .all: allSectionsView
        case .tracks: tracksFullView
        case .albums: albumsFullView
        case .artists: artistsFullView
        case .playlists: playlistsFullView
        case .mixes: mixesFullView
        }
    }

    // MARK: - All Sections View

    private var allSectionsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if !libraryManager.favoriteTracks.isEmpty {
                    allTracksSection
                }
                if !libraryManager.favoriteAlbums.isEmpty {
                    allAlbumsSection
                }
                if !libraryManager.favoriteArtists.isEmpty {
                    allArtistsSection
                }
                if !libraryManager.favoritePlaylists.isEmpty {
                    allPlaylistsSection
                }
                if !libraryManager.favoriteMixes.isEmpty {
                    allMixesSection
                }
                Spacer(minLength: 120)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - All: Tracks Section

    private var allTracksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Tracks", count: libraryManager.favoriteTracks.count) {
                selectedFilter = .tracks
            }
            ForEach(Array(libraryManager.favoriteTracks.prefix(3).enumerated()), id: \.element.id) { index, track in
                let queue = Array(libraryManager.favoriteTracks.dropFirst(index + 1))
                let previous = Array(libraryManager.favoriteTracks.prefix(index))
                TrackRow(track: track, queue: queue, previousTracks: previous, showCover: true, navigationPath: $navigationPath)
            }
        }
    }

    // MARK: - All: Albums Section

    private var allAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Albums", count: libraryManager.favoriteAlbums.count) {
                selectedFilter = .albums
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(libraryManager.favoriteAlbums) { album in
                        Button(action: { navigationPath.append(album) }) {
                            AlbumCard(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - All: Artists Section

    private var allArtistsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Artists", count: libraryManager.favoriteArtists.count) {
                selectedFilter = .artists
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(libraryManager.favoriteArtists) { artist in
                        Button(action: { navigationPath.append(artist) }) {
                            VStack(spacing: 8) {
                                AsyncImage(url: MonochromeAPI().getImageUrl(id: artist.picture, size: 320)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Circle().fill(Theme.secondary)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(Theme.mutedForeground.opacity(0.3))
                                            )
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())

                                Text(artist.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.mutedForeground)
                                    .lineLimit(1)
                            }
                            .frame(width: 100)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - All: Playlists Section

    private var allPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Playlists", count: libraryManager.favoritePlaylists.count) {
                selectedFilter = .playlists
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(libraryManager.favoritePlaylists) { playlist in
                        Button(action: { navigationPath.append(playlist) }) {
                            PlaylistCard(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - All: Mixes Section

    private var allMixesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Mixes", count: libraryManager.favoriteMixes.count) {
                selectedFilter = .mixes
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(libraryManager.favoriteMixes) { mix in
                        MixCard(mix: mix)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Full Views (when filter selected)

    private var sortedTracks: [Track] {
        if sortNewest { return libraryManager.favoriteTracks }
        return libraryManager.favoriteTracks.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
    }

    private var tracksFullView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(libraryManager.favoriteTracks.count) track\(libraryManager.favoriteTracks.count == 1 ? "" : "s")")
                .font(.system(size: 13))
                .foregroundColor(Theme.mutedForeground)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            List {
                ForEach(Array(sortedTracks.enumerated()), id: \.element.id) { index, track in
                    let queue = Array(sortedTracks.dropFirst(index + 1))
                    let previous = Array(sortedTracks.prefix(index))
                    TrackRow(track: track, queue: queue, previousTracks: previous, showCover: true, navigationPath: $navigationPath)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Color.clear.frame(height: 120)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
        }
    }

    private var albumsFullView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(libraryManager.favoriteAlbums) { album in
                    Button(action: { navigationPath.append(album) }) {
                        LibraryAlbumRow(album: album)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 120)
            }
        }
    }

    private var artistsFullView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(libraryManager.favoriteArtists) { artist in
                    Button(action: { navigationPath.append(artist) }) {
                        LibraryArtistRow(artist: artist)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 120)
            }
        }
    }

    private var playlistsFullView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(libraryManager.favoritePlaylists) { playlist in
                    Button(action: { navigationPath.append(playlist) }) {
                        LibraryPlaylistRow(playlist: playlist)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 120)
            }
        }
    }

    private var mixesFullView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(libraryManager.favoriteMixes) { mix in
                    LibraryMixRow(mix: mix)
                }
                Spacer(minLength: 120)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { action() } }) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.foreground)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.mutedForeground)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
    }

    private var sortButton: some View {
        Button(action: { sortNewest.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12))
                Text(sortNewest ? "Recent" : "A-Z")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(Theme.mutedForeground)
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "heart")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(Theme.mutedForeground.opacity(0.4))
                Text("Your favorites will appear here")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

// MARK: - Library Row Components

private struct LibraryAlbumRow: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: MonochromeAPI().getImageUrl(id: album.cover)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.secondary)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 3) {
                Text(album.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.foreground)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let artist = album.artist {
                        Text(artist.name)
                    }
                    if let year = album.releaseYear {
                        Text("·")
                        Text(year)
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.mutedForeground)
                .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct LibraryArtistRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: MonochromeAPI().getImageUrl(id: artist.picture, size: 160)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(Theme.secondary)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.mutedForeground.opacity(0.3))
                        )
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())

            Text(artist.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.foreground)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct LibraryPlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: playlistImageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.secondary)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: 18))
                                .foregroundColor(Theme.mutedForeground.opacity(0.3))
                        )
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.title ?? "Playlist")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.foreground)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let user = playlist.user, let name = user.name {
                        Text(name)
                    }
                    if let count = playlist.numberOfTracks {
                        Text("·")
                        Text("\(count) tracks")
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.mutedForeground)
                .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var playlistImageURL: URL? {
        guard let image = playlist.image, !image.isEmpty else { return nil }
        if image.hasPrefix("http") { return URL(string: image) }
        return MonochromeAPI().getImageUrl(id: image)
    }
}

private struct LibraryMixRow: View {
    let mix: Mix

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: mixImageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.secondary)
                        .overlay(
                            Image(systemName: "waveform")
                                .font(.system(size: 18))
                                .foregroundColor(Theme.mutedForeground.opacity(0.3))
                        )
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 3) {
                Text(mix.title ?? "Mix")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.foreground)
                    .lineLimit(1)

                if let subTitle = mix.subTitle {
                    Text(subTitle)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.mutedForeground)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var mixImageURL: URL? {
        guard let cover = mix.cover, !cover.isEmpty else { return nil }
        if cover.hasPrefix("http") { return URL(string: cover) }
        return MonochromeAPI().getImageUrl(id: cover)
    }
}

// MARK: - Cards (for horizontal scroll in All view)

private struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: cardImageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.mutedForeground.opacity(0.2))
                        )
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(playlist.title ?? "Playlist")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.foreground)
                .lineLimit(1)

            if let count = playlist.numberOfTracks {
                Text("\(count) tracks")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.mutedForeground)
            }
        }
        .frame(width: 150)
    }

    private var cardImageURL: URL? {
        guard let image = playlist.image, !image.isEmpty else { return nil }
        if image.hasPrefix("http") { return URL(string: image) }
        return MonochromeAPI().getImageUrl(id: image)
    }
}

private struct MixCard: View {
    let mix: Mix

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: cardImageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                        .overlay(
                            Image(systemName: "waveform")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.mutedForeground.opacity(0.2))
                        )
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(mix.title ?? "Mix")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.foreground)
                .lineLimit(1)

            if let subTitle = mix.subTitle {
                Text(subTitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.mutedForeground)
                    .lineLimit(1)
            }
        }
        .frame(width: 150)
    }

    private var cardImageURL: URL? {
        guard let cover = mix.cover, !cover.isEmpty else { return nil }
        if cover.hasPrefix("http") { return URL(string: cover) }
        return MonochromeAPI().getImageUrl(id: cover)
    }
}

#Preview {
    LibraryView(navigationPath: .constant(NavigationPath()))
        .environment(LibraryManager.shared)
        .environment(AudioPlayerService())
}
