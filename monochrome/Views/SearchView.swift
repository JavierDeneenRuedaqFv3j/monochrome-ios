import SwiftUI

struct SearchView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    @State private var searchText = ""
    @State private var searchResults: [Track] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Input
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.mutedForeground)
                        TextField("Rechercher des titres, albums, artistes...", text: $searchText)
                            .foregroundColor(Theme.foreground)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Theme.mutedForeground)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.input)
                    .cornerRadius(Theme.radiusMd)
                    .padding(16)
                    
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
                            .padding()
                    }
                    
                    if !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(searchResults) { track in
                                    TrackRow(track: track)
                                }
                            }
                            .padding(.horizontal, 16)
                            // Add extra padding at bottom to clear the mini player
                            .padding(.bottom, 80)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Recherche")
            .navigationBarHidden(true)
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        
        Task {
            do {
                searchResults = try await MonochromeAPI().searchTracks(query: searchText)
            } catch {
                // TODO: Handle error state in UI
            }
            isSearching = false
        }
    }
}

struct TrackRow: View {
    let track: Track
    @Environment(AudioPlayerService.self) private var audioPlayer
    
    var body: some View {
        Button(action: {
            Task {
                if let streamUrlStr = try? await MonochromeAPI().fetchStreamUrl(trackId: track.id),
                   let url = URL(string: streamUrlStr) {
                    await MainActor.run {
                        audioPlayer.play(
                            url: url,
                            title: track.title,
                            artist: track.artist?.name ?? "Unknown",
                            coverUrl: MonochromeAPI().getImageUrl(id: track.album?.cover)
                        )
                    }
                }
            }
        }) {
            HStack(spacing: 16) {
                AsyncImage(url: MonochromeAPI().getImageUrl(id: track.album?.cover)) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Theme.card)
                    }
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .foregroundColor(Theme.foreground)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(track.artist?.name ?? "Unknown Artist")
                        if let year = track.releaseYear {
                            Text("•")
                            Text(year)
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Theme.mutedForeground)
                    .lineLimit(1)
                }
                
                Spacer()
                
                Text(formatDuration(track.duration))
                    .font(.system(size: 14))
                    .foregroundColor(Theme.mutedForeground)
                    .frame(width: 50, alignment: .trailing)
                
                Image(systemName: "ellipsis")
                    .foregroundColor(Theme.mutedForeground)
                    .font(.system(size: 14))
                    .padding(.leading, 8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    SearchView()
        .environment(AudioPlayerService())
}
