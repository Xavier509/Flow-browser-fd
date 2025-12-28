package com.example.flow_browser

import android.net.VpnService
import android.os.ParcelFileDescriptor

class MyVpnService : VpnService() {
    override fun onStartCommand(intent: android.content.Intent?, flags: Int, startId: Int): Int {
        val builder = Builder()
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .setSession("Flow VPN")

        val vpnInterface = builder.establish()
        return START_STICKY
    }
}