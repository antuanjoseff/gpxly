import Foundation
import Flutter
import CoreLocation

class TrackingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?

    // MARK: - Plugin registration
    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TrackingPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "tracking/methods",
            binaryMessenger: registrar.messenger()
        )

        let eventChannel = FlutterEventChannel(
            name: "tracking/events",
            binaryMessenger: registrar.messenger()
        )

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - MethodChannel
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {

        case "start":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "BAD_ARGS", message: "Arguments missing", details: nil))
                return
            }

            let useTime = args["useTime"] as? Bool ?? true
            let seconds = args["seconds"] as? Int ?? 5
            let meters = args["meters"] as? Double ?? 10.0
            let accuracy = args["accuracy"] as? Double ?? 30.0

            TrackingManager.shared.configure(
                useTime: useTime,
                seconds: seconds,
                meters: meters,
                accuracy: accuracy
            )

            TrackingManager.shared.startTracking()
            result(nil)

        case "stop":
            TrackingManager.shared.stopTracking()
            result(nil)

        case "hasBackgroundPermission":
            let status = CLLocationManager.authorizationStatus()
            let granted = (status == .authorizedAlways)
            result(granted)

        case "requestBackgroundPermission":
            // iOS no permet forçar el diàleg Always.
            // L’usuari ha d’anar a Settings.
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            result(true)

        case "openAppLocationPermissions":
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - EventChannel
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        // Connectem TrackingManager amb Flutter
        TrackingManager.shared.eventSink = { data in
            events(data)
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        TrackingManager.shared.eventSink = nil
        return nil
    }
}
