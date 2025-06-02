package com.parendum.nativeplaylistplayer

import android.content.Intent
import android.os.Build
import android.util.Log

class NativePlaylistPlayer(private val context: android.content.Context) {

    companion object {
        private const val TAG = "NativePlaylistPlayer"
    }

    private var playlist = mutableListOf<String>()
    private var durationSeconds: Int = 0

    fun echo(value: String): String {
        Log.i(TAG, "echo() called with value: $value")
        return value
    }

    fun setPlaylist(list: List<String>, durationSeconds: Int) {
        Log.i(TAG, "setPlaylist() called with ${list.size} items and durationSeconds = $durationSeconds")
        this.playlist = list.toMutableList()
        this.durationSeconds = durationSeconds

        for ((index, file) in playlist.withIndex()) {
            Log.i(TAG, "  [$index] $file")
        }
    }

    fun getPlaylist(): List<String> {
        Log.i(TAG, "getPlaylist() called, returning ${playlist.size} items")
        return this.playlist.toList()
    }

    fun getDurationSeconds(): Int {
        Log.i(TAG, "getDurationSeconds() called, returning $durationSeconds")
        return durationSeconds
    }

    fun play() {
        val context = this.context
        val intent = Intent(context, NativeAudioService::class.java)
        val playList = this.getPlaylist()
        val durationSeconds = this.getDurationSeconds()

        intent.putStringArrayListExtra("playlist", ArrayList(playList))
        intent.putExtra("duration_seconds", durationSeconds)
        Log.i(TAG, "Starting NativeAudioService with ${playList.size} items for $durationSeconds seconds")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun pause() {
        val intent = Intent(context, NativeAudioService::class.java)
        intent.action = "ACTION_PAUSE"

        Log.i(TAG, "Sending ACTION_PAUSE to NativeAudioService")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun stop() {
        val intent = Intent(context, NativeAudioService::class.java)
        intent.action = "ACTION_STOP"

        Log.i(TAG, "Sending ACTION_STOP to NativeAudioService")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }
}
