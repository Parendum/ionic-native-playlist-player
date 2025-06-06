package com.parendum.nativeplaylistplayer

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class NativePlaylistPlayer(private val context: android.content.Context) {

    companion object {
        private const val TAG = "NativePlaylistPlayer"
    }

    private var playlist = mutableListOf<String>()
    private var durationSeconds: Int = 0
    private var languageCode: String = "en"

    fun echo(value: String): String {
        Log.i(TAG, "echo() called with value: $value")
        return value
    }

    fun setPlaylist(list: List<String>, durationSeconds: Int, languageCode: String) {
        Log.i(TAG, "setPlaylist() called with ${list.size} items and durationSeconds = $durationSeconds")
        this.playlist = list.toMutableList()
        this.durationSeconds = durationSeconds
        this.languageCode = languageCode

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

    fun isServiceRunning(): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        for (service in activityManager.getRunningServices(Integer.MAX_VALUE)) {
            if (NativeAudioService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }

    fun play() {
        val context = this.context
        val intent = Intent(context, NativeAudioService::class.java)
        val playList = this.getPlaylist()
        val durationSeconds = this.getDurationSeconds()

        intent.putStringArrayListExtra("playlist", ArrayList(playList))
        intent.putExtra("duration_seconds", durationSeconds)
        intent.putExtra("language_code", languageCode)
        Log.i(TAG, "Starting NativeAudioService with ${playList.size} items for $durationSeconds seconds")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun pause() {
        if (!isServiceRunning()) {
            Log.w(TAG, "Service is not running, cannot pause")
            return
        }

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
        if (!isServiceRunning()) {
            Log.w(TAG, "Service is not running, cannot stop")
            return
        }

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
