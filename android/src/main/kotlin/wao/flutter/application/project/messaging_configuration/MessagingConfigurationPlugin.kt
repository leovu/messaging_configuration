package wao.flutter.application.project.messaging_configuration

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.res.AssetManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.annotation.NonNull
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** MessagingConfigurationPlugin */
class MessagingConfigurationPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var vibrateChannel : MethodChannel
  private lateinit var context: Context
  private lateinit var assetManager: AssetManager
  private lateinit var player: MediaPlayer

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    assetManager = flutterPluginBinding.applicationContext.assets
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter.io/audioSoundSetup")
    channel.setMethodCallHandler(this)
    vibrateChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter.io/vibrate")
    vibrateChannel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "setupSound") {
      val dict:Map<String,Any> = call.arguments()
      if(dict["asset"] == null || dict["asset"] == "") {
        result.success("Android Setup Sound failed")
      }
      else {
        createChannel(dict["asset"].toString(),dict["channelId"].toString())
        result.success("Android Setup Sound completed")
      }
    }
    else if (call.method == "vibrate") {
      val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
      if (Build.VERSION.SDK_INT >= 26) {
        vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
      } else {
        vibrator.vibrate(200)
      }
      result.success("vibrate completed")
    }
    else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
  
  private fun createChannel(asset:String, channelId:String) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val loader = FlutterInjector.instance().flutterLoader()
      val key = loader.getLookupKeyForAsset(asset)
      val channel = NotificationChannel(channelId, "simpleLove", NotificationManager.IMPORTANCE_HIGH)
      val soundUri = Uri.parse(key)
      val att = AudioAttributes.Builder()
              .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
              .setUsage(AudioAttributes.USAGE_NOTIFICATION)
              .build()
      channel.setSound(null, null)
      val notificationManager: NotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      notificationManager.createNotificationChannel(channel)
      UtilProject.context = context
      val sharePref: SharePref = SharePref.getInstance(context)
      sharePref.saveData(UtilProject.key, asset)
    }
    else {
      //TODO: Android below 8 will automatically has sound when payload has sound value
    }
  }
}

object UtilProject {
  var asset: String? = null
  var context: Context? = null
  val key:String = "NotificationSoundKey"
}