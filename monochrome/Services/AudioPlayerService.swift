import Foundation
import AVFoundation
import MediaPlayer
import Observation

@Observable
class AudioPlayerService {
    var player: AVPlayer?
    var isPlaying: Bool = false
    var currentTrackTitle: String = "No Track"
    var currentArtistName: String = "Unknown Artist"
    var currentCoverUrl: URL? = nil
    
    // Playback state
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    private var timeObserverToken: Any?
    
    init() {
        setupRemoteCommandCenter()
    }
    
    func play(url: URL, title: String, artist: String, coverUrl: URL? = nil) {
        // Clean up previous observer if any
        removeTimeObserver()
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        player?.play()
        
        isPlaying = true
        currentTrackTitle = title
        currentArtistName = artist
        currentCoverUrl = coverUrl
        currentTime = 0
        duration = 0
        
        addTimeObserver()
        updateNowPlayingInfo()
        
        // Load duration asynchronously
        Task {
            if let durationSeconds = try? await asset.load(.duration).seconds, !durationSeconds.isNaN {
                await MainActor.run {
                    self.duration = durationSeconds
                    self.updateNowPlayingInfo()
                }
            }
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }
    
    func seek(to time: TimeInterval) {
        guard let customPlayer = player else { return }
        
        let targetTime = CMTime(seconds: time, preferredTimescale: 1000)
        customPlayer.seek(to: targetTime) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.togglePlayPause()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.togglePlayPause()
            return .success
        }
    }
    
    private func addTimeObserver() {
        guard let customPlayer = player else { return }
        
        // Notify every 0.1 seconds
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = customPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            self?.updateNowPlayingInfo() // Consider throttling this if it hits performance
        }
    }
    
    private func removeTimeObserver() {
        if let token = timeObserverToken, let customPlayer = player {
            customPlayer.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrackTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentArtistName
        
        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    deinit {
        removeTimeObserver()
    }
}
