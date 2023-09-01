import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Quick camera prototype'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // we'll update this list, and use it to populate the gallery.
  List<Image> images = [];
  final ImagePicker picker = ImagePicker();

  _updateImageList() async {
    // realistically, search a directory named after the claim, not the
    // full documents directory.
    final Directory directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    List<Image> tempImages = [];
    for (final file in files) {
      final image = Image.file(File(file.path));
      tempImages.add(image);
    }
    setState(() {
      images = tempImages;
    });
  }

  _getCameraPermissions() async {
    final PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      // do nothing
    } else {
      // do something
    }
  }

  _getMicrophonePermissions() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      // do nothing
    } else {
      // do something
    }
  }

  _getGalleryPermissions() async {
    final PermissionStatus status = await Permission.mediaLibrary.request();
    if (status.isGranted) {
      // do nothing
    } else {
      // do something
    }
  }

  _selectPhotos() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final List<XFile?> selectedImages =
        await picker.pickMultiImage(requestFullMetadata: false);
    for (final image in selectedImages) {
      final name = image!.name;
      await image.saveTo('${directory.path}/$name');
      await _resizeImage(image);
    }
    _updateImageList();
  }

  _takeNewPhoto() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final XFile? image = await picker.pickImage(
        source: ImageSource.camera, requestFullMetadata: false);
    image?.saveTo('${directory.path}/${image.name}');
    _updateImageList();
  }

  // Resizes an image to 1/4 its size, to save space and upload time.
  // Note that this should not be used unless required.
  Future<XFile?> _resizeImage(XFile? image) async {
    if (image == null) {
      return null;
    }

    const maxSize = 1 * 1024 * 1024; // 1 MB
    final fileSize = await image.length();
    if (fileSize < maxSize) {
      return image;
    }

    final original = await img.decodeImageFile(image.path);
    if (original == null) {
      return null;
    }

    final originalHeight = original.height;
    final computedHeight = originalHeight / 2;
    final resized = img.copyResize(original, height: computedHeight.toInt());
    final jpeg = img.encodeJpg(resized, quality: 85);

    final Directory directory = await getApplicationDocumentsDirectory();
    final replacementPath = image.path.replaceAll('image_picker', 'resized');
    final xfile = XFile.fromData(jpeg, path: replacementPath);
    await xfile.saveTo('${directory.path}/${xfile.name}');
    await File(image.path).delete();
    return xfile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Gallery will go here, roughly',
              ),
              ...images.map((e) => SizedBox(child: e, height: 100, width: 100)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: FloatingActionButton(
              onPressed: _selectPhotos,
              tooltip: 'Choose photo',
              child: const Icon(Icons.image),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: _takeNewPhoto,
              tooltip: 'Take photo',
              child: const Icon(Icons.camera),
            ),
          ),
        ],
      ),
    );
  }
}
