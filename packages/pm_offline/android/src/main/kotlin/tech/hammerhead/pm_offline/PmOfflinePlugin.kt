package tech.hammerhead.pm_offline

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class PmOfflinePlugin : FlutterPlugin {
    private lateinit var wifiDirect: MethodChannel
    private lateinit var wifiAware: MethodChannel
    private lateinit var softAp: MethodChannel

    private var wifiDirectController: WifiDirectController? = null
    private var wifiAwareController: WifiAwareController? = null
    private var softApController: SoftApController? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val messenger = binding.binaryMessenger

        wifiDirectController = WifiDirectController(context)
        wifiAwareController = WifiAwareController(context)
        softApController = SoftApController(context)

        wifiDirect = MethodChannel(messenger, "pm_offline/wifi_direct").apply {
            setMethodCallHandler(wifiDirectController)
        }
        wifiAware = MethodChannel(messenger, "pm_offline/wifi_aware").apply {
            setMethodCallHandler(wifiAwareController)
        }
        softAp = MethodChannel(messenger, "pm_offline/soft_ap").apply {
            setMethodCallHandler(softApController)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        wifiDirect.setMethodCallHandler(null)
        wifiAware.setMethodCallHandler(null)
        softAp.setMethodCallHandler(null)
        wifiDirectController?.dispose()
        wifiAwareController?.dispose()
        softApController?.dispose()
        wifiDirectController = null
        wifiAwareController = null
        softApController = null
    }
}

internal fun Context.hasSystemFeature(feature: String): Boolean =
    packageManager.hasSystemFeature(feature)
