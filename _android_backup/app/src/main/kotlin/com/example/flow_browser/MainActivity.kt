package com.example.flow_browser

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.flow.browser/vpn_proxy"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleProxy" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    toggleProxy(enabled)
                    result.success(null)
                }
                "toggleVPN" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val provider = call.argument<String>("provider") ?: "mullvad"
                    toggleVPN(enabled, provider)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun toggleProxy(enabled: Boolean) {
        if (enabled) {
            System.setProperty("http.proxyHost", "127.0.0.1")
            System.setProperty("http.proxyPort", "8080")
        } else {
            System.clearProperty("http.proxyHost")
            System.clearProperty("http.proxyPort")
        }
    }

    private fun toggleVPN(enabled: Boolean, provider: String) {
        if (enabled) {
            val intent = VpnService.prepare(this)
            if (intent != null) {
                startActivityForResult(intent, 0)
            } else {
                onActivityResult(0, Activity.RESULT_OK, null)
            }
        } else {
            val intent = Intent(this, MyVpnService::class.java)
            stopService(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == 0 && resultCode == Activity.RESULT_OK) {
            val intent = Intent(this, MyVpnService::class.java)
            startService(intent)
        }
    }
}
