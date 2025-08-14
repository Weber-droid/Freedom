import UIKit
import Flutter
import GoogleMaps


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     let dartDefinesString = Bundle.main.infoDictionary!["DART_DEFINES"] as! String
     print("my key \(dartDefinesString)")
var dartDefinesDictionary = [String:String]()
for definedValue in dartDefinesString.components(separatedBy: ",") {
    guard let decodedData = Data(base64Encoded: definedValue),
          let decoded = String(data: decodedData, encoding: .utf8) else { continue }
    let values = decoded.components(separatedBy: "=")
    if values.count == 2 {
        dartDefinesDictionary[values[0]] = values[1]
    }
}
if let apiKey = dartDefinesDictionary["MAPS_API_KEY"] {
    GMSServices.provideAPIKey(apiKey)
} else {
    print("MAPS_API_KEY not found in dart defines!")
}

GMSServices.provideAPIKey(dartDefinesDictionary["MAPS_API_KEY"]!)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}