import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Battery level for the player's battery icon (like the Android app).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppBattery") {
      let channel = FlutterMethodChannel(name: "app/battery", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "battery" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        let charging = device.batteryState == .charging
        result(["level": level < 0 ? -1 : Int(level * 100), "charging": charging])
      }
    }
  }
}
