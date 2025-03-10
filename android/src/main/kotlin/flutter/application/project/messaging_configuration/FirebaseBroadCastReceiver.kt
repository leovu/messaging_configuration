package flutter.application.project.messaging_configuration

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import android.os.PowerManager
import android.widget.Toast


class FirebaseBroadcastReceiver : BroadcastReceiver() {
    private var wakeLock: PowerManager.WakeLock? = null
    override fun onReceive(context: Context, intent: Intent) {
        acquireWakeLock(context)
        val sharePref: SharePref = SharePref.getInstance(context)
        val value:String = sharePref.getData(UtilProject.key)
        if(value != "") {
            try {
                delayFunction({
                    AudioPlayer().playAudio(context, value)
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
                    PowerManager.ON_AFTER_RELEASE, "AppTag:WakeLock"
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
            val currentVolumeNotification = am!!.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
            if(currentVolumeNotification > 0) {
                if (am?.ringerMode == AudioManager.RINGER_MODE_NORMAL) {
                    val currentVolume = am!!.getStreamVolume(AudioManager.STREAM_MUSIC)
                    if(currentVolume > 65) {
                        mMediaPlayer.setVolume(50.toFloat(), currentVolume.toFloat())
                    }
                    else {
                        mMediaPlayer.setVolume(25.toFloat(), currentVolume.toFloat())
                    }
                    mMediaPlayer.prepare()
                    mMediaPlayer.start()
                    mMediaPlayer.setVolume(currentVolume.toFloat(), currentVolume.toFloat())
                }
            }
        }catch (ex: Exception){
            ex.printStackTrace()
        }

    }
}