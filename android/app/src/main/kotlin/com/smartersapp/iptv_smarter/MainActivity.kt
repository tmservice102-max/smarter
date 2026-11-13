package com.smartersapp.iptv_smarter

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Battery level for the player's battery icon (getBatteryDrawable).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/battery").setMethodCallHandler { call, result ->
            if (call.method == "battery") {
                val i = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                val level = i?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                val scale = i?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
                val status = i?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                result.success(
                    mapOf(
                        "level" to if (level < 0 || scale <= 0) -1 else level * 100 / scale,
                        "charging" to (status == BatteryManager.BATTERY_STATUS_CHARGING),
                    ),
                )
            } else {
                result.notImplemented()
            }
        }
    }
}
