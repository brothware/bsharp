package pl.brothware.bsharp

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.view.InputDevice
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var rotarySink: EventChannel.EventSink? = null

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pl.brothware.bsharp/battery")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isExempt" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestExemption" -> {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "pl.brothware.bsharp/rotary")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    rotarySink = events
                }

                override fun onCancel(arguments: Any?) {
                    rotarySink = null
                }
            })
    }

    override fun onGenericMotionEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_SCROLL &&
            event.isFromSource(InputDevice.SOURCE_ROTARY_ENCODER)
        ) {
            rotarySink?.success(-event.getAxisValue(MotionEvent.AXIS_SCROLL).toDouble())
            return true
        }
        return super.onGenericMotionEvent(event)
    }
}
