import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

// A single-screen app to go over most of the photo functionality.
// There's definitely cleanup work to do, but the core elements
// _work_, which is the important part.

// The 'img' package is needed because the traditional Image class
// doesn't have a resize function.  This is a bit of a pain, but
// it's not too bad.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Prototype',
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
    // full documents directory, OR filter based on the claim name.
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

  // check the permissions on page load and after each action.
  // This will allow us to disable the buttons if the user has not
  // granted permissions.
  // We don't want to ask for permissions on page load, because
  // that's annoying and we don't want to do it every time.
  // This is going to give us the best user experience and allow
  // rate.
  // The camera button should require both camera and microphone
  // (microphone may be a null operation on android) because
  // of live photos.
  _checkCameraPermissions() async {
    final PermissionStatus status = await Permission.camera.status;
    if (status.isDenied) {
      // Disable the button
    }
  }

  _checkMicrophonePermissions() async {
    final PermissionStatus status = await Permission.microphone.status;
    if (status.isDenied) {
      // Disable the button
    }
  }

  _checkGalleryPermissions() async {
    final PermissionStatus status = await Permission.mediaLibrary.status;
    if (status.isDenied) {
      // Disable the button
    }
  }

  // choose photos from the image picker.
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

  // choose photos from the camera.
  _takeNewPhoto() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final XFile? image = await picker.pickImage(
        source: ImageSource.camera, requestFullMetadata: false);
    image?.saveTo('${directory.path}/${image.name}');
    // resize it, I suppose.
    _updateImageList();
  }

  // Resizes an image to 1/4 its size, to save space and upload time.
  // Note that this should not be used unless required (i.e. this won't)
  // resize unless we're larger than the max size, but the max size in
  // this function is set pretty darn low, so we can test it easily.
  Future<XFile?> _resizeImage(XFile? image) async {
    if (image == null) {
      return null;
    }

    const maxSize = 1 * 1024 * 1024; // 1 MB, needs to be 10 for shippping
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
