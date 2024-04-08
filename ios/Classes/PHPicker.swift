import Foundation
import Flutter
import PhotosUI

@available(iOS 14.0, *)
public class PHPicker: NSObject, PHPickerViewControllerDelegate {

    private static var sWeakDict: Set<PHPicker> = Set<PHPicker>()

    private let result: FlutterResult

    init(_ result: @escaping FlutterResult) {
        self.result = result
        super.init()
    }

    func chooseVideoFromGallery(_ parent: UIViewController) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .overCurrentContext

        PHPicker.sWeakDict.insert(self)
        parent.present(picker, animated: true, completion: nil)
    }


    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        PHPicker.sWeakDict.remove(self)
        picker.dismiss(animated: true)

        if results.isEmpty {
            call(nil)
            return
        }
        let video = results.first!
        video.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
            if let url = url {
                let file = VideoPickerPlugin.copyVideo(url: url)
                self.call(file)
                return
            }
            self.call(nil)
        }
    }

    private func call(_ any: Any?) {
        DispatchQueue.main.async {
            self.result(any)
        }
    }
}
