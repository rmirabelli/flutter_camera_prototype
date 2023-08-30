import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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

  _selectPhotos() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final List<XFile?> selectedImages =
        await picker.pickMultiImage(requestFullMetadata: false);
    for (final image in selectedImages) {
      final name = image!.name;
      image.saveTo('${directory.path}/$name');
    }
    setState(() {
      // eventually set the list of images, so there's something meaningful as a result.
    });
  }

  _takeNewPhoto() async {
    final XFile? selectedImages = await picker.pickImage(
        source: ImageSource.camera, requestFullMetadata: false);
    print('$selectedImages.length');

    setState(() {
      // eventually set the list of images, so there's something meaningful as a result.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Gallery will go here, roughly',
            ),
          ],
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
