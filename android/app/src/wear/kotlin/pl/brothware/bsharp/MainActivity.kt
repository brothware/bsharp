package pl.brothware.bsharp

import android.app.Activity
import android.app.RemoteInput
import android.content.Intent
import androidx.wear.input.RemoteInputIntentHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "pl.brothware.bsharp/wear"
private const val INPUT_KEY = "text"
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
                        requestTextInput(call.argument("label"), result)
                    else -> result.notImplemented()
                }
            }
    }

    // The watch keyboard keeps its own copy of the text on screen and only
    // refreshes it for a real EditText, which Flutter does not give it. The
    // system input screen owns both, and adds voice and handwriting.
    private fun requestTextInput(label: String?, result: MethodChannel.Result) {
        pendingInput?.success(null)
        pendingInput = result

        val remoteInput = RemoteInput.Builder(INPUT_KEY)
            .setLabel(label)
            .setAllowFreeFormInput(true)
            .build()
        val intent = RemoteInputIntentHelper.createActionRemoteInputIntent()
        RemoteInputIntentHelper.putRemoteInputsExtra(intent, listOf(remoteInput))
        if (label != null) RemoteInputIntentHelper.putTitleExtra(intent, label)
        startActivityForResult(intent, INPUT_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != INPUT_REQUEST) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val pending = pendingInput
        pendingInput = null
        val typed = data?.takeIf { resultCode == Activity.RESULT_OK }?.let {
            RemoteInput.getResultsFromIntent(it)?.getCharSequence(INPUT_KEY)
        }
        pending?.success(typed?.toString())
    }
}
