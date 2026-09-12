package pl.brothware.bsharp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pl.brothware.bsharp/wear")
            .setMethodCallHandler { call, result ->
                if (call.method == "isScreenRound") {
                    result.success(resources.configuration.isScreenRound)
                } else {
                    result.notImplemented()
                }
            }
    }
}
