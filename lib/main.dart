
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';



late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyHomePage());
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage? img;
  late CameraController controller;
  bool isBusy = false;
  String result = "";
  late ImageLabeler imageLabeler;

  @override
  void initState() {
    super.initState();
    imageLabeler = GoogleMlKit.vision.imageLabeler();
  }

  //Initialize camera
  initializeCamera () async
  {
    controller = CameraController(cameras[0], ResolutionPreset.max);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
        if(!isBusy){
          isBusy = true,
          img = image,
          doImageLabeling()
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }


  //Write image labeling code
  doImageLabeling() async{
    result = "";
    InputImage inputImg = getInputImage();
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImg);
    for (ImageLabel label in labels) {
      final String text = label.label;
      final int index = label.index;
      final double confidence = label.confidence;
      result+=text+"   "+confidence.toStringAsFixed(2)+"\n";
    }
    setState(() {
      result;
      isBusy = false;
    });

  }

  InputImage getInputImage()  {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in img!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
    Size(img!.width.toDouble(), img!.height.toDouble());

    final camera = cameras[0];
    final imageRotation =
    InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    // if (imageRotation == null) return;

    final inputImageFormat =
    InputImageFormatValue.fromRawValue(img!.format.raw);
    // if (inputImageFormat == null) return null;

    final planeData = img!.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );

    final inputImage =
    InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('images/img2.jpg'), fit: BoxFit.fill),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                          margin: EdgeInsets.only(top: 100),
                          height: 220,
                          width : 320,
                          child: Image.asset('images/lcd2.jpg')),
                    ),
                    Center(
                      child: FlatButton(
                        child: Container(
                          margin: EdgeInsets.only(top: 118),
                          height: 177,
                          width: 310,
                          child: img == null?Container(
                            width: 140,
                            height: 150,
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white,
                            ),
                          ):AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: CameraPreview(controller),
                          ),
                        ),
                        onPressed: (){
                          initializeCamera();
                        },
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Container(
                    height: 245,
                    child: SingleChildScrollView(
                        child: Text(
                          '$result',
                          style: TextStyle(
                              fontSize: 25,
                              color: Colors.black,
                              fontFamily: 'finger_paint'),
                          textAlign: TextAlign.center,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
