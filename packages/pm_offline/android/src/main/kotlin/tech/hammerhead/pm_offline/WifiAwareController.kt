package tech.hammerhead.pm_offline

import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.aware.AttachCallback
import android.net.wifi.aware.DiscoverySessionCallback
import android.net.wifi.aware.PublishConfig
import android.net.wifi.aware.PublishDiscoverySession
import android.net.wifi.aware.SubscribeConfig
import android.net.wifi.aware.SubscribeDiscoverySession
import android.net.wifi.aware.WifiAwareManager
import android.net.wifi.aware.WifiAwareNetworkInfo
import android.net.wifi.aware.WifiAwareNetworkSpecifier
import android.net.wifi.aware.WifiAwareSession
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val AWARE_SERVICE = "meshmarket"

class WifiAwareController(private val context: Context) :
    MethodChannel.MethodCallHandler {

    private val manager: WifiAwareManager? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            context.getSystemService(Context.WIFI_AWARE_SERVICE) as? WifiAwareManager
        else null
    private val connectivity =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private var session: WifiAwareSession? = null
    private var publish: PublishDiscoverySession? = null
    private var subscribe: SubscribeDiscoverySession? = null
    private var deviceId: String = ""
    private var syncPort: Int = 0
    private var callback: ConnectivityManager.NetworkCallback? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "start" -> {
                deviceId = call.argument<String>("deviceId").orEmpty()
                syncPort = call.argument<Int>("syncPort") ?: 0
                start(result)
            }
            "resolve" -> resolve(call.argument<String>("peerId").orEmpty(), result)
            "stop" -> stop(result)
            else -> result.notImplemented()
        }
    }

    private fun isSupported(): Boolean =
        manager != null &&
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE) &&
            manager.isAvailable

    private fun start(result: MethodChannel.Result) {
        val mgr = manager
        if (mgr == null) {
            result.error("unsupported", "Wi-Fi Aware unavailable", null)
            return
        }
        mgr.attach(object : AttachCallback() {
            override fun onAttached(awareSession: WifiAwareSession) {
                session = awareSession
                publishService()
                result.success(null)
            }

            override fun onAttachFailed() {
                result.error("attach_failed", "Wi-Fi Aware attach failed", null)
            }
        }, null)
    }

    private fun publishService() {
        val config = PublishConfig.Builder()
            .setServiceName(AWARE_SERVICE)
            .setServiceSpecificInfo("$deviceId:$syncPort".toByteArray())
            .build()
        session?.publish(config, object : DiscoverySessionCallback() {
            override fun onPublishStarted(s: PublishDiscoverySession) {
                publish = s
            }
        }, null)
    }

    private fun resolve(peerId: String, result: MethodChannel.Result) {
        val active = session
        if (active == null) {
            result.error("unsupported", "Wi-Fi Aware not started", null)
            return
        }
        val config = SubscribeConfig.Builder().setServiceName(AWARE_SERVICE).build()
        active.subscribe(config, object : DiscoverySessionCallback() {
            override fun onSubscribeStarted(s: SubscribeDiscoverySession) {
                subscribe = s
            }

            override fun onServiceDiscovered(
                peerHandle: android.net.wifi.aware.PeerHandle,
                serviceSpecificInfo: ByteArray?,
                matchFilter: List<ByteArray>?,
            ) {
                val info = serviceSpecificInfo?.let { String(it) } ?: return
                val parts = info.split(":")
                if (parts.size != 2 || parts[0] != peerId) return
                requestDataPath(peerHandle, parts[1].toIntOrNull() ?: return, result)
            }
        }, null)
    }

    private fun requestDataPath(
        peerHandle: android.net.wifi.aware.PeerHandle,
        peerPort: Int,
        result: MethodChannel.Result,
    ) {
        val sub = subscribe ?: return
        val specifier = WifiAwareNetworkSpecifier.Builder(sub, peerHandle).build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI_AWARE)
            .setNetworkSpecifier(specifier)
            .build()
        callback = object : ConnectivityManager.NetworkCallback() {
            override fun onCapabilitiesChanged(
                network: Network,
                caps: NetworkCapabilities,
            ) {
                val awareInfo = caps.transportInfo as? WifiAwareNetworkInfo ?: return
                val address = awareInfo.peerIpv6Addr ?: return
                val host = "${address.hostAddress}"
                result.success(mapOf("host" to host, "port" to peerPort))
            }
        }
        connectivity.requestNetwork(request, callback as ConnectivityManager.NetworkCallback)
    }

    private fun stop(result: MethodChannel.Result) {
        dispose()
        result.success(null)
    }

    fun dispose() {
        callback?.let { runCatching { connectivity.unregisterNetworkCallback(it) } }
        callback = null
        publish?.close()
        subscribe?.close()
        session?.close()
        publish = null
        subscribe = null
        session = null
    }
}
