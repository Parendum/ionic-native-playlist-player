package com.parendum.nativeplaylistplayer

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission


@CapacitorPlugin(
    name = "NativePlaylistPlayer",
    permissions = [
        Permission(
            alias = "Service",
            strings = [Manifest.permission.FOREGROUND_SERVICE]
        ),
        Permission(
            alias = "MediaService",
            strings = [Manifest.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK]
        ),
        Permission(
            alias = "MediaNotification",
            strings = [Manifest.permission.POST_NOTIFICATIONS]
        ),
    ]
)
class NativePlaylistPlayerPlugin : Plugin() {

    companion object {
        private const val TAG = "NativePlaylistPPlugin"
    }

    private lateinit var implementation: NativePlaylistPlayer
    private var playerStateReceiver: BroadcastReceiver? = null

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun load() {
        super.load()

        implementation = NativePlaylistPlayer(context)

        playerStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "PLAYER_STATE_UPDATE") {
                    val isPlaying = intent.getBooleanExtra("isPlaying", false)
                    val currentTrackIndex = intent.getIntExtra("currentTrackIndex", 0)
                    val durationSeconds = intent.getIntExtra("durationSeconds", 0)
                    val elapsedSeconds = intent.getIntExtra("elapsedSeconds", 0)

                    Log.i(TAG,
                        "Received player state: isPlaying=$isPlaying, currentTrackIndex=$currentTrackIndex, durationSeconds=$durationSeconds, elapsedSeconds=$elapsedSeconds")

                    // Fire JS event:
                    val ret = JSObject()
                    ret.put("isPlaying", isPlaying)
                    ret.put("currentTrackIndex", currentTrackIndex)
                    ret.put("durationSeconds", durationSeconds)
                    ret.put("elapsedSeconds", elapsedSeconds)

                    notifyListeners("playerStateUpdate", ret)
                }
            }
        }

        val filter = IntentFilter("PLAYER_STATE_UPDATE")

        context.applicationContext.registerReceiver(playerStateReceiver, filter, Context.RECEIVER_EXPORTED)
    }

    override fun handleOnDestroy() {
        super.handleOnDestroy()

        val appContext = context.applicationContext

        Log.i(TAG, "Plugin destroyed, unregistering playerStateReceiver")

        playerStateReceiver?.let {
            appContext.unregisterReceiver(it)
        }
    }


    @PluginMethod
    fun echo(call: PluginCall) {
        Log.i(TAG, "echo()")
        val value = call.getString("value") ?: ""

        val ret = JSObject()
        ret.put("value", implementation.echo(value))
        call.resolve(ret)
    }

    @PluginMethod
    fun setPlaylist(call: PluginCall) {
        Log.i(TAG, "setPlaylist()")
        val filesArray = call.getArray("playlist")
        val durationSeconds = call.getInt("duration_seconds")
        val languageCode = call.getString("language_code", "en")
        val filesList = mutableListOf<String>()

        filesArray?.let {
            for (i in 0 until it.length()) {
                val filePath = it.getString(i)
                if (filePath != null) {
                    filesList.add(filePath)
                    Log.i("NativePlaylistPlayer", "Added to playlist: $filePath")
                }
            }
        }

        implementation.setPlaylist(filesList, durationSeconds!!, languageCode!!)
        call.resolve()
    }

    @PluginMethod
    fun getPlaylist(call: PluginCall) {
        Log.i(TAG, "getPlaylist()")
        val playlist = implementation.getPlaylist()
        val durationSeconds = implementation.getDurationSeconds()
        val jsArray = JSArray(playlist)

        val ret = JSObject()
        ret.put("playlist", jsArray)
        ret.put("duration_seconds", durationSeconds)
        call.resolve(ret)
    }

    @PluginMethod
    fun play(call: PluginCall) {
        Log.i(TAG, "play()")

        this.implementation.play()

        call.resolve()
    }

    @PluginMethod
    fun pause(call: PluginCall) {
        Log.i(TAG, "pause()")

        this.implementation.pause()

        call.resolve()
    }

    @PluginMethod
    fun stop(call: PluginCall) {
        Log.i(TAG, "stop()")

        this.implementation.stop()

        call.resolve()
    }
}
