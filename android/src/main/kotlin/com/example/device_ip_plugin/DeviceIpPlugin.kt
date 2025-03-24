package com.example.device_ip_plugin

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.text.format.Formatter
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.Inet6Address
import java.net.InetAddress
import java.net.NetworkInterface
import java.util.*

class DeviceIpPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var cachedIp: String? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "device_ip_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getIpAddress" -> {
                val networkType = call.argument<String>("networkType") ?: "wifi"
                result.success(getIpAddress(networkType))
            }
            else -> result.notImplemented()
        }
    }

    private fun getIpAddress(networkType: String): String {
        cachedIp?.let { return it } // Use cached IP

        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork: Network? = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)

        if (capabilities == null) {
            return "No internet connection"
        }

        return if (networkType == "wifi" && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            getWifiIp()
        } else if (networkType == "mobile" && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
            getMobileIp()
        } else {
            "No internet connection"
        }
    }

    private fun getWifiIp(): String {
        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val ip = wifiManager.connectionInfo.ipAddress
        cachedIp = Formatter.formatIpAddress(ip)
        return cachedIp ?: "No internet connection"
    }

    private fun getMobileIp(): String {
        try {
            NetworkInterface.getNetworkInterfaces().toList().forEach { networkInterface ->
                networkInterface.inetAddresses.toList().forEach { address ->
                    if (!address.isLoopbackAddress && address is InetAddress && address !is Inet6Address) {
                        cachedIp = address.hostAddress
                        return cachedIp!!
                    }
                }
            }
        } catch (e: Exception) {
            return "No internet connection"
        }
        return "No internet connection"
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
