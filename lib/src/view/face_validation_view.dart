// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:ekyc_flutter_sdk/ekyc_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as imglib;
import 'package:uiux_ekyc_flutter_sdk/components/custom_text_style.dart';
import 'package:uiux_ekyc_flutter_sdk/constants.dart';
import 'package:uiux_ekyc_flutter_sdk/src/callback/face_validation_callback.dart';
import 'package:uiux_ekyc_flutter_sdk/src/helper/face_validation_status.dart';
import 'package:uiux_ekyc_flutter_sdk/src/widgets/face_scanner.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../uiux_ekyc_flutter_sdk.dart';
import '../provider/face_validation_provider.dart';

enum TtsState { playing, stopped, paused, continued }

class StepValidation {
  FaceValidationStatus faceValidationStatus;
  bool isValid;
  String pathDefault;

  StepValidation({
    required this.faceValidationStatus,
    required this.pathDefault,
    required this.isValid,
  });
}

class FaceValidationView extends StatefulWidget {
  FaceValidationCallback faceValidationCallback;

  FaceValidationView({Key? key, required this.faceValidationCallback})
      : super(key: key);

  double valuedProcess = 0.0;

  @override
  _FaceValidationViewState createState() => _FaceValidationViewState();
}

class _FaceValidationViewState extends State<FaceValidationView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static String TAG = "Notify -------------->";
  double selectVolume = 0.5;
  bool _isInitVolume = false;
  CameraController? cameraController;
  bool isCameraReady = false;
  bool isCameraResume = false;
  bool isCapture = false;
  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.continued;
  late CameraImage currentImage;
  late double screenWidth, screenHeight;
  late double _cardAreaLeft, _cardAreaTop, _cardAreaHeight, _cardAreaWidth;
  FaceValidation? faceValidation;
  Color boderColor = Colors.white;
  bool isInit = false;
  CameraDescription? chooseCamera;

  // static const double CHECK_STEP_1 = 26.0;
  // static const double CHECK_STEP_2 = 21.0;
  // static const double CHECK_STEP_3 = 16.0;
  //
  // // static const double CHECK_CLOSE_ONE_EYE = 9;
  // static const double CHECK_STEP_4 = 11.0;
  // static const double CHECK_STEP_5 = 6.0;
  // static const double CHECK_DONE = 0.0;
  static const double CHECK_STEP_1 = 16.0;
  static const double CHECK_STEP_2 = 11.0;
  static const double CHECK_STEP_3 = 6.0;

  // static const double CHECK_CLOSE_ONE_EYE = 9;
  // static const double CHECK_STEP_4 = 11.0;
  // static const double CHECK_STEP_5 = 6.0;
  static const double CHECK_DONE = 0.0;
  static const int INVALID_POSITION = -1;
  FaceValidationNotifier faceValidationNotifier =
      FaceValidationNotifier(currentStatus: FaceValidationStatus.WAITING);
  late FaceValidationCallback faceValidationCallback;

  int countDetectFailedFrame = 0;
  int countLivenessFailedFrame = 0;
  int maxDetectFrameFailed = 10;
  int maxLivenessFrameFailed = 4;
  StreamController<OutputFaceResult>? streamController;
  var stepValidationDefault = [
    StepValidation(
        faceValidationStatus: FaceValidationStatus.CHECKING_STRAIGHT,
        pathDefault: "assets/images/ic_face_center.png",
        isValid: false),
    StepValidation(
        faceValidationStatus: FaceValidationStatus.CHECKING_LEFT,
        pathDefault: "assets/images/ic_face_left.png",
        isValid: false),
    StepValidation(
        faceValidationStatus: FaceValidationStatus.CHECKING_RIGHT,
        pathDefault: "assets/images/ic_face_right.png",
        isValid: false),
    // StepValidation(
    //     faceValidationStatus: FaceValidationStatus.CHECKING_DOWN,
    //     pathDefault: "assets/images/ic_face_down.png",
    //     isValid: false),
    // StepValidation(
    //     faceValidationStatus: FaceValidationStatus.CHECKING_UP,
    //     pathDefault: "assets/images/ic_face_up.png",
    //     isValid: false),
  ];

  late List<StepValidation> stepValidation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    faceValidationCallback = widget.faceValidationCallback;
    _initAudioPlay();
    _resetStatus();
    _initializeCamera();
    _listenerVolume();
  }

  void _listenerVolume() {
    VolumeController().listener((volume) {
      if (selectVolume == 0 && volume > 0.5) return;
      selectVolume = volume;
      if (volume == 0) {
        faceValidationNotifier.volumeStatus.add(true);
        selectedAudioPlayer?.setVolume(0.5);
        VolumeController().setVolume(0.5);
      } else {
        faceValidationNotifier.volumeStatus.add(false);
        selectedAudioPlayer?.setVolume(volume);
      }
    });
  }

  AudioPlayer? selectedAudioPlayer;
  List<StreamSubscription> streams = [];

  void _initAudioPlay() {
    try {
      selectedAudioPlayer = AudioPlayer();
      selectedAudioPlayer?.setReleaseMode(ReleaseMode.stop);
      selectedAudioPlayer?.audioCache = AudioCache(prefix: "");

      // Add error handling for audio player
      var subscription =
          selectedAudioPlayer?.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          // Handle completion if needed
        }
      });

      if (subscription != null) {
        streams.add(subscription);
      }
    } catch (e) {
      print("Error initializing audio player: $e");
    }
  }

  _speakByIndex(FaceValidationStatus status) async {
    AssetSource? source;
    switch (status) {
      case FaceValidationStatus.WAITING:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/khong-nhan-dien-duoc-khuon-mat.mp3');
        break;
      case FaceValidationStatus.CHECKING_STRAIGHT:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/nhin-thang.mp3');
        break;
      case FaceValidationStatus.CHECKING_RIGHT:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/quay-phai.mp3');
        break;
      case FaceValidationStatus.CHECKING_LEFT:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/quay-trai.mp3');
        break;
      case FaceValidationStatus.CHECKING_CLOSE_ONE_EYE:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/nhay-mat.mp3');
        break;
      case FaceValidationStatus.CHECKING_DOWN:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/nhin-xuong.mp3');
        break;
      case FaceValidationStatus.CHECKING_UP:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/nhin-len.mp3');
        break;
      case FaceValidationStatus.DONE:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/hoan-thanh.mp3');
        break;
      default:
        source = AssetSource(
            'packages/uiux_ekyc_flutter_sdk/assets/audios/dua-mat-vao-trong-khung-hinh.mp3');
        break;
    }
    if (!_isInitVolume) {
      _isInitVolume = true;
      var _getVolume = await VolumeController().getVolume();
      selectVolume = _getVolume;
      if (_getVolume == 0) {
        faceValidationNotifier.volumeStatus.add(true);
        selectedAudioPlayer?.setVolume(0.5);
        VolumeController().setVolume(0.5);
      } else {
        faceValidationNotifier.volumeStatus.add(false);
        selectedAudioPlayer?.setVolume(_getVolume);
      }
    }

    if (selectedAudioPlayer != null &&
        selectedAudioPlayer?.source.toString() !=
            source.toString().toString()) {
      try {
        await selectedAudioPlayer?.stop();
        await selectedAudioPlayer?.play(source);
      } catch (e) {
        print("Error playing audio: $e");
      }
    }
  }

  @override
  void didUpdateWidget(FaceValidationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (widget.valuedProcess == 0.0 && !_controller.isAnimating) {
    //   _controller.repeat();
    // } else if (widget.valuedProcess != 0.0 && _controller.isAnimating) {
    //   _controller.stop();
    // }
  }

  Future<void> _initializeCamera() async {
    final CameraController? oldController = cameraController;
    if (oldController != null) {
      //   // `controller` needs to be set to null before getting disposed,
      //   // to avoid a race condition when we use the controller that is being
      //   // disposed. This happens when camera permission dialog shows up,
      //   // which triggers `didChangeAppLifecycleState`, which disposes and
      //   // re-creates the controller.
      cameraController = null;
      await oldController.dispose();
    }
    // final cameras = await availableCameras();
    // for (int i = 0; i < cameras.length; i++) {
    //   if (cameras[i].lensDirection == CameraLensDirection.front) {
    //     chooseCamera = cameras[i];
    //     break;
    //   }
    // }
    // cameraController = CameraController(
    //   chooseCamera!,
    //   ResolutionPreset.high,
    //   enableAudio: true,
    //   imageFormatGroup: ImageFormatGroup.jpeg,
    // );
    // // If the controller is updated then update the UI.
    // cameraController?.addListener(() {
    //   if (mounted) {
    //     setState(() {});
    //   }
    //   if (cameraController!.value.hasError) {}
    // });
    //
    // try {
    //   await cameraController?.initialize();
    // } on CameraException catch (e) {
    //   print(e.description);
    // }
    //
    // if (mounted) {
    //   setState(() {
    //     isCameraReady = true;
    //     isCameraResume = true;
    //   });
    // }
    // setState(() {
    //   stepValidation = stepValidationDefault..shuffle();
    // });
    final cameras = await availableCameras();
    for (int i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == CameraLensDirection.front) {
        chooseCamera = cameras[i];
        break;
      }
    }
    if (chooseCamera == null) {
      print("$TAG Can't select camera !!!");
      return;
    }
    cameraController = CameraController(chooseCamera!, ResolutionPreset.high,
        enableAudio: true);
    cameraController?.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController?.value.hasError == true) {
      print('$TAG Camera Error ${cameraController?.value.errorDescription}');
    }
    try {
      await cameraController?.initialize();
    } catch (e) {
      print('$TAG Camera Error $e');
    }

    if (mounted) {
      setState(() {
        isCameraReady = true;
        isCameraResume = true;
      });
      _speakByIndex(FaceValidationStatus.DEFAULT);
      _resetStatus(change: false);
      _startStream();
    }
  }

  _startStream() {
    if (cameraController != null &&
        cameraController?.value.isInitialized == true) {
      cameraController?.startImageStream((CameraImage image) {
        if (faceValidation != null && isCameraResume && !isStartingRecording) {
          print("LONGNV, stream on _startStream");
          faceValidation!.runDetect(image);
        }
      });
    }
  }

  _resetStatus({bool change = true, bool isSpeak = true}) {
    if (change) {
      setState(() {
        stepValidation = stepValidationDefault..shuffle();
      });
    }
    if (isSpeak) _speakByIndex(FaceValidationStatus.DEFAULT);
    _start = CHECK_STEP_1 + 1;
    for (var e in stepValidation) {
      e.isValid = false;
    }
    faceValidationNotifier.resetStatus(
        stepValidation[0].faceValidationStatus, INVALID_POSITION);
  }

  Future<void> _disposeCamera() async {
    isCameraReady = false;
    isCameraResume = false;
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (cameraController != null) {
        cameraController?.dispose();
        cameraController = null;
      }
    });
  }

  Future<void> _pauseCamera() async {
    Future<void>.delayed(const Duration(milliseconds: 50), () async {
      if (cameraController != null) {
        print("$TAG _pauseCamera");
        await cameraController?.pausePreview();
        setState(() {
          isCameraResume = false;
        });
      }
    });
  }

  Future<void> _resumeCamera() async {
    Future<void>.delayed(const Duration(milliseconds: 50), () async {
      if (cameraController != null) {
        print("$TAG _resumeCamera");
        _resetStatus();
        await cameraController?.resumePreview();
        setState(() {
          isCameraResume = true;
        });
      }
    });
  }

  Future<void> _onCallBackResume(dynamic resultBack) {
    if (resultBack == CameraStatus.DISPOSE) {
      return _disposeCamera();
    }
    if (resultBack == CameraStatus.PAUSE_PREVIEW) {
      return _pauseCamera();
    }
    if (resultBack == CameraStatus.INIT) {
      return _initializeCamera();
    }
    if ((isCameraReady &&
            cameraController != null &&
            !isCameraResume &&
            cameraController?.hasListeners == true) ||
        resultBack == CameraStatus.RESUME_PREVIEW) {
      return _resumeCamera();
    } else {
      return Future(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (ModalRoute.of(context)?.isCurrent == true) {
      if (state == AppLifecycleState.resumed) {
        _resumeCamera();
      } else if (state == AppLifecycleState.inactive) {
        // disposeCamera();
      } else if (state == AppLifecycleState.paused) {
        stopTime();
        cameraController?.stopVideoRecording(isStopStream: false).then((value) {
          print("$TAG stopVideoRecording");
          _pauseCamera();
        }).onError((error, stackTrace) {
          print("$TAG stopVideoRecording $error");
          _pauseCamera();
        });
        faceValidationNotifier.changeCanStartStatus(false);
        faceValidationNotifier.changeRecordStatus(false);
        _resetStatus(isSpeak: false);
      } else if (state == AppLifecycleState.detached) {
        _stopRecordVideo(context);
        selectedAudioPlayer?.stop().catchError((onError) {});
        selectedAudioPlayer?.release().catchError((onError) {});
        _disposeCamera();
      }
    }
  }

  Timer? _timer;
  double _start = CHECK_STEP_1 + 1;

  void stopTime() {
    if (_timer != null) {
      print("$TAG TIME stopTime");
      _timer!.cancel();
    }
  }

  void startTimer(BuildContext context) {
    const oneSec = Duration(milliseconds: 500);
    _logTime("$TAG startTimer");
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        _logTime("$TAG startTimer $_start");
        if (_start < CHECK_STEP_3 && _start >= CHECK_DONE) {
          print("$TAG TIME CHECK_DONE");
          // count done left
          if (_start == CHECK_DONE) {
            _start = _start - 0.5;
            print("$TAG TIME start == CHECK_DONE");
            if (stepValidation
                .where((element) => element.isValid == false)
                .isNotEmpty) {
              _stopVideoAndResetTime(
                  "step5Fail", "Lỗi xảy ra khi thực hiện bước 5");
            }
          } else {
            _start = _start - 0.5;
          }
          if (stepValidation
                  .where((element) => element.isValid == false)
                  .isEmpty &&
              _start < CHECK_STEP_3 - 1) {
            _speakByIndex(FaceValidationStatus.DONE);
            faceValidationNotifier.updateFaceValidateCurrentStatus(
                FaceValidationStatus.DONE, INVALID_POSITION);
            _start = -1;
            _stopRecordVideo(context, isRecordDone: true);
          }
        } else {
          if (_start == CHECK_STEP_1) {
            print("$TAG TIME _start == CHECK_STEP_1");
            _speakByIndex(stepValidation[0].faceValidationStatus);
            faceValidationNotifier.updateFaceValidateCurrentStatus(
                stepValidation[0].faceValidationStatus, 0);
          }
          if (_start < CHECK_STEP_1 && _start >= CHECK_STEP_2) {
            // count done straight
            if (_start == CHECK_STEP_2) {
              print("$TAG TIME _start == CHECK_STEP_2");
              if (!stepValidation[0].isValid) {
                _stopVideoAndResetTime(
                    "step1Fail", "Lỗi xảy ra khi thực hiện bước 1");
              }
            }
            if (stepValidation[0].isValid && _start < CHECK_STEP_1 - 1) {
              faceValidationNotifier.updateFaceMaskBorderColor(Colors.green);

              _start = CHECK_STEP_2;
              _speakByIndex(stepValidation[1].faceValidationStatus);
              Future.delayed(const Duration(milliseconds: 100), () {
                faceValidationNotifier.updateFaceValidateCurrentStatus(
                    stepValidation[1].faceValidationStatus, 1);
              });
            }
          }
          if (_start < CHECK_STEP_2 && _start >= CHECK_STEP_3) {
            // count done right
            if (_start == CHECK_STEP_3) {
              print("$TAG TIME _start == CHECK_STEP_3");
              if (!stepValidation[1].isValid || !stepValidation[0].isValid) {
                _stopVideoAndResetTime(
                    "step2Fail", "Lỗi xảy ra khi thực hiện bước 2");
              }
            }
            if (stepValidation[1].isValid &&
                stepValidation[0].isValid &&
                _start < CHECK_STEP_2 - 1) {
              faceValidationNotifier.updateFaceMaskBorderColor(Colors.green);
              _start = CHECK_STEP_3;
              _speakByIndex(stepValidation[2].faceValidationStatus);
              Future.delayed(const Duration(milliseconds: 100), () {
                faceValidationNotifier.updateFaceValidateCurrentStatus(
                    stepValidation[2].faceValidationStatus, 2);
              });
            }
          }

          // if (_start < CHECK_STEP_3 && _start >= CHECK_STEP_4) {
          //   // count done right
          //   if (_start == CHECK_STEP_4) {
          //     print("$TAG TIME _start == CHECK_STEP_4");
          //     if (!stepValidation[2].isValid ||
          //         !stepValidation[1].isValid ||
          //         !stepValidation[0].isValid) {
          //       _stopVideoAndResetTime(
          //           "step3Fail", "Lỗi xảy ra khi thực hiện bước 3");
          //     }
          //   }
          //   if (stepValidation[2].isValid &&
          //       stepValidation[1].isValid &&
          //       stepValidation[0].isValid &&
          //       _start < CHECK_STEP_3 - 1) {
          //     faceValidationNotifier.updateFaceMaskBorderColor(Colors.green);
          //     _start = CHECK_STEP_4;
          //     _speakByIndex(stepValidation[3].faceValidationStatus);
          //     Future.delayed(const Duration(milliseconds: 100), () {
          //       faceValidationNotifier.updateFaceValidateCurrentStatus(
          //           stepValidation[3].faceValidationStatus, 3);
          //     });
          //   }
          // }
          // if (_start < CHECK_STEP_4 && _start >= CHECK_STEP_5) {
          //   // count done right
          //   if (_start == CHECK_STEP_5) {
          //     print("$TAG TIME _start == CHECK_STEP_5");
          //     if (!stepValidation[3].isValid ||
          //         !stepValidation[1].isValid ||
          //         !stepValidation[2].isValid ||
          //         !stepValidation[0].isValid) {
          //       _stopVideoAndResetTime(
          //           "step4Fail", "Lỗi xảy ra khi thực hiện bước 4");
          //     }
          //   }
          //
          //   if (stepValidation[3].isValid &&
          //       stepValidation[1].isValid &&
          //       stepValidation[2].isValid &&
          //       stepValidation[0].isValid &&
          //       _start < CHECK_STEP_4 - 1) {
          //     faceValidationNotifier.updateFaceMaskBorderColor(Colors.green);
          //     _start = CHECK_STEP_5;
          //     _speakByIndex(stepValidation[4].faceValidationStatus);
          //     Future.delayed(const Duration(milliseconds: 100), () {
          //       faceValidationNotifier.updateFaceValidateCurrentStatus(
          //           stepValidation[4].faceValidationStatus, 4);
          //     });
          //   }
          // }
          _start = _start - 0.5;
        }
      },
    );
  }

  void faceDetectCallBack(
      List<Detection> detection,
      imglib.Image? img,
      bool detectResult,
      String resultName,
      String message,
      double leftAndRigtPercent,
      double trenDuoi,
      Uint8List? imageByte) {
    if (isCameraResume && !isStartingRecording) {
      _startRecordVideo(context, isStartTime: true);
    }
    if (faceValidationNotifier.isRecording == true) {
      if (faceValidationNotifier.currentIndex == INVALID_POSITION) return;
      var currentIndex = faceValidationNotifier.currentIndex;
      print("$TAG faceDetectCallBack "
          "faceValidationStatus: ${stepValidation[currentIndex].faceValidationStatus}"
          "isValid: ${stepValidation[currentIndex].isValid} "
          "leftAndRigtPercent: $leftAndRigtPercent "
          "trenDuoi: $trenDuoi "
          "currentIndex: $currentIndex");

      switch (stepValidation[currentIndex].faceValidationStatus) {
        case FaceValidationStatus.CHECKING_STRAIGHT:
          if (!stepValidation[currentIndex].isValid &&
                  detectResult &&
                  -50 < leftAndRigtPercent &&
                  leftAndRigtPercent < 50
              // && trenDuoi == 150
              ) {
            faceValidationNotifier.changeImageStep(currentIndex, imageByte);
            stepValidation[currentIndex].isValid = true;
          }
          break;
        case FaceValidationStatus.CHECKING_LEFT:
          if (!stepValidation[currentIndex].isValid && leftAndRigtPercent < -60
              // && trenDuoi == 150
              ) {
            faceValidationNotifier.changeImageStep(currentIndex, imageByte);
            stepValidation[currentIndex].isValid = true;
          }
          break;
        case FaceValidationStatus.CHECKING_RIGHT:
          if (!stepValidation[currentIndex].isValid && leftAndRigtPercent > 60
              // && trenDuoi == 150
              ) {
            stepValidation[currentIndex].isValid = true;
            faceValidationNotifier.changeImageStep(currentIndex, imageByte);
          }
          break;
        case FaceValidationStatus.CHECKING_DOWN:
          if (!stepValidation[currentIndex].isValid && trenDuoi > 166) {
            stepValidation[currentIndex].isValid = true;
            faceValidationNotifier.changeImageStep(currentIndex, imageByte);
          }
          break;
        case FaceValidationStatus.CHECKING_UP:
          if (!stepValidation[currentIndex].isValid && trenDuoi < 147) {
            stepValidation[currentIndex].isValid = true;
            faceValidationNotifier.changeImageStep(currentIndex, imageByte);
          }
          break;
        case FaceValidationStatus.DEFAULT:
        case FaceValidationStatus.WAITING:
        case FaceValidationStatus.CHECKING_CLOSE_ONE_EYE:
        case FaceValidationStatus.DONE:
          break;
      }
    }
  }

  var isStartingRecording = false;

  // void faceLivenessCallBack(bool livenessResult, String resultName,
  //     String message) {
  //   if (!isPrepareRestart) return;
  //   if (faceValidationNotifier.isRecording == false) {
  //     if (!livenessResult) {
  //       // _speakByIndex(FaceValidationStatus.DEFAULT);
  //       faceValidationNotifier.changeValidationResult(message.toString());
  //     } else {
  //       if (isCameraResume && !isStartingRecording) {
  //         _startRecordVideo(context, isStartTime: true);
  //       }
  //     }
  //   } else {
  //     if (livenessResult &&
  //         (resultName == "SMALL_FACE" ||
  //             resultName == "TWO_FACE" ||
  //             resultName == "BIG_FACE")) {
  //       faceValidationNotifier.changeValidationResult(message.toString());
  //     }
  //   }
  // }

  @override
  void dispose() {
    if (cameraController != null) {
      cameraController?.dispose();
    }
    faceValidation?.closeAllStream();
    _stopRecordVideo(context);
    stopTime();

    // Properly dispose audio player
    try {
      selectedAudioPlayer?.stop();
      selectedAudioPlayer?.dispose();
    } catch (e) {
      print("Error disposing audio player: $e");
    }

    // Dispose stream subscriptions
    for (var subscription in streams) {
      subscription.cancel();
    }
    streams.clear();

    _disposeCamera();
    VolumeController().removeListener();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  late SdkConfig sdkConfig;

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    getScannerSize();
    if (!isInit && chooseCamera != null && isCameraReady) {
      MaskView maskView = MaskView(
          _cardAreaLeft, _cardAreaTop, _cardAreaWidth, _cardAreaHeight);
      sdkConfig = SdkConfig(MediaQuery.of(context).size, maskView,
          ValidationStep.CARDBACK, chooseCamera!);
      faceValidation = FaceValidation(
        sdkConfig,
        faceDetectionCallBack: faceDetectCallBack,
        // faceLivenessCallBack: faceLivenessCallBack
      );
      // faceValidation?.resultFaceLivenessStream?.listen((event) {
      //   faceLivenessCallBack(
      //       event.livenessResult, event.resultName, event.message);
      // });
      faceValidation?.resultFaceDetectStream?.listen((event) {
        faceDetectCallBack(
            event.detection,
            event.img,
            event.detectResult,
            event.resultName,
            event.message,
            event.leftAndRigtPercent,
            event.trenDuoi,
            event.imageByte);
      });
      isInit = true;
    }
    return getBody();
  }

  void getScannerSize() {
    const _CARD_ASPECT_RATIO = 1.25 / 1;
    const _OFFSET_X_FACTOR = 0.15;
    final screenRatio = screenWidth / screenHeight;

    _cardAreaLeft = _OFFSET_X_FACTOR * screenWidth.round();
    _cardAreaWidth = screenWidth.round() - _cardAreaLeft * 2;
    _cardAreaHeight = _cardAreaWidth * _CARD_ASPECT_RATIO;
    _cardAreaTop = MediaQuery.of(context).padding.top + 74 + 15;
    // (screenHeight.round() - screenHeight.round() * 0.15 - _cardAreaHeight) /
    //     2;
    getScannerRealSize();
  }

  late double _cardAreaLeftR, _cardAreaTopR, _cardAreaHeightR, _cardAreaWidthR;

  void getScannerRealSize() {
    const _OFFSET_X_FACTOR = 0.08;
    _cardAreaLeftR = _OFFSET_X_FACTOR * screenWidth;
    _cardAreaWidthR = screenWidth - _cardAreaLeftR * 2;
    _cardAreaHeightR = _cardAreaWidthR;
    _cardAreaTopR = MediaQuery.of(context).padding.top + 74 + 15;
    // (screenHeight - screenHeight * 0.15 - _cardAreaHeightR) / 2;
  }

  _startRecordVideo(BuildContext context, {bool isStartTime = true}) {
    if (cameraController == null ||
        cameraController?.value.isRecordingVideo == true ||
        faceValidationNotifier.isRecording) {
      return;
    }
    isStartingRecording = true;
    cameraController?.stopImageStream().then((value) {
      cameraController?.prepareForVideoRecording().then((value) {
        try {
          cameraController?.startVideoRecording(
              onAvailable: (CameraImage image) {
            print("LONGNV, stream on startVideoRecording");
            if (faceValidation != null && isCameraResume) {
              faceValidation?.runDetect(image);
            }
          }).then((value) {
            isStartingRecording = false;
            faceValidationNotifier.changeRecordStatus(true);
            if (_timer?.isActive != true) startTimer(context);
          });
        } catch (ex) {
          print(ex);
        }
      });
    });
  }

  Future<void> failedFunction() async {}

  _stopRecordVideo(BuildContext context,
      {bool isRecordDone = false,
      String errorCode = "",
      String errMessage = "Xin hãy thực hiện theo hướng dẫn"}) {
    if (faceValidationNotifier.isRecording == true) {
      final CameraController? controller = cameraController;

      if (controller == null || !controller.value.isRecordingVideo) {
        return null;
      }

      if (isRecordDone == true) {
        stopTime();
        XFile? file;
        try {
          controller.stopVideoRecording().then((value) async {
            if (cameraController != null) {
              print("$TAG _pauseCamera");
              await cameraController
                  ?.pausePreview()
                  .onError((error, stackTrace) {
                print("$TAG _pauseCamera error $error");
              });
              setState(() {
                isCameraResume = false;
              });
            }
            file = value;
            print("$TAG  stopVideoRecord Success");
            if (file != null) {
              faceValidationNotifier.changeRecordStatus(false);
              faceValidationNotifier.changeCanStartStatus(false);
              await faceValidationCallback(
                  true, file!.path, "", "", _onCallBackResume);
            }
          }).onError((error, stackTrace) {
            faceValidationNotifier.changeRecordStatus(false);
            faceValidationNotifier.changeCanStartStatus(false);
            _resumeCamera();
            print("$TAG  stopVideoRecord Error");
          });
        } on CameraException catch (e) {
          faceValidationNotifier.changeRecordStatus(false);
          faceValidationNotifier.changeCanStartStatus(false);
          print("$TAG  stopVideoRecord Error");
          return null;
        }
      } else {
        stopTime();
        controller.stopVideoRecording(isStopStream: false).then((value) async {
          File videoFile = File(value.path);
          try {
            await videoFile.delete();
          } catch (e) {}
          print("$TAG  stopVideoRecording success not done");
          faceValidationNotifier.changeCanStartStatus(false);
          faceValidationNotifier.changeRecordStatus(false);
        }).catchError((ex) {
          faceValidationNotifier.changeCanStartStatus(false);
          faceValidationNotifier.changeRecordStatus(false);
          print("$TAG stopVideoRecording error");
        });
      }
    }
  }

  getBody() {
    // if (isCameraReady) {
    var scale = 1.0;
    final size = MediaQuery.of(context).size;
    // try {
    //   if (isCameraReady && cameraController != null) {
    //     var camera = cameraController!.value;
    //     if (camera != null && camera.aspectRatio != null) {
    //       scale = size.aspectRatio * camera.aspectRatio;
    //     }
    //     if (scale < 1) scale = 1 / scale;
    //   }
    // } catch (ex) {
    //   print(ex);
    // }
    var heightCard = (size.height -
            (_cardAreaTopR + _cardAreaHeightR + 24 + 15 + 24 + 20 + 16 + 5)) /
        2;
    return SafeArea(
      bottom: false,
      top: false,
      child: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Transform.scale(
              scale: scale,
              child: isCameraReady
                  ? Center(
                      child: CameraPreview(cameraController!),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            StreamBuilder(
                stream: faceValidationNotifier.faceMaskBorderColor.stream,
                builder: (context, snapsot) {
                  Color? color = snapsot.data as Color?;
                  return _getShapeOverlay(true, color);
                }),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 45,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: StreamBuilder(
                          stream:
                              faceValidationNotifier.validationResult.stream,
                          builder: (context, snapsot) {
                            String? validationResult = snapsot.data as String?;
                            return Text(
                              validationResult ?? "",
                              textAlign: TextAlign.center,
                              style: getTextStyleBodyMRegular(
                                  color: kError300Color),
                            );
                          })),
                  const SizedBox(width: 5),
                  StreamBuilder(
                      stream: faceValidationNotifier.volumeStatus.stream,
                      builder: (context, snapsot) {
                        bool? _isMute = snapsot.data as bool?;
                        return SizedBox(
                          width: 20,
                          height: 24,
                          child: _isMute == true
                              ? SvgPicture.asset(
                                  "assets/images/ic_volume_mute.svg",
                                  package: 'uiux_ekyc_flutter_sdk')
                              : SvgPicture.asset("assets/images/ic_volume.svg",
                                  package: 'uiux_ekyc_flutter_sdk'),
                        );
                      })
                ],
              ),
            ),
            Positioned(
              top: _cardAreaTopR + _cardAreaHeightR + 24 + 15,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  StreamBuilder(
                      stream: faceValidationNotifier.stepResult.stream,
                      builder: (context, snapsot) {
                        String? validationResult = snapsot.data as String?;
                        return Text(
                          validationResult ?? "",
                          textAlign: TextAlign.left,
                          style: getTextStyleBodyLSemibold(),
                        );
                      }),
                  const SizedBox(height: 20),
                  _getRow1StepImage(heightCard > 75 ? 75 : heightCard),
                  // const SizedBox(height: 16),
                  // _getRow2StepImage(heightCard > 75 ? 75 : heightCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _getRow1StepImage(double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _buildItemGuide(stepValidation[0].pathDefault,
            faceValidationNotifier.imgStep1.stream, height),
        const SizedBox(width: 16),
        _buildItemGuide(stepValidation[1].pathDefault,
            faceValidationNotifier.imgStep2.stream, height),
        const SizedBox(width: 16),
        _buildItemGuide(stepValidation[2].pathDefault,
            faceValidationNotifier.imgStep3.stream, height),
      ],
    );
  }

  _getRow2StepImage(double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _buildItemGuide(stepValidation[3].pathDefault,
            faceValidationNotifier.imgStep4.stream, height),
        const SizedBox(width: 16),
        _buildItemGuide(stepValidation[4].pathDefault,
            faceValidationNotifier.imgStep5.stream, height),
      ],
    );
  }

  _getShapeOverlay(bool checkStraight, Color? faceMaskBorderColor) {
    return Container(
      decoration: ShapeDecoration(
        shape: FaceScannerOverlayShape(
            offsetYInput: _cardAreaTop,
            overlayColor: Colors.white,
            borderColor: faceMaskBorderColor ?? const Color(0xffa8b1bd),
            borderRadius: 12,
            borderLength: 32,
            borderWidth: 4),
      ),
    );
  }

  Widget _buildItemGuide(String icon, Stream stream, double height) {
    return Container(
        width: height * 101 / 75,
        height: height,
        decoration: BoxDecoration(
            border: Border.all(color: kNeutral200Color),
            borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(10),
        child: Center(
          child: SizedBox(
            child: StreamBuilder(
                stream: stream,
                builder: (context, snapsot) {
                  Uint8List? img = snapsot.data as Uint8List?;
                  return img == null
                      ? Image.asset(
                          icon,
                          package: 'uiux_ekyc_flutter_sdk',
                        )
                      : Image.memory(img);
                }),
            height: 59,
            width: 46,
          ),
        ));
  }

  _logTime(String message) {
    DateTime dateToday = DateTime.now();
    String date = dateToday.toString();
    debugPrint("$message ---->$date");
  }

  bool isPrepareRestart = true;

  void _stopVideoAndResetTime(String code, String mess) {
    isPrepareRestart = false;
    for (var e in stepValidation) {
      e.isValid = false;
    }
    _start = CHECK_STEP_1 + 1;
    _speakByIndex(FaceValidationStatus.WAITING);
    faceValidationNotifier.updateFaceValidateCurrentStatus(
        FaceValidationStatus.WAITING, INVALID_POSITION,
        messageError: "Không nhận diện được khuôn mặt");
    _stopRecordVideo(context, errorCode: code, errMessage: mess);

    if (faceValidationNotifier.isRecording == true) {
      final CameraController? controller = cameraController;

      if (controller == null || !controller.value.isRecordingVideo) {
        return;
      }

      stopTime();
      controller.stopVideoRecording(isStopStream: false).then((value) {
        File videoFile = File(value.path);
        videoFile.delete().then((value) {
          print("$TAG  _stopVideoAndResetTime success");
          faceValidationNotifier.changeCanStartStatus(false);
          faceValidationNotifier.changeRecordStatus(false);
          Future.delayed(const Duration(seconds: 2), () {
            _resetStatus();
            // _startStream();
            isPrepareRestart = true;
          });
        }, onError: (ex) {
          print("$TAG  _stopVideoAndResetTime success ERROR");
          faceValidationNotifier.changeCanStartStatus(false);
          faceValidationNotifier.changeRecordStatus(false);
          Future.delayed(const Duration(seconds: 2), () {
            _resetStatus();
            // _startStream();
            isPrepareRestart = true;
          });
        });
      }, onError: (ex) {
        faceValidationNotifier.changeCanStartStatus(false);
        faceValidationNotifier.changeRecordStatus(false);
        Future.delayed(const Duration(seconds: 2), () {
          _resetStatus();
          // _startStream();
          isPrepareRestart = true;
        });
        print("$TAG stopVideoRecording error");
      });
    }
  }
}

class ObjectImage {
  imglib.Image? image;

  ObjectImage(this.image);
}

class OutputFaceResult {
  bool isRecording = false;
  bool canStart = false;
  String? arrowPath;
  String? iconPath = "assets/images/face_validate_straight_icon.png";
  String step1Path = "assets/images/ic_face_center.png";
  String step2Path = "assets/images/ic_face_left.png";
  String step3Path = "assets/images/ic_face_right.png";
  String step4Path = 'assets/images/ic_face_close_one_eye.png';
  String step5Path = 'assets/images/ic_face_down.png';
  String step6Path = 'assets/images/ic_face_up.png';
  imglib.Image? imgStep1;
  imglib.Image? imgStep2;
  imglib.Image? imgStep3;
  imglib.Image? imgStep4;
  imglib.Image? imgStep5;
  imglib.Image? imgStep6;
  Color faceMaskBorderColor = Colors.green;
  FaceValidationStatus? faceValidateCurrentStatus =
      FaceValidationStatus.WAITING;
}

class AnimatedProgressBar extends AnimatedWidget {
  const AnimatedProgressBar({Key? key, required Animation<double> animation})
      : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return Container(
      height: 6.0,
      width: animation.value,
      decoration: const BoxDecoration(color: Colors.green),
    );
  }
}
