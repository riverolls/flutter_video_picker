# video_picker

无权限（弱权限）视频获取组件

## 使用
```
  video_picker:
    git:
      url: https://github.com/riverolls/flutter_video_picker.git
      tag: 1.0.0
```

## 接口

```dart
class VideoPicker {
  /// 从相册选取视频
  static Future<String?> chooseVideoFromGallery();

  /// 清空缓存
  static Future<void> clean();
}
```
