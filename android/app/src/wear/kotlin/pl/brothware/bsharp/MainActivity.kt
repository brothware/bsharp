package pl.brothware.bsharp

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "pl.brothware.bsharp/wear"
private const val INPUT_REQUEST = 4201

class MainActivity : FlutterActivity() {
    private var pendingInput: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isScreenRound" ->
                        result.success(resources.configuration.isScreenRound)
                    "requestTextInput" ->
                        requestTextInput(
                            call.argument("label"),
                            call.argument("text"),
                            result,
                        )
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestTextInput(
        label: String?,
        text: String?,
        result: MethodChannel.Result,
    ) {
        pendingInput?.success(null)
        pendingInput = result

        val intent = Intent(this, TextInputActivity::class.java)
            .putExtra(TextInputActivity.EXTRA_LABEL, label)
            .putExtra(TextInputActivity.EXTRA_TEXT, text)
        startActivityForResult(intent, INPUT_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != INPUT_REQUEST) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val pending = pendingInput
        pendingInput = null
        val typed = data
            ?.takeIf { resultCode == Activity.RESULT_OK }
            ?.getStringExtra(TextInputActivity.EXTRA_TEXT)
        pending?.success(typed)
    }
}
