import SwiftUI

struct MiniPlayerView: View {
    @Binding var expansion: CGFloat
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryManager.self) private var libraryManager

    @State private var swipeOffset: CGFloat = 0
    @State private var dragAxis: DragAxis = .undecided

    private enum DragAxis { case undecided, horizontal, vertical }

    var body: some View {
        VStack(spacing: 0) {
            // Track content with carousel swipe
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    // Previous track (slides in from left)
                    if swipeOffset > 0, let prev = audioPlayer.playHistory.last {
                        miniTrackRow(title: prev.title, artist: prev.artist?.name ?? "Unknown Artist",
                                     coverUrl: MonochromeAPI().getImageUrl(id: prev.album?.cover))
                            .offset(x: -w + swipeOffset)
                    }

                    // Current track (follows finger)
                    currentTrackRow
                        .offset(x: swipeOffset)

                    // Next track (slides in from right)
                    if swipeOffset < 0, let next = audioPlayer.queuedTracks.first {
                        miniTrackRow(title: next.title, artist: next.artist?.name ?? "Unknown Artist",
                                     coverUrl: MonochromeAPI().getImageUrl(id: next.album?.cover))
                            .offset(x: w + swipeOffset)
                    }
                }
                .clipped()
            }
            .frame(height: 56)

            // Progress bar
            GeometryReader { geo in
                let progress = audioPlayer.duration > 0 ? (audioPlayer.currentTime / audioPlayer.duration) : 0
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.border.opacity(0.3))
                    Rectangle().fill(Theme.foreground)
                        .frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 2)
        }
        .background(Theme.secondary.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)

                    if dragAxis == .undecided && (dx > 12 || dy > 12) {
                        dragAxis = dx > dy ? .horizontal : .vertical
                    }

                    switch dragAxis {
                    case .horizontal:
                        // Don't allow swiping if no track in that direction
                        let raw = value.translation.width
                        if raw > 0 && audioPlayer.playHistory.isEmpty { return }
                        if raw < 0 && audioPlayer.queuedTracks.isEmpty { return }
                        swipeOffset = raw
                    case .vertical:
                        let progress = -value.translation.height / UIScreen.main.bounds.height
                        expansion = max(0, min(1, progress))
                    case .undecided:
                        break
                    }
                }
                .onEnded { value in
                    let lockedAxis = dragAxis
                    dragAxis = .undecided

                    if lockedAxis == .horizontal {
                        let dx = value.translation.width
                        let velocityX = value.predictedEndTranslation.width - dx
                        let screenW = UIScreen.main.bounds.width

                        // Threshold: 30% of width or fast velocity
                        if (abs(dx) > screenW * 0.3 || abs(velocityX) > 400) {
                            // Complete the slide
                            let goNext = dx < 0
                            let target: CGFloat = goNext ? -screenW : screenW

                            withAnimation(.easeOut(duration: 0.2)) {
                                swipeOffset = target
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if goNext {
                                    audioPlayer.nextTrack()
                                } else {
                                    audioPlayer.previousTrack()
                                }
                                swipeOffset = 0
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                swipeOffset = 0
                            }
                        }
                    } else if lockedAxis == .vertical {
                        let dy = value.translation.height
                        let velocity = -(value.predictedEndTranslation.height - dy)
                        let progress = -dy / UIScreen.main.bounds.height

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            if progress > 0.25 || velocity > 600 {
                                expansion = 1
                            } else {
                                expansion = 0
                            }
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            swipeOffset = 0
                            expansion = 0
                        }
                    }
                }
        )
    }

    // MARK: - Current track row (with buttons)

    private var currentTrackRow: some View {
        HStack(spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    expansion = 1
                }
            }) {
                HStack(spacing: 10) {
                    AsyncImage(url: audioPlayer.currentCoverUrl) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(audioPlayer.currentTrackTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.foreground)
                            .lineLimit(1)
                        Text(audioPlayer.currentArtistName)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.mutedForeground)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if let track = audioPlayer.currentTrack {
                Button(action: { libraryManager.toggleFavorite(track: track) }) {
                    Image(systemName: libraryManager.isFavorite(trackId: track.id) ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(libraryManager.isFavorite(trackId: track.id) ? Theme.foreground : Theme.mutedForeground)
                }
                .buttonStyle(.plain)
            }

            Button(action: { audioPlayer.togglePlayPause() }) {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.foreground)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Generic track row for next/previous preview

    private func miniTrackRow(title: String, artist: String, coverUrl: URL?) -> some View {
        HStack(spacing: 10) {
            AsyncImage(url: coverUrl) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.foreground)
                    .lineLimit(1)
                Text(artist)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.mutedForeground)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
