import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    TrackingPlugin.register(with: self.registrar(forPlugin: "TrackingPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
