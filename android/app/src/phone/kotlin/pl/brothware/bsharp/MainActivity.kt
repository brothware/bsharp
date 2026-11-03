package pl.brothware.bsharp

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.Settings
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "pl.brothware.bsharp/phone"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connectedWatchName" -> connectedWatchName(result)
                    "openAppList" -> openAppList(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun connectedWatchName(result: MethodChannel.Result) {
        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes -> result.success(nodes.firstOrNull()?.displayName) }
            .addOnFailureListener { error ->
                result.error("watch_unavailable", error.message, null)
            }
    }

    private fun openAppList(result: MethodChannel.Result) {
        val failures = mutableListOf<String>()
        for (action in listOf(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS, Settings.ACTION_SETTINGS)) {
            try {
                startActivity(Intent(action))
                result.success(null)
                return
            } catch (error: ActivityNotFoundException) {
                failures += "$action: ${error.message}"
            }
        }
        result.error("no_settings", failures.joinToString("; "), null)
    }
}
