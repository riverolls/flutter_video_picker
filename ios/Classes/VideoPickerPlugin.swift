import Flutter
import UIKit
import PhotosUI

public class VideoPickerPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.rr.video.picker", binaryMessenger: registrar.messenger())
        let instance = VideoPickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "chooseVideoFromGallery":
            chooseVideoFromGallery(result)
            break

        case "clean":
            clean()
            break

        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    /// 清理文件
    private func clean() {
        DispatchQueue.global().async {
            let fm = FileManager.default
            do {
                let dir = VideoPickerPlugin.getCacheDir()
                if !fm.fileExists(atPath: dir) {
                    return
                }
                let files = try fm.contentsOfDirectory(atPath: dir)
                for file in files {
                    do {
                        try fm.removeItem(atPath: dir + "/" + file)
                    } catch {
                        print("remove item:\(file)\n error:\(error)")
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }

    /// 从图库选中
    private func chooseVideoFromGallery(_ result: @escaping FlutterResult) {
        let parent = VideoPickerPlugin.viewControllerWithWindow(nil)
        if #available(iOS 14.0, *) {
            let picker = PHPicker(result)
            picker.chooseVideoFromGallery(parent)
        } else {
            let picker = UIImagePicker(result)
            picker.chooseVideoFromGallery(parent)
        }
    }

    private static func viewControllerWithWindow(_ window: UIWindow?) -> UIViewController {
        var windowToUse = window
        if (windowToUse == nil) {
            for window in UIApplication.shared.windows {
                if window.isKeyWindow {
                    windowToUse = window
                    break
                }
            }
        }

        var topController = windowToUse!.rootViewController
        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
        }
        return topController!
    }

    /// 复制视频
    public static func copyVideo(url: URL) -> String? {
        let fileManager = FileManager.default
        let cacheDir = getCacheDir()
        let fm = FileManager.default
        if (!fm.fileExists(atPath: cacheDir)) {
            do {
                try fm.createDirectory(atPath: cacheDir, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }

        let ext: String = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
        let targetUrl = cacheDir + "/picker_" + UUID().uuidString + "." + ext
        do {
            try fileManager.copyItem(atPath: url.path, toPath: targetUrl)
            return targetUrl
        } catch {
            return nil
        }
    }

    /// 获取缓存目录
    private static func getCacheDir() -> String {
        NSTemporaryDirectory()
        let parent = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.cachesDirectory,
                FileManager.SearchPathDomainMask.userDomainMask,
                true
        ).last!
        return parent + "/video_picker"
    }
}
