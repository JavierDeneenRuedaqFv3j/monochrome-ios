import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @Binding var navigationPath: CompatNavigationPath
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @EnvironmentObject private var libraryManager: LibraryManager
    @EnvironmentObject private var downloadManager: DownloadManager

    @State private var loadedAlbum: Album?
    @State private var tracks: [Track] = []
    @State private var isLoading = true

    private var displayAlbum: Album { loadedAlbum ?? album }

    private var albumDownloadButton: some View {
        let allDownloaded = !tracks.isEmpty && tracks.allSatisfy { downloadManager.isDownloaded($0.id) }
        let someDownloading = tracks.contains { downloadManager.isDownloading($0.id) }

        return Button(action: {
            if !allDownloaded {
                downloadManager.downloadTracks(tracks)
            }
        }) {
            if allDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.accent)
            } else if someDownloading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.mutedForeground)
            }
        }
        .buttonStyle(.borderless)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                albumHeader
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                if tracks.isEmpty && isLoading {
                    skeletonTrackList
                } else {
                    trackList
                }

                Spacer(minLength: 120)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 0)
        }
        .navigationBarTitleDisplayMode(.inline)
        .compatToolbarBackground(.hidden)
        .task { await loadAlbum() }
    }

    // MARK: - Header

    private var albumHeader: some View {
        VStack(spacing: 18) {
            // Album art with reflection effect
            ZStack {
                CachedAsyncImage(url: MonochromeAPI().getImageUrl(id: displayAlbum.cover, size: 640)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fit)
                            .blur(radius: 50)
                            .opacity(0.3)
                            .scaleEffect(1.1)
                            .offset(y: 30)
                    }
                }
                .frame(width: 240, height: 100)
                .clipped()
                .mask(
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                )
                .offset(y: 120)

                CachedAsyncImage(url: MonochromeAPI().getImageUrl(id: displayAlbum.cover, size: 640)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.radiusMd).fill(
                            LinearGradient(colors: [Theme.card, Theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.mutedForeground.opacity(0.3))
                        )
                    }
                }
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
                .shadow(color: .black.opacity(0.5), radius: 30, y: 12)
            }

            VStack(spacing: 8) {
                Text(displayAlbum.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.foreground)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let artist = displayAlbum.artist {
                    Button(action: { navigationPath.append(artist) }) {
                        Text(artist.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    if let year = displayAlbum.releaseYear {
                        Text(year)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.secondary)
                            .clipShape(Capsule())
                    }
                    if let type = displayAlbum.type, type.uppercased() != "ALBUM" {
                        Text(type)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.secondary)
                            .clipShape(Capsule())
                    }
                    if let count = displayAlbum.numberOfTracks {
                        Text("\(count) tracks")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.secondary)
                            .clipShape(Capsule())
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.mutedForeground)
            }

            // Action buttons
            HStack(spacing: 14) {
                Button(action: { libraryManager.toggleFavorite(album: displayAlbum) }) {
                    Image(systemName: libraryManager.isFavorite(albumId: displayAlbum.id) ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(libraryManager.isFavorite(albumId: displayAlbum.id) ? Theme.accent : Theme.mutedForeground)
                        .frame(width: 40, height: 40)
                        .background(Theme.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                albumDownloadButton

                Button(action: {
                    guard !tracks.isEmpty else { return }
                    let shuffled = tracks.shuffled()
                    audioPlayer.play(track: shuffled[0], queue: Array(shuffled.dropFirst()))
                }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.mutedForeground)
                        .frame(width: 40, height: 40)
                        .background(Theme.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(action: {
                    guard let first = tracks.first else { return }
                    audioPlayer.play(track: first, queue: Array(tracks.dropFirst()))
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .offset(x: 1)
                        Text("Play")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Theme.primaryForeground)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Theme.foreground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Track List

    private var isMultiDisc: Bool {
        let volumes = Set(tracks.compactMap(\.volumeNumber))
        return volumes.count > 1
    }

    @ViewBuilder
    private var trackList: some View {
        if isMultiDisc {
            let grouped = Dictionary(grouping: tracks) { $0.volumeNumber ?? 1 }
            let sortedVolumes = grouped.keys.sorted()
            ForEach(sortedVolumes, id: \.self) { volume in
                let volumeTracks = grouped[volume] ?? []

                // Disc header
                HStack(spacing: 6) {
                    Image(systemName: "opticaldisc.fill")
                        .font(.system(size: 12))
                    Text("Disc \(volume)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Theme.mutedForeground)
                .padding(.horizontal, 16)
                .padding(.top, volume == sortedVolumes.first ? 4 : 16)
                .padding(.bottom, 4)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                ForEach(Array(volumeTracks.enumerated()), id: \.element.id) { index, track in
                    let globalIndex = tracks.firstIndex(where: { $0.id == track.id }) ?? index
                    let queue = Array(tracks.dropFirst(globalIndex + 1))
                    let previous = Array(tracks.prefix(globalIndex))
                    TrackRow(
                        track: track, queue: queue, previousTracks: previous,
                        showCover: false, showIndex: track.trackNumber ?? (index + 1),
                        navigationPath: $navigationPath
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        } else {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                let queue = Array(tracks.dropFirst(index + 1))
                let previous = Array(tracks.prefix(index))
                TrackRow(
                    track: track, queue: queue, previousTracks: previous,
                    showCover: false, showIndex: track.trackNumber ?? (index + 1),
                    navigationPath: $navigationPath
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - Skeleton Track List

    @ViewBuilder
    private var skeletonTrackList: some View {
        let count = displayAlbum.numberOfTracks ?? 8
        let titleWidths: [CGFloat] = [160, 120, 180, 140, 100, 150, 130, 170, 110, 145, 155, 125]
        let subtitleWidths: [CGFloat] = [90, 110, 70, 100, 80, 95, 85, 105, 75, 115, 88, 98]
        ForEach(0..<min(count, 12), id: \.self) { index in
            HStack(spacing: 12) {
                Text("\(index + 1)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonPill(width: titleWidths[index], height: 14)
                    SkeletonPill(width: subtitleWidths[index], height: 12)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .shimmer()
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Data (cache-then-network)

    private func loadAlbum() async {
        // Phase 1: instant from cache
        let cacheKey = "album_\(album.id)"
        if let cached: AlbumDetail = CacheService.shared.get(forKey: cacheKey) {
            loadedAlbum = cached.album
            tracks = cached.tracks
            isLoading = false
        }

        // Phase 2: skip network if cache is valid (within user-configured maxAge) and complete
        if let age = CacheService.shared.age(forKey: cacheKey),
           age < CacheService.shared.maxAge,
           !tracks.isEmpty {
            return
        }

        // Phase 3: refresh from network (retry up to 3 times with backoff)
        let api = MonochromeAPI()
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                if attempt > 0 {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
                }
                let detail = try await api.fetchAlbum(id: album.id)
                loadedAlbum = detail.album
                tracks = detail.tracks
                lastError = nil
                break
            } catch {
                lastError = error
                print("[Album] Attempt \(attempt + 1) failed for album \(album.id): \(error.localizedDescription)")
            }
        }
        if let error = lastError {
            if tracks.isEmpty, let stale: AlbumDetail = CacheService.shared.get(forKey: cacheKey, ignoreExpiry: true) {
                loadedAlbum = stale.album
                tracks = stale.tracks
            }
            if tracks.isEmpty { print("[Album] All retries failed for album \(album.id): \(error.localizedDescription)") }
        }
        isLoading = false
    }
}
