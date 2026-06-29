package tech.hammerhead.mesh_market

import android.app.PendingIntent
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets

class MainActivity : FlutterActivity() {
    private var nfcAdapter: NfcAdapter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tech.hammerhead.mesh_market/open_path"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFolder" -> result.success(openFolder(call.argument<String>("path")))
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tech.hammerhead.mesh_market/nfc_pairing"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startNdefPush" -> result.success(
                    startNdefPush(
                        call.argument<String>("mimeType"),
                        call.argument<String>("payload")
                    )
                )
                "stopNdefPush" -> {
                    stopNdefPush()
                    result.success(null)
                }
                "startHce" -> result.success(startHce(call.argument<String>("payload")))
                "popHceReceived" -> result.success(popHceReceived())
                "stopHce" -> {
                    stopHce()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        enableForegroundNfcDispatch()
    }

    override fun onPause() {
        disableForegroundNfcDispatch()
        super.onPause()
    }

    private fun enableForegroundNfcDispatch() {
        val adapter = nfcAdapter ?: return
        val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)
        try {
            adapter.enableForegroundDispatch(this, pendingIntent, null, null)
        } catch (_: IllegalStateException) {
        }
    }

    private fun disableForegroundNfcDispatch() {
        try {
            nfcAdapter?.disableForegroundDispatch(this)
        } catch (_: IllegalStateException) {
        }
    }

    @Suppress("DEPRECATION")
    private fun startNdefPush(mimeType: String?, payload: String?): Boolean {
        if (mimeType.isNullOrBlank() || payload == null) return false
        val adapter = nfcAdapter ?: return false
        return try {
            val record = NdefRecord.createMime(
                mimeType,
                payload.toByteArray(StandardCharsets.UTF_8)
            )
            setNdefPushMessage(adapter, NdefMessage(arrayOf(record)))
            true
        } catch (_: UnsupportedOperationException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        } catch (_: IllegalStateException) {
            false
        } catch (_: SecurityException) {
            false
        } catch (_: ReflectiveOperationException) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun stopNdefPush() {
        try {
            nfcAdapter?.let { setNdefPushMessage(it, null) }
        } catch (_: UnsupportedOperationException) {
        } catch (_: IllegalStateException) {
        } catch (_: SecurityException) {
        } catch (_: ReflectiveOperationException) {
        }
    }

    private fun setNdefPushMessage(adapter: NfcAdapter, message: NdefMessage?) {
        val method = adapter.javaClass.getMethod(
            "setNdefPushMessage",
            NdefMessage::class.java,
            Activity::class.java,
            Array<Activity>::class.java
        )
        method.invoke(adapter, message, this, emptyArray<Activity>())
    }

    private fun startHce(payload: String?): Boolean {
        if (payload.isNullOrBlank()) return false
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)) {
            return false
        }
        getSharedPreferences(NfcPairingApduService.PREFS, MODE_PRIVATE)
            .edit()
            .putString(NfcPairingApduService.KEY_PAYLOAD, payload)
            .apply()
        return true
    }

    private fun stopHce() {
        getSharedPreferences(NfcPairingApduService.PREFS, MODE_PRIVATE)
            .edit()
            .remove(NfcPairingApduService.KEY_PAYLOAD)
            .apply()
    }

    private fun popHceReceived(): String? {
        val prefs = getSharedPreferences(NfcPairingApduService.PREFS, MODE_PRIVATE)
        val payload = prefs.getString(NfcPairingApduService.KEY_RECEIVED_PAYLOAD, null)
        if (payload != null) {
            prefs.edit().remove(NfcPairingApduService.KEY_RECEIVED_PAYLOAD).apply()
        }
        return payload
    }

    private fun openFolder(path: String?): Boolean {
        val documentUri = path?.let(::externalStorageDocumentUri)
        if (documentUri != null && openFileManagerPath(documentUri)) return true
        return openDocumentsTree(documentUri)
    }

    private fun externalStorageDocumentUri(path: String): Uri? {
        val storagePath = "/storage/emulated/0/"
        if (!path.startsWith(storagePath)) return null
        val relative = path.removePrefix(storagePath).trimEnd('/')
        val docId =
            if (relative.isEmpty()) "primary:" else "primary:${relative.replace('/', ':')}"
        return DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents", docId
        )
    }

    private fun openFileManagerPath(uri: Uri): Boolean {
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, DocumentsContract.Document.MIME_TYPE_DIR)
            .addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_ACTIVITY_NEW_TASK
            )
        return start(intent)
    }

    private fun openDocumentsTree(initialUri: Uri?): Boolean {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .putExtra("android.content.extra.SHOW_ADVANCED", true)
            .addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        if (initialUri != null) {
            intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
        }
        return start(intent)
    }

    private fun start(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        }
    }
}
