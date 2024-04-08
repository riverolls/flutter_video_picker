import 'package:flutter/material.dart';
import 'package:video_picker/video_picker.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  _AppState();

  String? currentPath;

  @override
  void initState() {
    super.initState();
    VideoPicker.clean();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Video Picker')),
        body: Center(child: Text('Path: $currentPath')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _chooseVideoFromGallery(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// 从图库选中视频
  void _chooseVideoFromGallery() async {
    final path = await VideoPicker.chooseVideoFromGallery();
    debugPrint("path >> $path");
    setState(() => currentPath = path);
  }
}
