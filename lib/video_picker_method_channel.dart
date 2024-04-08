import 'package:flutter/services.dart';

class MethodChannelVideoPicker {
  static const methodChannel = MethodChannel('com.rr.video.picker');

  /// 请求视频
  static Future<String?> chooseVideoFromGallery() async {
    final path = await methodChannel.invokeMethod<String?>(
      'chooseVideoFromGallery',
    );
    return path;
  }

  /// 清空缓存
  static Future<String?> clean() async {
    final path = await methodChannel.invokeMethod<String?>('clean');
    return path;
  }
}
