import SwiftUI

struct QueueSheetView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                List {
                    // Now Playing
                    if let current = audioPlayer.currentTrack {
                        Section {
                            trackRow(
                                title: current.title,
                                artist: current.artist?.name ?? "Unknown Artist",
                                coverUrl: MonochromeAPI().getImageUrl(id: current.album?.cover, size: 80),
                                duration: current.duration,
                                isPlaying: true
                            )
                            .listRowBackground(Color.white.opacity(0.05))
                        } header: {
                            Text("Now Playing")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .textCase(nil)
                        }
                    }

                    // Next Up
                    if !audioPlayer.queuedTracks.isEmpty {
                        Section {
                            ForEach(Array(audioPlayer.queuedTracks.enumerated()), id: \.element.id) { index, track in
                                trackRow(
                                    title: track.title,
                                    artist: track.artist?.name ?? "Unknown Artist",
                                    coverUrl: MonochromeAPI().getImageUrl(id: track.album?.cover, size: 80),
                                    duration: track.duration,
                                    isPlaying: false
                                )
                                .listRowBackground(Theme.background)
                            }
                            .onDelete { offsets in
                                for index in offsets.sorted().reversed() {
                                    audioPlayer.removeFromQueue(at: index)
                                }
                            }
                            .onMove { source, destination in
                                audioPlayer.moveInQueue(from: source, to: destination)
                            }
                        } header: {
                            HStack {
                                Text("Next Up")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .textCase(nil)
                                Spacer()
                                Text("\(audioPlayer.queuedTracks.count) track\(audioPlayer.queuedTracks.count > 1 ? "s" : "")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, $editMode)
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(editMode == .active ? "Done" : "Edit") {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
    }

    private func trackRow(title: String, artist: String, coverUrl: URL?, duration: Int, isPlaying: Bool) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: coverUrl) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.card)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: isPlaying ? .semibold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(artist)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Text(formatDuration(duration))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
