package wao.flutter.application.project.messaging_configuration

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import androidx.core.content.ContextCompat.getSystemService
import android.os.PowerManager

class FirebaseBroadcastReceiver : BroadcastReceiver() {
    private var wakeLock: PowerManager.WakeLock? = null
    override fun onReceive(context: Context, intent: Intent) {
        acquireWakeLock(context)
        val sharePref: SharePref = SharePref.getInstance(context)
        val value:String = sharePref.getData(UtilProject.key)
        if(value != "") {
            try {
                AudioPlayer().playAudio(context, value)
                delayFunction({
                    val audioManager: AudioManager? = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager?
                    if(audioManager!!.getStreamVolume(AudioManager.STREAM_MUSIC) < audioManager!!.getStreamMaxVolume(AudioManager.STREAM_MUSIC)/2) {
                        audioManager!!.setStreamVolume(AudioManager.STREAM_MUSIC,
                                audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC),
                                AudioManager.MODE_NORMAL)
                    }
                    releaseWakeLock()
                }, 250)
            }catch (ex: Exception){
                releaseWakeLock()
                ex.printStackTrace()
            }
        }
        else {
            releaseWakeLock()
        }
    }
    private fun delayFunction(function: ()-> Unit, delay: Long) {
        Handler().postDelayed(function, delay)
    }
    fun acquireWakeLock(context: Context) {
        if (wakeLock != null) wakeLock!!.release()
        val pm: PowerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE, "WakeLock"
        )
        wakeLock!!.acquire()
    }

    fun releaseWakeLock() {
        if (wakeLock != null) wakeLock!!.release()
        wakeLock = null
    }
}

class AudioPlayer {
    private var mMediaPlayer: MediaPlayer = MediaPlayer()
    private fun stopAudio(context: Context) {
        try {
            mMediaPlayer.stop()
            mMediaPlayer.release()
        }catch (ex: Exception){
            ex.printStackTrace()
        }

    }
    fun playAudio(context: Context, fileName: String) {
        try {
            stopAudio(context)
            mMediaPlayer =  MediaPlayer()
            mMediaPlayer.setDataSource(fileName)
            mMediaPlayer.isLooping = false
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager?
            if (am?.ringerMode == AudioManager.RINGER_MODE_NORMAL) {
                mMediaPlayer.setVolume(100f, 100f)
                mMediaPlayer.prepare()
                mMediaPlayer.start()
            }
        }catch (ex: Exception){
            ex.printStackTrace()
        }

    }
}