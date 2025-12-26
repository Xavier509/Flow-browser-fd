import Flutter
import UIKit
import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.flow.browser/vpn_proxy"
    private var vpnManager: NEVPNManager?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

        methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "toggleProxy":
                if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool {
                    self?.toggleProxy(enabled: enabled)
                    result(nil)
                }
            case "toggleVPN":
                if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool, let provider = args["provider"] as? String {
                    self?.toggleVPN(enabled: enabled, provider: provider)
                    result(nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func toggleProxy(enabled: Bool) {
        // Basic proxy toggle (for system-wide, more complex implementation needed)
        if enabled {
            // Set proxy
        } else {
            // Remove proxy
        }
    }

    private func toggleVPN(enabled: Bool, provider: String) {
        vpnManager = NEVPNManager.shared()
        vpnManager?.loadFromPreferences { error in
            if error != nil {
                return
            }

            if enabled {
                let vpnProtocol = NEVPNProtocolIKEv2()
                vpnProtocol.serverAddress = "your.vpn.server.com"
                vpnProtocol.username = "username"
                vpnProtocol.passwordReference = "password".data(using: .utf8)
                vpnProtocol.remoteIdentifier = "your.vpn.server.com"
                vpnProtocol.localIdentifier = "client"

                self.vpnManager?.protocolConfiguration = vpnProtocol
                self.vpnManager?.localizedDescription = "Flow VPN"
                self.vpnManager?.isEnabled = true

                self.vpnManager?.saveToPreferences { error in
                    if error == nil {
                        do {
                            try self.vpnManager?.connection.startVPNTunnel()
                        } catch {
                            // Handle error
                        }
                    }
                }
            } else {
                self.vpnManager?.connection.stopVPNTunnel()
            }
        }
    }
}
