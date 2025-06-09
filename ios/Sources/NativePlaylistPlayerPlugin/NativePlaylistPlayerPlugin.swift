import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(NativePlaylistPlayerPlugin)
public class NativePlaylistPlayerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativePlaylistPlayerPlugin"
    public let jsName = "NativePlaylistPlayer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPlaylist", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPlaylist", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "play", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "togglePause", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "toggleLoop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isPlaying", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = NativePlaylistPlayer()
    private let tag = "NativePlaylistPPlugin"

    public override func load() {
        super.load()
        // Set the plugin reference for callbacks
        implementation.plugin = self
    }

    // Method to send player state updates directly to JS
    func sendPlayerStateUpdate(data: [String: Any]) {
        let isPlaying = data["isPlaying"] as? Bool ?? false
        let currentTrackIndex = data["currentTrackIndex"] as? Int ?? 0
        let durationSeconds = data["durationSeconds"] as? Int ?? 0
        let elapsedSeconds = data["elapsedSeconds"] as? Int ?? 0
        let isLooping = data["isLooping"] as? Bool ?? false

        if (durationSeconds == 0 && elapsedSeconds == 0) {
            return
        }

        CAPLog.print("[\(tag)] Sending player state: isPlaying=\(isPlaying), currentTrackIndex=\(currentTrackIndex), durationSeconds=\(durationSeconds), elapsedSeconds=\(elapsedSeconds), isLooping=\(isLooping)")

        notifyListeners("playerStateUpdate", data: data)
    }

    @objc func setPlaylist(_ call: CAPPluginCall) {
        CAPLog.print("[\(tag)] setPlaylist()")
        guard let playlistArray = call.getArray("playlist") as? [String] else {
            call.reject("Invalid playlist parameter")
            return
        }

        guard let durationSeconds = call.getInt("duration_seconds") else {
            call.reject("Invalid duration_seconds parameter")
            return
        }

        let languageCode = call.getString("language_code") ?? "en"

        implementation.setPlaylist(playlistArray, durationSeconds, languageCode)
        call.resolve()
    }

    @objc func getPlaylist(_ call: CAPPluginCall) {
        CAPLog.print("[\(tag)] getPlaylist()")
        let playlist = implementation.getPlaylist()
        let durationSeconds = implementation.getDurationSeconds()

        call.resolve([
            "playlist": playlist,
            "duration_seconds": durationSeconds
        ])
    }

    @objc func play(_ call: CAPPluginCall) {
        CAPLog.print("[\(tag)] play()")
        implementation.play()
        call.resolve()
    }

    @objc func togglePause(_ call: CAPPluginCall) {
        CAPLog.print("[\(tag)] togglePause()")
        implementation.togglePause()
        call.resolve()
    }

    @objc func toggleLoop(_ call: CAPPluginCall) {
        CAPLog.print("[\(tag)] toggleLoop()")
        implementation.toggleLoop()
        call.resolve()
    }

    @objc func stop(_ call: CAPPluginCall) {
        CAPLog.print("[\(tag)] stop()")
        implementation.stop()
        call.resolve()
    }

    @objc func isPlaying(_ call: CAPPluginCall) {
        CAPLog.print("[\(tag)] isPlaying()")
        let isRunning = implementation.isServiceRunning()

        CAPLog.print("[\(tag)] isPlaying: \(isRunning)")
        call.resolve([
            "isPlaying": isRunning
        ])
    }
}
