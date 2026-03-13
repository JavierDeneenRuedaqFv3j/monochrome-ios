import SwiftUI

struct UserPlaylistDetailView: View {
    let playlistId: String
    @Binding var navigationPath: NavigationPath
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(PlaylistManager.self) private var playlistManager

    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false

    private var playlist: UserPlaylist? {
        playlistManager.userPlaylists.first { $0.id == playlistId }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let playlist = playlist {
                List {
                    playlistHeader(playlist)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                    if playlist.tracks.isEmpty {
                        Text("No tracks yet")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.mutedForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(Array(playlist.tracks.enumerated()), id: \.element.id) { index, track in
                            let queue = Array(playlist.tracks.dropFirst(index + 1))
                            let previous = Array(playlist.tracks.prefix(index))
                            HStack(spacing: 0) {
                                TrackRow(track: track, queue: queue, previousTracks: previous, showCover: true, navigationPath: $navigationPath)

                                Button {
                                    withAnimation {
                                        playlistManager.removeTrack(track.id, from: playlistId)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Theme.mutedForeground.opacity(0.5))
                                }
                                .buttonStyle(.borderless)
                                .padding(.trailing, 16)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                    }

                    Spacer(minLength: 120)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 0)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Rename Playlist", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if !renameText.trimmingCharacters(in: .whitespaces).isEmpty {
                    playlistManager.renamePlaylist(id: playlistId, name: renameText.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        .alert("Delete Playlist?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                playlistManager.deletePlaylist(id: playlistId)
                navigationPath.removeLast()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func playlistHeader(_ playlist: UserPlaylist) -> some View {
        VStack(spacing: 16) {
            // Cover
            playlistCover(playlist)
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
                .padding(.top, 16)

            // Title
            Text(playlist.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.foreground)
                .multilineTextAlignment(.center)

            // Info
            HStack(spacing: 8) {
                Label(playlist.isPublic ? "Public" : "Private", systemImage: playlist.isPublic ? "globe" : "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.mutedForeground)

                Text("\(playlist.numberOfTracks) track\(playlist.numberOfTracks == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.mutedForeground)
            }

            if !playlist.description.isEmpty {
                Text(playlist.description)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action buttons
            HStack(spacing: 20) {
                // Visibility toggle
                Button {
                    playlistManager.togglePlaylistVisibility(id: playlistId)
                } label: {
                    Image(systemName: playlist.isPublic ? "globe" : "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.foreground)
                        .frame(width: 44, height: 44)
                        .background(Theme.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                // Shuffle
                Button {
                    guard !playlist.tracks.isEmpty else { return }
                    let shuffled = playlist.tracks.shuffled()
                    audioPlayer.play(track: shuffled[0], queue: Array(shuffled.dropFirst()))
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.foreground)
                        .frame(width: 44, height: 44)
                        .background(Theme.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                // Play
                Button {
                    guard !playlist.tracks.isEmpty else { return }
                    audioPlayer.play(track: playlist.tracks[0], queue: Array(playlist.tracks.dropFirst()))
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.background)
                        .frame(width: 52, height: 52)
                        .background(Theme.foreground)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                // Rename
                Button {
                    renameText = playlist.name
                    showRenameAlert = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.foreground)
                        .frame(width: 44, height: 44)
                        .background(Theme.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                // Delete
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(Theme.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cover

    @ViewBuilder
    private func playlistCover(_ playlist: UserPlaylist) -> some View {
        if !playlist.cover.isEmpty {
            AsyncImage(url: MonochromeAPI().getImageUrl(id: playlist.cover)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    coverPlaceholder
                }
            }
        } else if playlist.images.count >= 4 {
            // 4-image collage
            let size: CGFloat = 100
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    coverImage(playlist.images[0], size: size)
                    coverImage(playlist.images[1], size: size)
                }
                HStack(spacing: 0) {
                    coverImage(playlist.images[2], size: size)
                    coverImage(playlist.images[3], size: size)
                }
            }
        } else if let first = playlist.images.first {
            AsyncImage(url: MonochromeAPI().getImageUrl(id: first)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    coverPlaceholder
                }
            }
        } else {
            coverPlaceholder
        }
    }

    private func coverImage(_ id: String, size: CGFloat) -> some View {
        AsyncImage(url: MonochromeAPI().getImageUrl(id: id)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Rectangle().fill(Theme.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipped()
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8).fill(Theme.card)
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.mutedForeground.opacity(0.3))
            )
    }
}
