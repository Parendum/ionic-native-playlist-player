import Foundation
import AVFoundation
import Capacitor
import MediaPlayer

@objc public class NativePlaylistPlayer: NSObject {
    private let tag = "NativePlaylistPlayer"
    private var playlist: [String] = []
    private var durationSeconds: Int = 0
    private var languageCode: String = "en"
    private var audioPlayer: AVAudioPlayer?
    private var currentTrackIndex: Int = 0
    private var isPlaying: Bool = false
    private var isPaused: Bool = false
    private var isLooping: Bool = false
    private var elapsedSeconds: Int = 0
    private var timer: Timer?
    private var statusTimer: Timer?
    private var volumeTimer: Timer?

    // Volume limiting
    private let maxVolumePercentage: Float = 0.6 // 60%
    private var volumeView: MPVolumeView?

    // Weak reference to plugin for callbacks
    weak var plugin: NativePlaylistPlayerPlugin?

    override init() {
        super.init()
        setupAudioSession()
        setupVolumeMonitoring()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            CAPLog.print("[\(tag)] Audio session configured for background playback")
        } catch {
            CAPLog.print("[\(tag)] Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func setupVolumeMonitoring() {
        // Create a hidden MPVolumeView to access volume controls
        volumeView = MPVolumeView(frame: CGRect.zero)
        volumeView?.showsVolumeSlider = false
        volumeView?.showsRouteButton = false
        volumeView?.isHidden = true

        // Add volume change notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(volumeDidChange),
            name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )

        CAPLog.print("[\(tag)] Volume monitoring setup completed")
    }

    @objc private func volumeDidChange(notification: NSNotification) {
        // This will be called whenever system volume changes
        checkAndLimitVolume()
    }

    @objc public func setPlaylist(_ list: [String], _ durationSeconds: Int, _ languageCode: String) {
        CAPLog.print("[\(tag)] setPlaylist() called with \(list.count) items and durationSeconds = \(durationSeconds)")
        self.playlist = list
        self.durationSeconds = durationSeconds
        self.languageCode = languageCode

        for (index, file) in playlist.enumerated() {
            CAPLog.print("[\(tag)]   [\(index)] \(file)")
        }
    }

    @objc public func getPlaylist() -> [String] {
        CAPLog.print("[\(tag)] getPlaylist() called, returning \(playlist.count) items")
        return playlist
    }

    @objc public func getDurationSeconds() -> Int {
        CAPLog.print("[\(tag)] getDurationSeconds() called, returning \(durationSeconds)")
        return durationSeconds
    }

    @objc public func isServiceRunning() -> Bool {
        return isPlaying || isPaused
    }

    @objc public func play() {
        CAPLog.print("[\(tag)] play() called")
        guard !playlist.isEmpty else {
            CAPLog.print("[\(tag)] Playlist is empty, cannot start playback")
            return
        }

        currentTrackIndex = 0
        elapsedSeconds = 0
        startPlayback()
        startTimers()
    }

    @objc public func togglePause() {
        CAPLog.print("[\(tag)] togglePause() called")

        if isPlaying {
            pausePlayback()
        } else if isPaused {
            resumePlayback()
        } else {
            CAPLog.print("[\(tag)] No active playback to toggle")
        }

        sendPlaybackState()
    }

    @objc public func toggleLoop() {
        CAPLog.print("[\(tag)] toggleLoop() called")
        isLooping = !isLooping
        CAPLog.print("[\(tag)] Loop mode set to \(isLooping)")
        sendPlaybackState()
    }

    @objc public func stop() {
        CAPLog.print("[\(tag)] stop() called")
        stopPlayback()
        sendPlaybackState()
    }

    private func startPlayback() {
        guard currentTrackIndex < playlist.count else {
            CAPLog.print("[\(tag)] Invalid track index: \(currentTrackIndex)")
            return
        }

        let filePath = playlist[currentTrackIndex]
        CAPLog.print("[\(tag)] Attempting to play file: \(filePath)")

        // More robust URL handling
        var url: URL

        // Check if it's already a complete file URL
        if filePath.hasPrefix("file://") {
            url = URL(string: filePath)!
        }
        // Check if it starts with a slash (absolute path)
        else if filePath.hasPrefix("/") {
            url = URL(fileURLWithPath: filePath)
        }
        // Assume it's a relative path from app bundle
        else {
            // Try to find in main bundle first
            let pathExtension = URL(fileURLWithPath: filePath).pathExtension
            let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent

            if let bundlePath = Bundle.main.path(forResource: fileName, ofType: pathExtension) {
                url = URL(fileURLWithPath: bundlePath)
            } else {
                // Try as relative path from Documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                url = documentsPath.appendingPathComponent(filePath)
            }
        }

        // Check if file exists
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            CAPLog.print("[\(tag)] File does not exist at path: \(url.path)")

            // List files in directory for debugging
            let directory = url.deletingLastPathComponent()
            do {
                let files = try fileManager.contentsOfDirectory(atPath: directory.path)
                CAPLog.print("[\(tag)] Files in directory \(directory.path): \(files)")
            } catch {
                CAPLog.print("[\(tag)] Could not list directory contents: \(error)")
            }
            return
        }

        // Check file size
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            if fileSize == 0 {
                CAPLog.print("[\(tag)] File is empty")
                return
            }
        } catch {
            CAPLog.print("[\(tag)] Could not get file attributes: \(error)")
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self

            audioPlayer?.prepareToPlay()
            let success = audioPlayer?.play() ?? false

            if success {
                isPlaying = true
                isPaused = false
                CAPLog.print("[\(tag)] Started playing: \(filePath)")
                sendPlaybackState()
            } else {
                CAPLog.print("[\(tag)] Failed to start playback")
            }
        } catch {
            CAPLog.print("[\(tag)] Failed to create audio player: \(error.localizedDescription)")

            // More detailed error information
            if let nsError = error as NSError? {
                CAPLog.print("[\(tag)] Error domain: \(nsError.domain)")
                CAPLog.print("[\(tag)] Error code: \(nsError.code)")
                CAPLog.print("[\(tag)] Error userInfo: \(nsError.userInfo)")
            }
        }
    }

    private func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        isPaused = true
        CAPLog.print("[\(tag)] Playback paused")
    }

    private func resumePlayback() {
        audioPlayer?.play()
        isPlaying = true
        isPaused = false
        CAPLog.print("[\(tag)] Playback resumed")
    }

    private func stopPlayback() {
        stopTimers()
        audioPlayer?.stop()
        sendPlaybackState()
        audioPlayer = nil
        isPlaying = false
        isPaused = false
        currentTrackIndex = 0
        elapsedSeconds = 0
        CAPLog.print("[\(tag)] Playback stopped")
    }

    private func playNextTrack() {
        guard !playlist.isEmpty else { return }

        currentTrackIndex = (currentTrackIndex + 1) % playlist.count
        startPlayback()
    }

    private func startTimers() {
        CAPLog.print("[\(tag)] startTimers() called on thread: \(Thread.current)")

        // Always create and schedule timers on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            CAPLog.print("[\(self.tag)] Creating timers on main thread")

            if timer != nil || statusTimer != nil || volumeTimer != nil {
                CAPLog.print("[\(self.tag)] Warning: Timers already exist, skipping timer creation")
                return
            }

            // Timer for elapsed seconds
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }

                if self.isPlaying {
                    self.elapsedSeconds += 1
                }

                if self.elapsedSeconds >= self.durationSeconds {
                    if self.isLooping {
                        self.elapsedSeconds = 0
                        self.audioPlayer?.currentTime = 0
                    } else {
                        self.stopPlayback()
                    }
                }
            }

            // Timer for status updates
            self.statusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.sendPlaybackState()
            }

            // Timer for volume monitoring (every 200ms like Android)
            self.volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.checkAndLimitVolume()
            }

            CAPLog.print("[\(self.tag)] Timers created and scheduled on main thread")
            CAPLog.print("[\(self.tag)] Volume monitoring started")
        }
    }

    private func stopTimers() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.timer?.invalidate()
            self.timer = nil
            self.statusTimer?.invalidate()
            self.statusTimer = nil
            self.volumeTimer?.invalidate()
            self.volumeTimer = nil
            CAPLog.print("[\(self.tag)] Timers stopped on main thread")
            CAPLog.print("[\(self.tag)] Volume monitoring stopped")
        }
    }

    private func checkAndLimitVolume() {
        // Only limit volume when actually playing audio
        guard isPlaying || isPaused else { return }

        let currentVolume = AVAudioSession.sharedInstance().outputVolume

        if currentVolume > maxVolumePercentage {
            // Find the volume slider in MPVolumeView
            guard let volumeView = volumeView else { return }

            for subview in volumeView.subviews {
                if let slider = subview as? UISlider {
                    DispatchQueue.main.async {
                        slider.setValue(self.maxVolumePercentage, animated: false)
                        CAPLog.print("[\(self.tag)] Volume limited from \(currentVolume) to \(self.maxVolumePercentage)")
                    }
                    break
                }
            }
        }
    }

    private func sendPlaybackState() {
        let data: [String: Any] = [
            "isPlaying": isPlaying,
            "currentTrackIndex": currentTrackIndex,
            "durationSeconds": durationSeconds,
            "elapsedSeconds": elapsedSeconds,
            "isLooping": isLooping
        ]

        // Direct call to plugin instead of NotificationCenter
        plugin?.sendPlayerStateUpdate(data: data)
    }

    deinit {
        // Clean up volume monitoring
        NotificationCenter.default.removeObserver(self)
        stopTimers()
    }
}

// MARK: - AVAudioPlayerDelegate
extension NativePlaylistPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            playNextTrack()
        }
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        CAPLog.print("[\(tag)] Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
        playNextTrack()
    }
}
