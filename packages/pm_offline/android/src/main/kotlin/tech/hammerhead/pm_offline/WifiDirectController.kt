package tech.hammerhead.pm_offline

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pManager
import android.net.wifi.p2p.nsd.WifiP2pDnsSdServiceInfo
import android.net.wifi.p2p.nsd.WifiP2pDnsSdServiceRequest
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val SERVICE_NAME = "meshmarket"
private const val SERVICE_TYPE = "_meshmarket._tcp"

class WifiDirectController(private val context: Context) :
    MethodChannel.MethodCallHandler {

    private val manager: WifiP2pManager? =
        context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private var channel: WifiP2pManager.Channel? = null

    private val resolvedPorts = HashMap<String, Int>()
    private val resolvedDevices = HashMap<String, WifiP2pDevice>()
    private var pendingResolve: PendingResolve? = null
    private var receiver: BroadcastReceiver? = null

    private data class PendingResolve(val peerId: String, val result: MethodChannel.Result)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "start" -> start(call.argument<String>("deviceId").orEmpty(),
                call.argument<Int>("syncPort") ?: 0, result)
            "resolve" -> resolve(call.argument<String>("peerId").orEmpty(), result)
            "stop" -> stop(result)
            else -> result.notImplemented()
        }
    }

    private fun isSupported(): Boolean =
        manager != null &&
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT)

    private fun start(deviceId: String, syncPort: Int, result: MethodChannel.Result) {
        val mgr = manager
        if (mgr == null) {
            result.error("unsupported", "Wi-Fi Direct unavailable", null)
            return
        }
        if (channel == null) channel = mgr.initialize(context, Looper.getMainLooper(), null)
        val info = WifiP2pDnsSdServiceInfo.newInstance(
            SERVICE_NAME, SERVICE_TYPE, mapOf("id" to deviceId, "port" to syncPort.toString())
        )
        mgr.clearLocalServices(channel, null)
        mgr.addLocalService(channel, info, actionListener(result) { registerListeners() })
    }

    private fun registerListeners() {
        val mgr = manager ?: return
        mgr.setDnsSdResponseListeners(
            channel,
            { _, _, device -> resolvedDevices[device.deviceAddress] = device },
            { _, record, device ->
                val id = record["id"] ?: return@setDnsSdResponseListeners
                val port = record["port"]?.toIntOrNull() ?: return@setDnsSdResponseListeners
                resolvedPorts[id] = port
                resolvedDevices[id] = device
                tryCompletePending()
            },
        )
    }

    private fun resolve(peerId: String, result: MethodChannel.Result) {
        val mgr = manager
        if (mgr == null || channel == null) {
            result.error("unsupported", "Wi-Fi Direct not started", null)
            return
        }
        pendingResolve = PendingResolve(peerId, result)
        ensureReceiver()
        mgr.addServiceRequest(channel, WifiP2pDnsSdServiceRequest.newInstance(), null)
        mgr.discoverServices(channel, null)
    }

    private fun tryCompletePending() {
        val pending = pendingResolve ?: return
        val device = resolvedDevices[pending.peerId] ?: return
        val port = resolvedPorts[pending.peerId] ?: return
        val mgr = manager ?: return
        val config = WifiP2pConfig().apply { deviceAddress = device.deviceAddress }
        mgr.connect(channel, config, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                requestConnectionInfo(port)
            }

            override fun onFailure(reason: Int) {
                finishResolve(null)
            }
        })
    }

    private fun requestConnectionInfo(peerPort: Int) {
        val mgr = manager ?: return
        mgr.requestConnectionInfo(channel) { info ->
            if (!info.groupFormed || info.isGroupOwner) {
                finishResolve(null)
            } else {
                finishResolve(
                    mapOf("host" to info.groupOwnerAddress.hostAddress, "port" to peerPort)
                )
            }
        }
    }

    private fun finishResolve(payload: Map<String, Any?>?) {
        pendingResolve?.result?.success(payload)
        pendingResolve = null
    }

    private fun ensureReceiver() {
        if (receiver != null) return
        val filter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
        }
        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {}
        }
        context.registerReceiver(receiver, filter)
    }

    private fun stop(result: MethodChannel.Result) {
        val mgr = manager
        val ch = channel
        if (mgr != null && ch != null) {
            mgr.clearLocalServices(ch, null)
            mgr.clearServiceRequests(ch, null)
            mgr.removeGroup(ch, null)
        }
        dispose()
        result.success(null)
    }

    fun dispose() {
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        receiver = null
        pendingResolve = null
        resolvedPorts.clear()
        resolvedDevices.clear()
    }

    private fun actionListener(
        result: MethodChannel.Result,
        onSuccess: () -> Unit,
    ) = object : WifiP2pManager.ActionListener {
        override fun onSuccess() {
            onSuccess()
            result.success(null)
        }

        override fun onFailure(reason: Int) {
            result.error("p2p_error", "Wi-Fi Direct action failed: $reason", null)
        }
    }
}
