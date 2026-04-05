import SwiftUI

struct NowPlayingView: View {
    @Binding var expansion: CGFloat
    @Binding var navigationPath: CompatNavigationPath

    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @EnvironmentObject private var playbackProgress: PlaybackProgress
    @EnvironmentObject private var libraryManager: LibraryManager
    @EnvironmentObject private var downloadManager: DownloadManager
    @State private var showQueue = false
    @State private var isDraggingSlider = false
    @State private var localSeekValue: Double = 0
    @State private var artScale: CGFloat = 1.0

    private let screenW = UIScreen.main.bounds.width
    private let screenH = UIScreen.main.bounds.height
    private var safeT: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .compactMap { $0.keyWindow }
            .first?.safeAreaInsets.top) ?? 59
    }
    private var safeB: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .compactMap { $0.keyWindow }
            .first?.safeAreaInsets.bottom) ?? 34
    }

    var body: some View {
        let usable = screenH - safeT - safeB
        let padX: CGFloat = 28
        let artSize = min(screenW - padX * 2, usable * 0.40)

        ZStack {
            backgroundLayer

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Handle
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .frame(height: usable * 0.03)

                    // Top bar
                    topBar
                        .frame(height: usable * 0.06)

                    Color.clear.frame(height: usable * 0.025)

                    // Album art with scale animation
                    albumArt
                        .frame(width: artSize, height: artSize)
                        .scaleEffect(audioPlayer.isPlaying ? 1.0 : 0.92)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: audioPlayer.isPlaying)

                    Color.clear.frame(height: usable * 0.035)

                    // Track info
                    trackInfo
                        .frame(minHeight: usable * 0.07)

                    Color.clear.frame(height: usable * 0.02)

                    // Progress
                    progressBar
                        .frame(height: usable * 0.07)

                    Color.clear.frame(height: usable * 0.005)

                    // Controls
                    controls
                        .frame(height: usable * 0.11)

                    Color.clear.frame(height: usable * 0.015)

                    // Secondary controls
                    queueInfo
                        .frame(height: usable * 0.05)

                    // Lyrics
                    LyricsView()
                        .padding(.top, 40)
                        .padding(.bottom, safeB + 40)
                }
                .padding(.horizontal, padX)
                .padding(.top, safeT)
            }
        }
        .frame(width: screenW, height: screenH)
        .clipped()
        .onReceive(playbackProgress.$currentTime) { time in
            if !isDraggingSlider {
                localSeekValue = time
            }
        }
        .onAppear {
            localSeekValue = playbackProgress.currentTime
        }
        .sheet(isPresented: $showQueue) {
            QueueSheetView()
                .environmentObject(audioPlayer)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Theme.background
            if let coverUrl = audioPlayer.currentCoverUrl {
                CachedAsyncImage(url: coverUrl) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 100)
                            .brightness(-0.45)
                            .saturation(1.3)
                            .scaleEffect(1.6)
                    }
                }
            }
            // Gradient overlay for depth
            LinearGradient(
                colors: [.black.opacity(0.3), .clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: screenW, height: screenH)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    expansion = 0
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial.opacity(0.4))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("NOW PLAYING")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.5)
                if let album = audioPlayer.currentTrack?.album?.title {
                    Text(album)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Album Art

    private var albumArt: some View {
        CachedAsyncImage(url: audioPlayer.currentCoverUrl) { phase in
            if let image = phase.image {
                image.resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: Theme.radiusLg)
                    .fill(
                        LinearGradient(
                            colors: [Theme.card, Theme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.mutedForeground.opacity(0.3))
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
        .shadow(color: .black.opacity(0.6), radius: 40, y: 20)
        .onTapGesture {
            guard let album = audioPlayer.currentTrack?.album else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expansion = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                navigationPath.append(album)
            }
        }
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(audioPlayer.currentTrackTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let artist = audioPlayer.currentTrack?.artist {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            expansion = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            navigationPath.append(artist)
                        }
                    }) {
                        Text(audioPlayer.currentArtistName)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(audioPlayer.currentArtistName)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let track = audioPlayer.currentTrack {
                Button(action: { libraryManager.toggleFavorite(track: track) }) {
                    Image(systemName: libraryManager.isFavorite(trackId: track.id) ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(libraryManager.isFavorite(trackId: track.id) ? Theme.accent : .white.opacity(0.4))
                        .symbolEffect(.bounce, value: libraryManager.isFavorite(trackId: track.id))
                }
                .frame(width: 44, height: 44)

                downloadToggleButton(track: track)
            }
        }
    }

    @ViewBuilder
    private func downloadToggleButton(track: Track) -> some View {
        let isDownloaded = downloadManager.isDownloaded(track.id)
        let isDownloading = downloadManager.isDownloading(track.id)

        Button(action: {
            if isDownloaded {
                downloadManager.removeDownload(track.id)
            } else if !isDownloading {
                downloadManager.downloadTrack(track)
            }
        }) {
            if isDownloading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
                    .tint(.white)
            } else if isDownloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.accent)
            } else {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(width: 44, height: 44)
    }

    // MARK: - Progress

    private var progressBar: some View {
        VStack(spacing: 8) {
            // Custom progress track
            GeometryReader { geo in
                let progress = playbackProgress.duration > 0
                    ? (isDraggingSlider ? localSeekValue : playbackProgress.currentTime) / playbackProgress.duration
                    : 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .frame(height: isDraggingSlider ? 6 : 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progress), height: isDraggingSlider ? 6 : 4)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: isDraggingSlider ? 14 : 0, height: isDraggingSlider ? 14 : 0)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        .offset(x: max(0, geo.size.width * progress - 7))
                }
                .frame(height: 14)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingSlider = true
                            let ratio = max(0, min(1, value.location.x / geo.size.width))
                            localSeekValue = ratio * (playbackProgress.duration > 0 ? playbackProgress.duration : 1)
                        }
                        .onEnded { _ in
                            isDraggingSlider = false
                            audioPlayer.seek(to: localSeekValue)
                        }
                )
                .animation(.easeOut(duration: 0.15), value: isDraggingSlider)
            }
            .frame(height: 14)

            HStack {
                Text(formatTime(isDraggingSlider ? localSeekValue : playbackProgress.currentTime))
                Spacer()
                Text("-" + formatTime(max(0, playbackProgress.duration - (isDraggingSlider ? localSeekValue : playbackProgress.currentTime))))
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack {
            Spacer()

            Button(action: { audioPlayer.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 30))
                    .foregroundColor(audioPlayer.hasPreviousTrack ? .white : .white.opacity(0.2))
            }
            .disabled(!audioPlayer.hasPreviousTrack)

            Spacer()

            // Play/Pause with accent ring
            Button(action: { audioPlayer.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 68, height: 68)
                        .shadow(color: Theme.accent.opacity(0.3), radius: 20, y: 4)

                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
                        .offset(x: audioPlayer.isPlaying ? 0 : 2)
                }
            }

            Spacer()

            Button(action: { audioPlayer.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 30))
                    .foregroundColor(audioPlayer.hasNextTrack ? .white : .white.opacity(0.2))
            }
            .disabled(!audioPlayer.hasNextTrack)

            Spacer()
        }
    }

    // MARK: - Queue Info

    private var queueInfo: some View {
        HStack {
            Button(action: { audioPlayer.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(audioPlayer.isShuffled ? Theme.accent : .white.opacity(0.3))
            }
            .frame(width: 44, height: 44)

            Spacer()

            if !audioPlayer.queuedTracks.isEmpty {
                Button(action: { showQueue = true }) {
                    HStack(spacing: 4) {
                        Text("\(audioPlayer.queuedTracks.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("in queue")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.06))
                    .clipShape(Capsule())
                }
            }

            Spacer()

            Button(action: { audioPlayer.cycleRepeatMode() }) {
                Image(systemName: audioPlayer.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(audioPlayer.repeatMode != .off ? Theme.accent : .white.opacity(0.3))
            }
            .frame(width: 44, height: 44)

            Button(action: { showQueue = true }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(width: 44, height: 44)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time > 0 && !time.isNaN else { return "0:00" }
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
