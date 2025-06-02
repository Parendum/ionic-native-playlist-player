package com.parendum.nativeplaylistplayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer

class NativeAudioService : Service() {

    companion object {
        private const val TAG = "NativePlaylistPService"
        private const val CHANNEL_ID = "native_audio_notification_channel"
        private const val NOTIFICATION_ID = 1
    }

    private lateinit var player: ExoPlayer
    private var playlist: List<String> = listOf()

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service created")
        createNotificationChannel()

        // Initialize ExoPlayer
        player = ExoPlayer.Builder(this).build()
        player.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                sendPlaybackState()
            }

            override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                sendPlaybackState()
            }

            override fun onPlaybackStateChanged(state: Int) {
                sendPlaybackState()
            }
        })
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.i(TAG, "onStartCommand called, action = $action")

        when (action) {
            "ACTION_STOP" -> {
                stopPlayback()
                return START_NOT_STICKY
            }
            "ACTION_PAUSE" -> {
                pausePlayback()
                return START_STICKY
            }
            else -> {
                // Normal playback start
                val files = intent?.getStringArrayListExtra("playlist") ?: arrayListOf()
                playlist = files.toList()
                Log.i(TAG, "Playlist received: ${playlist.size} files")
                startPlayback()

                // Promote to foreground
                val notification = buildNotification()
                startForeground(NOTIFICATION_ID, notification)
            }
        }

        return START_STICKY // Tell system to restart if needed
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "Service destroyed")
        player.release()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // We won’t do bound service (yet)
    }

    private fun startPlayback() {
        player.clearMediaItems()

        for (filePath in playlist) {
            val mediaItem = MediaItem.fromUri(filePath)
            player.addMediaItem(mediaItem)
        }

        player.prepare()
        player.repeatMode = Player.REPEAT_MODE_ALL
        player.play()
        Log.i(TAG, "Playback started")
    }

    private fun stopPlayback() {
        Log.i(TAG, "stopPlayback() called")
        player.stop()
        stopForeground(true)
        stopSelf()
    }

    private fun pausePlayback() {
        Log.i(TAG, "pausePlayback() called")

        if (!player.isPlaying) {
            Log.i(TAG, "Setting player to play")
            player.play()
        } else {
            Log.i(TAG, "Setting player to pause")
            player.pause()
        }

        sendPlaybackState()
    }

    private fun buildNotification(): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Playing Audio")
            .setContentText("Your playlist is playing...")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Native Audio Playback",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun sendPlaybackState() {
        val intent = Intent("PLAYER_STATE_UPDATE")
        intent.putExtra("isPlaying", player.isPlaying)
        intent.putExtra("currentTrackIndex", player.currentMediaItemIndex)
        intent.putExtra("currentPosition", player.currentPosition / 1000) // in seconds
        intent.putExtra("duration", player.duration / 1000) // in seconds

        sendBroadcast(intent)
        Log.i(TAG, "sendPlaybackState() broadcast sent")
    }
}
