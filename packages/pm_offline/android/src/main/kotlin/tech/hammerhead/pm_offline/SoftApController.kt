package tech.hammerhead.pm_offline

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SoftApController(private val context: Context) :
    MethodChannel.MethodCallHandler {

    private val wifi: WifiManager? =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "start" -> start(result)
            "stop" -> stop(result)
            else -> result.notImplemented()
        }
    }

    private fun isSupported(): Boolean =
        wifi != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O

    private fun start(result: MethodChannel.Result) {
        val mgr = wifi
        if (mgr == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("unsupported", "Local hotspot unavailable", null)
            return
        }
        mgr.startLocalOnlyHotspot(
            object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(res: WifiManager.LocalOnlyHotspotReservation) {
                    reservation = res
                    result.success(credentials(res))
                }

                override fun onFailed(reason: Int) {
                    result.error("hotspot_failed", "Hotspot failed: $reason", null)
                }
            },
            null,
        )
    }

    private fun credentials(res: WifiManager.LocalOnlyHotspotReservation): Map<String, Any?> {
        val config = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            res.softApConfiguration
        } else {
            null
        }
        @Suppress("DEPRECATION")
        val legacy = res.wifiConfiguration
        return mapOf(
            "ssid" to (config?.ssid ?: legacy?.SSID ?: ""),
            "passphrase" to (config?.passphrase ?: legacy?.preSharedKey ?: ""),
        )
    }

    private fun stop(result: MethodChannel.Result) {
        dispose()
        result.success(null)
    }

    fun dispose() {
        reservation?.close()
        reservation = null
    }
}
