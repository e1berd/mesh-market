package tech.hammerhead.point_machine

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tech.hammerhead.point_machine/open_path"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFolder" -> result.success(openFolder(call.argument<String>("path")))
                else -> result.notImplemented()
            }
        }
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
