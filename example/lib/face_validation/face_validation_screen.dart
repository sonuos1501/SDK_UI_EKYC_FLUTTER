import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uiux_ekyc_flutter_sdk/components/custom_text_style.dart';
import 'package:uiux_ekyc_flutter_sdk/models/sdk_config.dart';
import 'package:uiux_ekyc_flutter_sdk/uiux_ekyc_flutter_sdk.dart';
import 'package:uiux_ekyc_flutter_sdk_example/face_validation/app_config.dart';

class FaceValidationScreen extends StatefulWidget {
  const FaceValidationScreen({Key? key, required this.sdkConfig})
      : super(key: key);
  final SdkConfig sdkConfig;

  @override
  State<FaceValidationScreen> createState() => _FaceValidationScreenState();
}

class _FaceValidationScreenState extends State<FaceValidationScreen> {
  bool isSuccess = false;

  Future<void> faceValidationCallback(
      bool faceValidationResult,
      String videoPath,
      String errorCode,
      String message,
      Future<void> Function(dynamic result) backRecogScreenCallback) async {
    if (faceValidationResult) {
      var arr = videoPath.split("/");
      var fileName = arr[arr.length - 1];
      var newfile = File(videoPath);

      final appDir = Platform.isAndroid
          ? await getExternalStorageDirectory() //FOR ANDROID
          : await getApplicationSupportDirectory();

      final appPath = appDir!.path;
      final fileOnDevice = File('$appPath/$fileName'); //FOR ANDROID AND IOS
      await fileOnDevice.writeAsBytes(newfile.readAsBytesSync());
      if (AppConfig().sdkCallback != null) {
        AppConfig()
            .sdkCallback!
            .faceDeviceCheck(faceValidationResult, "", "", videoPath);
      }
    } else {
      if (AppConfig().sdkCallback != null) {
        AppConfig()
            .sdkCallback!
            .faceDeviceCheck(faceValidationResult, errorCode, message, "");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _getBody(),
        if (isSuccess) _getSuccessScreen(),
      ],
    );
  }

  _getBody() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Stack(fit: StackFit.expand, children: <Widget>[
        FaceValidationView(faceValidationCallback: faceValidationCallback),
      ]),
    );
  }

  _getSuccessScreen() {
    return Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        body: LayoutBuilder(
          builder: (context, contrains) {
            return Container(
              color: Colors.white,
              child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage(
                          'assets/images/ic_background_permission.png',
                          package: 'uiux_ekyc_flutter_sdk'),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                          top: contrains.maxHeight * 1 / 5,
                          left: 20,
                          right: 20,
                          child: _getSuccessWidget())
                    ],
                  )),
            );
          },
        ));
  }

  _getSuccessWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: 200,
          height: 148,
          child: Image.asset(
            'assets/images/ic_upload_face_success.png',
            package: 'uiux_ekyc_flutter_sdk',
          ),
        ),
        const SizedBox(height: 16),
        Text("Nhận diện khuôn mặt\n thành công!",
            textAlign: TextAlign.center, style: getTextStyleH2Bold()),
        const SizedBox(height: 4),
        Text("Dữ liệu khuôn mặt trùng khớp với giấy tờ đã chụp tài khoản.",
            textAlign: TextAlign.center, style: getTextStyleBodyLRegular()),
      ],
    );
  }
}
