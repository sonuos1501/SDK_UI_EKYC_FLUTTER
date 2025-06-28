import 'package:flutter/material.dart';

import 'package:uiux_ekyc_flutter_sdk/models/sdk_config.dart';
import 'face_validation/face_validation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SdkConfig sdkConfig;

  @override
  void initState() {
    super.initState();
    initSdkConfig();
    setState(() {});
  }

  void initSdkConfig() {
    sdkConfig = SdkConfig(
      apiUrl: "https://savis-ekyc.tunnel.techainer.com/api/v1/ekyc",
      source: "techainer",
      env: "dev",
      token: "74d479f61e1fef2961a6253f32922fcf1b6ff785",
      timeOut: 60,
      email: "",
      phone: "",
      backRoute: "/",
      urlVideoDetectFaceGuide:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      urlVideoAuthenGuide:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: FaceValidationScreen(sdkConfig: sdkConfig),
      ),
    );
  }
}
