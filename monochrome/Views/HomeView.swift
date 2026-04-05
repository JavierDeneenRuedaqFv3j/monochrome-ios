import SwiftUI

struct HomeView: View {
    @Binding var navigationPath: CompatNavigationPath
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @EnvironmentObject private var libraryManager: LibraryManager

    @State private var appeared = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 { return "Late night" }
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 { return "moon.stars.fill" }
        if hour < 12 { return "sun.horizon.fill" }
        if hour < 18 { return "sun.max.fill" }
        return "moon.fill"
    }

    var body: some View {
        List {
            homeContent
        }
        .listStyle(.plain)
        .compatScrollContentBackground(false)
        .background(Theme.background)
        .environment(\.defaultMinListRowHeight, 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        Group {
            // Greeting header with icon
            HStack(spacing: 10) {
                Image(systemName: greetingIcon)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.accent)

                Text(greeting)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.foreground)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)

            // Quick stats pill
            if audioPlayer.currentTrack != nil || !libraryManager.favoriteTracks.isEmpty {
                HStack(spacing: 12) {
                    if !libraryManager.favoriteTracks.isEmpty {
                        StatPill(icon: "heart.fill", value: "\(libraryManager.favoriteTracks.count)", label: "liked")
                    }
                    if !audioPlayer.playHistory.isEmpty {
                        StatPill(icon: "clock.fill", value: "\(audioPlayer.playHistory.count)", label: "played")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }

            if !audioPlayer.playHistory.isEmpty || audioPlayer.currentTrack != nil {
                recentlyPlayed
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 28, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            if !libraryManager.favoriteTracks.isEmpty {
                favoritesSection
            }

            if audioPlayer.playHistory.isEmpty && audioPlayer.currentTrack == nil && libraryManager.favoriteTracks.isEmpty {
                emptyState
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Color.clear.frame(height: 100)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Theme.accent.opacity(0.05))
                    .frame(width: 140, height: 140)
                Image(systemName: "waveform")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Theme.accent.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("Your music awaits")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.foreground)
                Text("Search for an artist or track to begin")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Recently Played

    private var recentlyPlayed: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recently played", icon: "clock.arrow.circlepath")
                .padding(.horizontal, 20)

            let recentTracks = recentTracksList
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(Array(recentTracks.prefix(6).enumerated()), id: \.element.id) { index, track in
                    RecentTrackCard(track: track, isFirst: index == 0) {
                        audioPlayer.play(track: track)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var recentTracksList: [Track] {
        var tracks: [Track] = []
        if let current = audioPlayer.currentTrack {
            tracks.append(current)
        }
        for track in audioPlayer.playHistory.reversed() {
            if !tracks.contains(where: { $0.id == track.id }) {
                tracks.append(track)
            }
        }
        return tracks
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        Group {
            Section {
                ForEach(Array(libraryManager.favoriteTracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                    let queue = Array(libraryManager.favoriteTracks.dropFirst(index + 1))
                    let previous = Array(libraryManager.favoriteTracks.prefix(index))
                    TrackRow(track: track, queue: queue, previousTracks: previous, showCover: true, navigationPath: $navigationPath)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            } header: {
                HStack(spacing: 8) {
                    SectionHeader(title: "Your favorites", icon: "heart.fill")

                    Spacer()

                    Text("\(libraryManager.favoriteTracks.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accentSubtle)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 14)
                .background(Theme.background)
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 7) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accent)
            }
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Theme.foreground)
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(Theme.accent)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.foreground)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.mutedForeground)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.secondary)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Theme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Recent Track Card

struct RecentTrackCard: View {
    let track: Track
    var isFirst: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                CachedAsyncImage(url: MonochromeAPI().getImageUrl(id: track.album?.cover)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(
                            LinearGradient(
                                colors: [Theme.card, Theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
                .frame(width: 52, height: 52)
                .clipped()

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.foreground)
                        .lineLimit(1)

                    if let artist = track.artist?.name {
                        Text(artist)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.mutedForeground)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)

                Spacer()
            }
            .frame(height: 52)
            .background(Theme.secondary.opacity(isFirst ? 0.9 : 0.5))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMd)
                    .stroke(isFirst ? Theme.accent.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CompatNavigationView {
        HomeView(navigationPath: .constant(CompatNavigationPath()))
    }
    .environmentObject(AudioPlayerService())
    .environmentObject(LibraryManager.shared)
    .environmentObject(DownloadManager.shared)
}
