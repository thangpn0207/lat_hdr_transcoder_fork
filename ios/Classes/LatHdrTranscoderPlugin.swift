import Flutter
import UIKit

public class LatHdrTranscoderPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private let cacheDirName = "_sdr_"
    
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "lat_hdr_transcoder", binaryMessenger: registrar.messenger())
        let instance = LatHdrTranscoderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let eventChannel = FlutterEventChannel(name: "lat_hdr_transcode/stream", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance.self)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("\(call.method), \(String(describing: call.arguments))")
        switch call.method {
        case "isHDR":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                TranscodeErrorType.invalidArgs.occurs(result: result)
                return
            }
            
            guard #available(iOS 14.0, *) else {
                TranscodeErrorType.notSupportVersion.occurs(result: result)
                return
            }
            
            let inputURL = URL(fileURLWithPath: path)
            let isHDR = Transcoder().isHDR(inputURL: inputURL)
            result(isHDR)
        
        case "clearCache":
            result(clearCache())
            
        case "transcode":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                TranscodeErrorType.invalidArgs.occurs(result: result)
                return
            }
            
            let inputURL = URL(fileURLWithPath: path)
            let outputURL = outputFileURL(inputPath: path)
            
            guard deleteFileIfExists(url: outputURL) else {
                TranscodeErrorType.existsOutputFile.occurs(result: result)
                return
            }
            
            Transcoder().convert(inputURL: inputURL, outputURL: outputURL) { progress in
                print(progress)
                self.eventSink?(progress)
            } completion: { error in
                if let error = error {
                    TranscodeErrorType.failedConvert.occurs(result: result, extra: error.localizedDescription)
                } else {
                    result(outputURL.relativePath)
                }
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    private func outputFileURL(inputPath: String) -> URL {
        let inputUrl = URL(fileURLWithPath: inputPath)
        let fileName = inputUrl.deletingPathExtension().lastPathComponent
        let newFileName = fileName + "_sdr"
        
        let tempDirURL = createTempDirIfNot()
        let newURL = tempDirURL.appendingPathComponent(newFileName).appendingPathExtension("mp4")
        return newURL
    }
    
    
    
    private func clearCache() -> Bool {
        let url = cacheDirURL()
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                return true
            } catch {
                return false
            }
        }
        return true
    }
    

    private func createTempDirIfNot() -> URL {
        let url = cacheDirURL()
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        } catch {
            print(error)
            return url
        }
    }
    
    private func deleteFileIfExists(url: URL) -> Bool {
        let manager = FileManager.default
        guard manager.fileExists(atPath: url.relativePath) else {
            return true
        }
        
        do {
            try manager.removeItem(atPath: url.relativePath)
            return true
        } catch  {
            print("error \(error)")
            return false
        }
        
    }
    
    private func cacheDirURL() -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(cacheDirName, isDirectory: true)
    }
    
    private func fileExists(url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.relativePath)
    }
    
}
