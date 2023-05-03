import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class HomePage extends StatelessWidget {
  const HomePage(this.uid,{super.key}) ;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await availableCameras().then(
                  (value) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraPage(cameras: value,uid: uid),
                ),
              ),
            );
          },
          child: const Text('Launch Camera'),
        ),
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const CameraPage({this.cameras, required this.uid, Key? key}) : super(key: key);
  final String uid;

  @override
  _CameraPageState createState() => _CameraPageState(uid:uid);
}

class _CameraPageState extends State<CameraPage> {
  _CameraPageState({required this.uid});
  late CameraController controller;
  XFile? pictureFile;
  final  String uid;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.cameras![0],
      ResolutionPreset.max,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: SizedBox(
              height: 700,
              width: 400,
              child: CameraPreview(controller),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              pictureFile = await controller.takePicture();
              setState(() {});
              if (pictureFile != null){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ImagePreview(path:pictureFile!.path,uid:uid)),
                );
              }else{
                AlertDialog(
                  content: const Text("Image capture failed "),
                  actions: [
                    ElevatedButton(
                      child: const Text("Ok"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePage(uid)),
                        );
                      },
                    )
                  ],
                );
              }
                // // Image.network(
                // //   pictureFile!.path,
                // //   height: 200,
                // // )
                // //Android/iOS
                // Uploadimage(uid: uid, url: File(pictureFile!.path))),


            },
            child: const Text('Capture Image'),
          ),
        ),


      ],
    );
  }
}

class Uploadimage{

  final String uid;
  final String url;

  Uploadimage({ required this.uid, required this.url});

  // collection reference
  final CollectionReference brewCollection = FirebaseFirestore.instance.collection('images');

  Future updateData() async {
    return await brewCollection.doc(uid).get().then((docSnapshot) =>
    {
      if (docSnapshot.exists) {
        brewCollection.doc(uid).update({
          "Image_url": FieldValue.arrayUnion(
              [{"url": url}]),
        }),
      } else
        {
          brewCollection.doc(uid).set({
            "Image_url": FieldValue.arrayUnion(
                [{"url": url}]),
          }),
        }
    });
  }
}

class FirebaseApi {
  static UploadTask? uploadFile(String destination, File file) {
    try {
      final ref = FirebaseStorage.instance.ref(destination);

      return ref.putFile(file);
    } on FirebaseException catch (e) {
      return null;
    }
  }
}

class ImagePreview extends StatefulWidget {
  const ImagePreview({required this.path, required this.uid, Key? key})
      : super(key: key);

  final String path;
  final String uid;

  @override
  _ImagePreviewState createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: SizedBox(
              height: 700,
              width: 400,
              child: Image.file(File(widget.path)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0,horizontal: 60.0),
                child: ElevatedButton(
                  child: const Text("Confirm"),
                  onPressed: () async {
                    final fileName = basename(File(widget.path).path);
                    final destination = 'files/$fileName';
                    var task = FirebaseApi.uploadFile(destination, File(widget.path));
                    setState(() {});
                    if (task == null) return;
                    final snapshot = await task!.whenComplete(() {});
                    final urlDownload = await snapshot.ref.getDownloadURL();
                    await Uploadimage(uid: widget.uid, url: urlDownload).updateData();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: const Text("Image uploaded successfully"),
                          actions: [
                            ElevatedButton(
                              child: const Text("Ok"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(widget.uid),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0,horizontal: 40.0),
                child: ElevatedButton(
                  child: const Text("Cancel"),
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(widget.uid),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
