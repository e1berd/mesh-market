#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

public class PmOfflinePlugin: NSObject, FlutterPlugin {
    private let multipeer = MultipeerController()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PmOfflinePlugin()
        #if os(iOS)
        let messenger = registrar.messenger()
        #elseif os(macOS)
        let messenger = registrar.messenger
        #endif
        let method = FlutterMethodChannel(
            name: "pm_offline/multipeer", binaryMessenger: messenger)
        let events = FlutterEventChannel(
            name: "pm_offline/multipeer/events", binaryMessenger: messenger)
        registrar.addMethodCallDelegate(instance, channel: method)
        events.setStreamHandler(instance.multipeer)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        multipeer.handle(call, result: result)
    }
}
