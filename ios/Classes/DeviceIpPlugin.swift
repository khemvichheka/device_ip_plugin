import Flutter
import UIKit
import SystemConfiguration.CaptiveNetwork
import Network

public class DeviceIpPlugin: NSObject, FlutterPlugin {
    static var cachedIp: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "device_ip_plugin", binaryMessenger: registrar.messenger())
        let instance = DeviceIpPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getIpAddress" {
            let args = call.arguments as? [String: Any]
            let networkType = args?["networkType"] as? String ?? "wifi"
            result(getIPAddress(networkType: networkType))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func getIPAddress(networkType: String) -> String {
        if let cached = DeviceIpPlugin.cachedIp {
            return cached
        }

        var address: String = "No internet connection"

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if (networkType == "wifi" && name == "en0") || (networkType == "mobile" && name == "pdp_ip0") {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        DeviceIpPlugin.cachedIp = address
                    }
                }
                ptr = interface.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
