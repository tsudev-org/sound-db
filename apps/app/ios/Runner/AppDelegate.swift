import AVFoundation
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
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SoundDbAudioSession") else { return }
    // Kênh đặt phiên âm thanh cho đo lường (apps/app/lib/services/audio_input.dart):
    // mode .measurement tắt AGC, khử ồn, EQ của iOS - không có nó, mức đo thay đổi theo xử lý của hệ thống.
    let channel = FlutterMethodChannel(name: "com.tsudev.sounddb/audio_session", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "configureMeasurement" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setPreferredSampleRate(48_000)
        try session.setActive(true)
        result(session.sampleRate)
      } catch {
        result(FlutterError(code: "audio_session", message: error.localizedDescription, details: nil))
      }
    }
  }
}
