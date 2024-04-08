import 'package:video_picker/video_picker_method_channel.dart';

class VideoPicker {
  VideoPicker._();

  /// 从相册选取视频
  static Future<String?> chooseVideoFromGallery() {
    return MethodChannelVideoPicker.chooseVideoFromGallery();
  }

  /// 清空缓存
  static Future<void> clean() {
    return MethodChannelVideoPicker.clean();
  }
}
