package wao.flutter.application.project.messaging_configuration

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.widget.Toast


class FirebaseBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
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
                }, 250)
            }catch (ex: Exception){
                ex.printStackTrace()
            }
        }
    }
    private fun delayFunction(function: ()-> Unit, delay: Long) {
        Handler().postDelayed(function, delay)
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
            mMediaPlayer.setVolume(100f, 100f)
            mMediaPlayer.prepare()
            mMediaPlayer.start()
        }catch (ex: Exception){
            ex.printStackTrace()
        }

    }
}