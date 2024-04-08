import Foundation
import MobileCoreServices
import Flutter
import AVFoundation

class UIImagePicker: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    private static var sWeakDict: Set<UIImagePicker> = Set<UIImagePicker>()

    private let result: FlutterResult

    init(_ result: @escaping FlutterResult) {
        self.result = result
        super.init()
    }

    func chooseVideoFromGallery(_ parent: UIViewController) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeMPEG4 as String]
        picker.videoQuality = UIImagePickerController.QualityType.typeHigh
        picker.videoExportPreset = AVAssetExportPresetPassthrough  // 保证视频不被压缩
        picker.modalPresentationStyle = .overCurrentContext
        picker.delegate = self
        UIImagePicker.sWeakDict.insert(self)
        parent.present(picker, animated: true, completion: nil)
    }


    public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        UIImagePicker.sWeakDict.remove(self)
        picker.dismiss(animated: true)

        if let url = info[.mediaURL] as? URL {
            let file = VideoPickerPlugin.copyVideo(url: url)
            call(file)
            return
        }
        call(nil)
    }


    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        UIImagePicker.sWeakDict.remove(self)
        picker.dismiss(animated: true)

        call(nil)
    }

    private func call(_ any: Any?) {
        DispatchQueue.main.async {
            self.result(any)
        }
    }
}
