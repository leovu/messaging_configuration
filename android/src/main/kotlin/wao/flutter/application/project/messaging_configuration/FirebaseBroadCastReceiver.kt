package wao.flutter.application.project.messaging_configuration

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer


class FirebaseBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val sharePref: SharePref = SharePref.getInstance(context)
        val value:String = sharePref.getData(UtilProject.key)
        if(value != "") {
            AudioPlayer().playAudio(context, value)
        }
    }

}

class AudioPlayer {
    private var mMediaPlayer: MediaPlayer = MediaPlayer()
    private fun stopAudio(context: Context) {
        try {
            mMediaPlayer.release()
        }catch (ex: Exception){
            ex.printStackTrace()
        }

    }
    fun playAudio(context: Context, fileName: String) {
        try {
            stopAudio(context)
            val audioManager: AudioManager? = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager?
            audioManager!!.setStreamVolume(AudioManager.STREAM_MUSIC,
                    audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC),
                    AudioManager.FLAG_SHOW_UI)
            mMediaPlayer = MediaPlayer()
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