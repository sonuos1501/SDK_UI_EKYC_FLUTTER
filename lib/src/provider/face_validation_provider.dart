import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:uiux_ekyc_flutter_sdk/src/helper/face_validation_status.dart';

import '../../constants.dart';

class FaceValidationNotifier {
  bool isRecording = false;
  bool canStart = false;
  String? arrowPath = null;
  StreamController<Uint8List?> imgStep1 = StreamController<Uint8List?>.broadcast();
  StreamController<Uint8List?> imgStep2 = StreamController<Uint8List?>.broadcast();
  StreamController<Uint8List?> imgStep3 = StreamController<Uint8List?>.broadcast();
  StreamController<Uint8List?> imgStep4 = StreamController<Uint8List?>.broadcast();
  StreamController<Uint8List?> imgStep5 = StreamController<Uint8List?>.broadcast();
  StreamController<String> stepResult = StreamController<String>.broadcast();
  String? strValidationResult;
  StreamController<String> validationResult = StreamController<String>.broadcast();
  StreamController<Color> faceMaskBorderColor = StreamController<Color>.broadcast();
  StreamController<bool> volumeStatus = StreamController<bool>.broadcast();
  late FaceValidationStatus faceValidateCurrentStatus;
  late int currentIndex;

  FaceValidationNotifier({required FaceValidationStatus currentStatus}) {
    faceValidateCurrentStatus = currentStatus;
    changeValidationResult("");
  }

  void changeRecordStatus(bool status) {
    isRecording = status;
    // notifyListeners();
  }

  void changeArrowPath(String path) {
    arrowPath = path;
    // notifyListeners();
  }

  void changeCanStartStatus(bool status) {
    canStart = status;
    // notifyListeners();
  }

  void changeValidationResult(String result) {
    if (strValidationResult == result) return;
    strValidationResult = result;
    validationResult.add(result);
    // notifyListeners();
  }

  void updateFaceValidateCurrentStatus(FaceValidationStatus status,int index,
      {String? messageError}) {
    faceValidateCurrentStatus = status;
    currentIndex = index;
    switch (status) {
      case FaceValidationStatus.WAITING:
        changeValidationResult(messageError ?? "");
        print("Notify change to WAITING");
        faceMaskBorderColor.add(kError300Color);
        break;
      case FaceValidationStatus.CHECKING_STRAIGHT:
        changeValidationResult("");
        print("Notify change to CHECKING_STRAIGHT");
        stepResult.add("Nhìn thẳng");
        faceMaskBorderColor.add(kNeutral200Color);
        break;
      case FaceValidationStatus.CHECKING_RIGHT:
        print("Notify change to CHECKING_RIGHT");
        changeValidationResult("");
        stepResult.add("Quay phải");
        faceMaskBorderColor.add(kNeutral200Color);
        break;
      case FaceValidationStatus.CHECKING_LEFT:
        print("Notify change to CHECKING_LEFT");
        changeValidationResult("");
        // update step2 done
        faceMaskBorderColor.add(kNeutral200Color);
        stepResult.add("Quay trái");
        break;
      case FaceValidationStatus.CHECKING_CLOSE_ONE_EYE:
        print("Notify change to CHECKING_CLOSE_ONE_EYE");
        changeValidationResult("");
        // update step2 done
        faceMaskBorderColor.add(kNeutral200Color);
        stepResult.add("Nháy mắt");
        break;
      case FaceValidationStatus.CHECKING_DOWN:
        print("Notify change to CHECKING_DOWN");
        changeValidationResult("");
        // update step2 done
        faceMaskBorderColor.add(kNeutral200Color);
        stepResult.add("Nhìn xuống");
        break;
      case FaceValidationStatus.CHECKING_UP:
        print("Notify change to CHECKING_UP");
        changeValidationResult("");
        // update step2 done
        faceMaskBorderColor.add(kNeutral200Color);
        stepResult.add("Nhìn lên");
        break;
      case FaceValidationStatus.DONE:
        faceMaskBorderColor.add(kSuccess400Color);
        changeValidationResult("Hoàn Thành");
        stepResult.add("Hoàn Thành");
        break;
      default:
        changeValidationResult("Đưa mặt vào trong khung hình");
        break;
    }
    print("Notify face validation notifyListeners");
    // notifyListeners();
  }

  void resetStatus(FaceValidationStatus faceValidationStatus, int index) {
    faceValidateCurrentStatus = FaceValidationStatus.DEFAULT;
    faceMaskBorderColor.add(kNeutral200Color);
    imgStep1.add(null);
    imgStep2.add(null);
    imgStep3.add(null);
    imgStep4.add(null);
    imgStep5.add(null);
    stepResult.add(_getStep(faceValidationStatus));
    currentIndex = index;
  }

  String _getStep(FaceValidationStatus status) {
    switch (status) {
      case FaceValidationStatus.CHECKING_STRAIGHT:
        return "Nhìn thẳng";
      case FaceValidationStatus.CHECKING_RIGHT:
        return "Quay phải";
      case FaceValidationStatus.CHECKING_LEFT:
        return "Quay trái";
      case FaceValidationStatus.CHECKING_CLOSE_ONE_EYE:
        return "Nháy mắt";
      case FaceValidationStatus.CHECKING_DOWN:
        return "Nhìn xuống";
      case FaceValidationStatus.CHECKING_UP:
        return "Nhìn lên";
      default:
        return "";
    }
  }

  void updateFaceMaskBorderNormal({int time = 300}) {
    if (time > 0) {
      Future.delayed(Duration(milliseconds: time), () {
        print("Notify change border to white");
        faceMaskBorderColor.add(kSuccess400Color);
        // notifyListeners();
      });
    }
  }

  void updateFaceMaskBorderColor(Color color) {
    faceMaskBorderColor.add(color);
  }

  void changeImageStep(int  index, Uint8List? img) {
    if (img == null) return;
    switch (index) {
      case 0:
        imgStep1.add(img);
        break;
      case 1:
        imgStep2.add(img);
        break;
      case 2:
        imgStep3.add(img);
        break;
      case 3:
        imgStep4.add(img);
        break;
      case 4:
        imgStep5.add(img);
        break;
    }
  }
}
