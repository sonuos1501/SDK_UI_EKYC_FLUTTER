import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ekyc_flutter_sdk/ekyc_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as imglib;
import 'package:path_provider/path_provider.dart';
import 'package:uiux_ekyc_flutter_sdk/components/custom_text_style.dart';
import 'package:uiux_ekyc_flutter_sdk/src/callback/card_validation_callback.dart';
import 'package:uiux_ekyc_flutter_sdk/src/helper/uiux_sdk_config.dart';
import 'package:uiux_ekyc_flutter_sdk/src/widgets/cardScanner.dart';

import '../../constants.dart';

class CardValidationView extends StatefulWidget {
  CardValidationStep currentStep;
  CardValidationType cardValidationType;
  UIUXCardValidationCallback callback;
  Function(bool isShowLoading)? loadingCallBack;

  CardValidationView({
    Key? key,
    required this.cardValidationType,
    required this.currentStep,
    required this.callback,
    this.loadingCallBack,
  }) : super(key: key);

  @override
  CardValidationViewState createState() => CardValidationViewState();
}

// enum CardStatus {
//   CARD_IN_VALID(0),
//   CARD_VALID(1),
//   CARD_DETECTING(2),
// }

class CardValidationViewState extends State<CardValidationView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? cameraController;
  bool isCameraReady = false;
  bool isCameraResume = false;
  late CardValidation cardValidation;
  bool isCapture = false;
  bool isUpload = false;
  CameraImage? currentImage;
  CameraImage? imageValid;
  late double screenWidth, screenHeight;
  late double _cardAreaLeft, _cardAreaTop, _cardAreaHeight, _cardAreaWidth;
  imglib.Image? _showImage;
  List<int>? _showBuffer;
  late SdkConfig sdkConfig;
  bool isInit = false;
  CameraDescription? choosenCamera;
  late UIUXCardValidationCallback uiuxCardValidationCallback;
  StreamController<bool> isVisibility = StreamController();
  late Stream<bool> resultVisibility;
  var initFutureCamera;
  int _start = 2;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    uiuxCardValidationCallback = widget.callback;
    resultVisibility = isVisibility.stream.asBroadcastStream();
    _initializeCamera();
  }

  void startTimer() {
    _start = 2;
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        _start--;
        if (_start == 0) {
          isVisibility.add(false);
          _timer?.cancel();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (ModalRoute.of(context)?.isCurrent == true) {
      print("${widget.currentStep} $state ");
      if (state == AppLifecycleState.resumed) {
        if (!isUpload) _resumeCamera();
      } else if (state == AppLifecycleState.inactive) {
        // disposeCamera();
      } else if (state == AppLifecycleState.paused) {
        _pauseCamera();
      } else if (state == AppLifecycleState.detached) {
        disposeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    isCapture = false;
    if (cameraController != null) await cameraController!.dispose();
    final cameras = await availableCameras();
    choosenCamera = cameras[0];
    print(choosenCamera!.sensorOrientation);

    cameraController = CameraController(choosenCamera!, await resolutionPreset,
        imageFormatGroup: ImageFormatGroup.bgra8888, enableAudio: false);

    cameraController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController!.value.hasError) {
      print('Camera Error ${cameraController!.value.errorDescription}');
    }

    try {
      initFutureCamera = await cameraController!.initialize().then((_) => {
            setState(() {
              isCameraReady = true;
              isCameraResume = true;
            })
          });
    } catch (e) {
      print('Camera Error $e');
    }

    if (mounted) {
      setState(() {});
    }
    if (cameraController != null && cameraController!.value.isInitialized) {
      cameraController!.startImageStream((CameraImage image) {
        currentImage = image;
        if (isCameraResume) {
          cardValidation.runDetect(currentImage!);
        }
      });
    }
    isVisibility.add(true);
    startTimer();
    print("LongNV Init camera");
  }

  Future<ResolutionPreset> get resolutionPreset async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      final String deviceModel = iosInfo.utsname.machine ?? '';
      // Các model của iPhone 5 đến iPhone 8 Plus
      if (deviceModel.startsWith('iPhone5') || // iPhone 5, 5C
          deviceModel.startsWith('iPhone6') || // iPhone 5S
          deviceModel.startsWith('iPhone7') || // iPhone 6, 6 Plus
          deviceModel
              .startsWith('iPhone8') || // iPhone 6S, 6S Plus, SE (1st gen)
          deviceModel.startsWith('iPhone9') || // iPhone 7, 7 Plus
          deviceModel.startsWith('iPhone10')) {
        // iPhone 8, 8 Plus, X
        return ResolutionPreset.high;
      } else {
        // deviceModel.startsWith('iPhone11') ||  // iPhone XS, XS Max, XR
        // deviceModel.startsWith('iPhone12') ||  // iPhone 11 series, SE (2nd gen)
        // deviceModel.startsWith('iPhone13') ||  // iPhone 12 series
        // deviceModel.startsWith('iPhone14') ||  // iPhone 13 series, SE (3rd gen), 14 series
        // deviceModel.startsWith('iPhone15'))||  // iPhone 14 Pro series
        return ResolutionPreset.veryHigh;
      }
    } else {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final int processors = Platform.numberOfProcessors;

      // Convert total RAM from bytes to GB
      // Check for low RAM devices, processors and Android version
      if (!androidInfo.systemFeatures.contains('android.hardware.ram.low') && processors > 4 && androidInfo.version.sdkInt >= 24) {
        return ResolutionPreset.veryHigh;
      }

      return ResolutionPreset.high;
    }
  }

  Future<void> disposeCamera() async {
    isCameraResume = false;
    isCameraReady = false;
    if (cameraController != null) {
      print("LongNV _disposeCamera");
      await cameraController?.dispose();
      cameraController = null;
    }
  }

  var isPauseError = false;

  Future<void> _pauseCamera({bool isStopImageStream = true}) async {
    return Future<void>.delayed(Duration.zero, () async {
      isPauseError = false;
      if (cameraController != null) {
        print("LongNV _pauseCamera");
        isCameraResume = false;
        await cameraController!.pausePreview();
        if (isStopImageStream) await cameraController!.stopImageStream();
      }
    }).catchError(() {
      isPauseError = true;
      print("LongNV _pauseCamera Error");
    }).onError((error, stackTrace) {
      isPauseError = true;
      print("----_pauseCamera $error");
    });
  }

  Future<void> _resumeCamera() async {
    Future<void>.delayed(const Duration(milliseconds: 50), () async {
      if (cameraController != null) {
        print("LongNV _resumeCamera");
        isCameraResume = true;
        if (!cameraController!.value.isStreamingImages) {
          await cameraController!.startImageStream((image) {
            currentImage = image;
            if (isCameraResume) cardValidation.runDetect(currentImage!);
          });
        }
        await cameraController!.resumePreview();
      }
    }).onError((error, stackTrace) => print("---- _resumeCamera $error"));
  }

  @override
  void dispose() async {
    disposeCamera();
    cardValidation.streamController?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> onCardValidationCallback(
      imglib.Image? rawCardImage,
      imglib.Image? cardImage,
      CardValidationClass? cardValidationClass,
      bool cardValidationResult,
      String message) async {
    if (rawCardImage == null ||
        cardImage == null ||
        cardValidationClass == null) {
      print("onCardValidationCallback  error: RAW CARD IMAGE NULL");
      uiuxCardValidationCallback(false, '', '',
          "Ảnh bị cắt xén vui lòng chụp lại.", _onCallBackResume);
      return;
    }
    print("LongNV onCardValidationCallback $message");
    List<int> cardImageJpeg = imglib.JpegEncoder().encodeImage(cardImage);
    List<int> rawCardImageJpeg = imglib.JpegEncoder().encodeImage(rawCardImage);
    final appDir = await getTemporaryDirectory();
    final appPath = appDir.path;
    var now = DateTime.now().millisecondsSinceEpoch;

    final fileRawImageOnDevice = File('$appPath/${now}_raw_front.jpg');
    File fileRawImage =
        await fileRawImageOnDevice.writeAsBytes(rawCardImageJpeg, flush: true);

    final fileOnDevice = File('$appPath/${now}_front.jpg');
    File file = await fileOnDevice.writeAsBytes(cardImageJpeg, flush: true);
    uiuxCardValidationCallback(cardValidationResult, fileRawImage.path,
        file.path, message, _onCallBackResume);
  }

  Future<void> _onCallBackResume(dynamic resultBack) {
    isUpload = false;
    if (resultBack == CameraStatus.DISPOSE) {
      return disposeCamera();
    }
    if (resultBack == CameraStatus.PAUSE_PREVIEW) {
      return _pauseCamera();
    }
    if (resultBack == CameraStatus.INIT) {
      cardValidation.resetStatus();
      return _initializeCamera();
    }
    if ((isCameraReady &&
            cameraController != null &&
            !isCameraResume &&
            cameraController?.hasListeners == true) ||
        resultBack == CameraStatus.RESUME_PREVIEW) {
      cardValidation.resetStatus();
      return _resumeCamera();
    } else {
      return Future(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInit && choosenCamera != null) {
      isInit = true;
      screenHeight = MediaQuery.of(context).size.height;
      screenWidth = MediaQuery.of(context).size.width;
      getScannerSize();

      MaskView maskView = MaskView(
          _cardAreaLeft, _cardAreaTop, _cardAreaWidth, _cardAreaHeight);

      ValidationStep cardStep =
          widget.currentStep == CardValidationStep.CARDFRONT
              ? ValidationStep.CARDFRONT
              : ValidationStep.CARDBACK;
      SdkConfig sdkConfig = SdkConfig(
          MediaQuery.of(context).size, maskView, cardStep, choosenCamera!);
      cardValidation = CardValidation(sdkConfig, onCardValidationCallback);
    }
    return getBody();
  }

  double _CARD_ASPECT_RATIO = 1.5;
  double _OFFSET_X_FACTOR = 0.05;

  void getScannerSize() {
    _CARD_ASPECT_RATIO =
        (widget.cardValidationType == CardValidationType.PASSPORT)
            ? 1 / 1.2
            : 1 / 1.5;
    _OFFSET_X_FACTOR = 0.05;
    final screenRatio = screenWidth / screenHeight;

    _cardAreaLeft = _OFFSET_X_FACTOR * screenWidth.round();
    _cardAreaWidth = screenWidth.round() - _cardAreaLeft * 2;
    _cardAreaHeight = _cardAreaWidth * _CARD_ASPECT_RATIO;
    _cardAreaTop = (screenHeight.round() - _cardAreaHeight) / 2;
  }

  DeviceOrientation _getApplicableOrientation() {
    return cameraController!.value.isRecordingVideo
        ? cameraController!.value.recordingOrientation!
        : (cameraController!.value.previewPauseOrientation ??
            cameraController!.value.lockedCaptureOrientation ??
            cameraController!.value.deviceOrientation);
  }

  getBody() {
    if (isCameraReady && cameraController != null) {
      var camera = cameraController!.value;
      var scale = 1.0;
      final size = MediaQuery.of(context).size;
      // try {
      //   scale = size.aspectRatio * camera.aspectRatio;
      //   if (scale < 1) scale = 1 / scale;
      // } catch (ex) {
      //   print(ex);
      // }
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(cameraController!),
            ),
          ),
          StreamBuilder<OutputResult>(
            stream: cardValidation.resultStream,
            builder: (context, snapshot) {
              CardStatus cardStatusResult = getCardStatus(snapshot.data);
              if (snapshot.data?.cardValidationResult == true) {
                imageValid = currentImage;
              }
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Container(
                    decoration: ShapeDecoration(
                      shape: CardScannerOverlayShape(
                        CARD_ASPECT_RATIO: _CARD_ASPECT_RATIO,
                        OFFSET_X_FACTOR: _OFFSET_X_FACTOR,
                        borderColor: Colors.white,
                        validColor: cardStatusResult.borderColor,
                        borderRadius: 14,
                        borderLength: 32,
                        borderWidth: 4,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    right: 30,
                    bottom: _cardAreaTop + _cardAreaHeight + 24,
                    child: Text(
                      cardStatusResult.message,
                      textAlign: TextAlign.center,
                      style: getTextStyleBodyMRegular(
                          color: cardStatusResult.messageColor),
                    ),
                  ),
                  Positioned(
                      left: _cardAreaLeft,
                      top: _cardAreaTop,
                      bottom: _cardAreaTop,
                      right: _cardAreaLeft,
                      child: StreamBuilder(
                          stream: resultVisibility,
                          builder: (context, snapshot) {
                            bool? isv = snapshot.data as bool?;
                            return Visibility(
                                visible: (isv ?? false),
                                child: Container(
                                    padding: const EdgeInsets.only(
                                        top: 18,
                                        bottom: 18,
                                        right: 28,
                                        left: 28),
                                    child: (widget.cardValidationType ==
                                            CardValidationType.CCCD)
                                        ? Image(
                                            image: AssetImage(
                                              widget.currentStep ==
                                                      CardValidationStep
                                                          .CARDFRONT
                                                  ? "assets/images/ic_card_front_overlay.png"
                                                  : "assets/images/ic_card_back_overlay.png",
                                              package: 'ekyc_sdk_plugin',
                                            ),
                                            width: 268,
                                            height: 169,
                                            alignment: Alignment.center,
                                          )
                                        : const Image(
                                            image: AssetImage(
                                              "assets/images/ic_passpost_overlay.png",
                                              package: 'ekyc_sdk_plugin',
                                            ),
                                            width: 268,
                                            height: 188.86,
                                            alignment: Alignment.center,
                                          )));
                          })),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _cardAreaTop - 70,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            child: SvgPicture.asset(
                              widget.currentStep == CardValidationStep.CARDFRONT
                                  ? "assets/images/ic_card_front.svg"
                                  : "assets/images/ic_card_back.svg",
                              package: 'ekyc_sdk_plugin',
                            ),
                            width: 30,
                            height: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.cardValidationType ==
                                    CardValidationType.PASSPORT
                                ? 'Chụp trang có ảnh chân dung'
                                : (widget.currentStep ==
                                        CardValidationStep.CARDFRONT
                                    ? "Chụp mặt trước"
                                    : "Chụp mặt sau"),
                            textAlign: TextAlign.center,
                            style: getTextStyleBodyMSemibold(),
                          )
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 50),
                      child: IconButton(
                        icon: SvgPicture.asset(cardStatusResult.icTakePath,
                            package: 'ekyc_sdk_plugin', width: 72),
                        iconSize: 72,
                        tooltip: 'Nhấn để chụp',
                        onPressed: (cardStatusResult.status ==
                                CardValidationStatus.VALID)
                            ? () async {
                                CameraImage? currentImg;
                                if (Platform.isAndroid) {
                                  if (imageValid != null) {
                                    try {
                                      currentImg = imageValid;
                                      if (widget.loadingCallBack != null) {
                                        isUpload = true;
                                        widget.loadingCallBack!(true);
                                      }
                                      print("takePicture start");
                                      await _pauseCamera();
                                      cardValidation
                                          .detectByImageAndroid(currentImg!);
                                      currentImg = null;
                                      imageValid = null;
                                      currentImage = null;
                                    } catch (ex) {
                                      print(
                                          "takePicture error" + ex.toString());
                                    }
                                  }
                                } else {
                                  if (imageValid != null) {
                                    try {
                                      currentImg = imageValid;
                                      if (widget.loadingCallBack != null) {
                                        isUpload = true;
                                        widget.loadingCallBack!(true);
                                      }
                                      print("takePicture start");
                                      await _pauseCamera();
                                      cardValidation
                                          .detectByImageIos(currentImg!);
                                      currentImg = null;
                                      imageValid = null;
                                      currentImage = null;
                                    } catch (ex) {
                                      print(
                                          "takePicture error" + ex.toString());
                                    }
                                  }
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        ],
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  CardStatus getCardStatus(OutputResult? ouputR) {
    CardValidationStatus status;
    String message;
    bool isShowCardOverlay = false;
    if (widget.cardValidationType == CardValidationType.CCCD) {
      switch (ouputR?.cardValidationClass) {
        case CardValidationClass.invalid_background:
          message = "Vui lòng đặt CCCD nằm trong khung hình";
          isShowCardOverlay = true;
          break;
        case CardValidationClass.valid_front_CCCD:
        case CardValidationClass.valid_front_chip:
        case CardValidationClass.valid_back_CCCD:
        case CardValidationClass.valid_back_chip:
          message = "Sẵn sàng chụp";
          break;
        case CardValidationClass.invalid_hand_cover_CCCD_front:
        case CardValidationClass.invalid_hand_cover_CCCD_back:
        // case CardValidationClass.invalid_insert_text_paper_CCCD_front:
        // case CardValidationClass.invalid_insert_text_paper_CCCD_back:
        // case CardValidationClass.invalid_icon_CCCD_back:
        case CardValidationClass.invalid_spotlight_CCCD_front:
        case CardValidationClass.invalid_spotlight_CCCD_back:
        case CardValidationClass.invalid_spotlight_CMND_front:
        case CardValidationClass.invalid_spotlight_CMND_back:
        case CardValidationClass.invalid_hand_cover_CMND_front:
        case CardValidationClass.invalid_hand_cover_CMND_back:
        // case CardValidationClass.invalid_insert_text_paper_CMND_front:
        // case CardValidationClass.invalid_insert_text_paper_CMND_back:
        // case CardValidationClass.invalid_icon_CMND_front:
        // case CardValidationClass.invalid_icon_CMND_back:
        case CardValidationClass.invalid_spotlight_CHIP_front:
        case CardValidationClass.invalid_spotlight_CHIP_back:
        // case CardValidationClass.invalid_insert_text_paper_CHIP_front:
        // case CardValidationClass.invalid_insert_text_paper_CHIP_back:
        // case CardValidationClass.invalid_icon_CHIP_front:
        // case CardValidationClass.invalid_icon_CHIP_back:
        case CardValidationClass.invalid_hand_cover_CHIP_front:
        case CardValidationClass.invalid_hand_cover_CHIP_back:
          message = "Ảnh bị loá";
          break;
        // case CardValidationClass.invalid_device_CCCD:
        // case CardValidationClass.invalid_device_CMND:
        // case CardValidationClass.invalid_device_CHIP:
        // message= "Không sử dụng thẻ photo hoặc bị hư hại";
        // break;
        case CardValidationClass.invalid_cut_edge_CMND_front:
        case CardValidationClass.invalid_cut_edge_CMND_back:
        case CardValidationClass.invalid_cut_edge_CCCD_front:
        case CardValidationClass.invalid_cut_edge_CCCD_back:
        case CardValidationClass.invalid_cut_edge_CHIP_front:
        case CardValidationClass.invalid_cut_edge_CHIP_back:
          message = "Vui lòng đặt CCCD nằm trong khung hình";
          break;
        case CardValidationClass.invalid_SIDE:
          message = "Vui lòng sử dụng đúng mặt CCCD";
          break;
        case CardValidationClass.valid_PASSPORT:
        case CardValidationClass.valid_front_CMND:
        case CardValidationClass.valid_back_CMND:
          message = "Vui lòng sử dụng đúng loại giấy tờ";
          break;
        default:
          isShowCardOverlay = true;
          message = "Vui lòng đặt CCCD nằm trong khung hình";
          break;
      }
    } else {
      switch (ouputR?.cardValidationClass) {
        case CardValidationClass.invalid_background:
          message = "Vui lòng đặt trang 2 Hộ chiếu\n nằm trong khung hình";
          isShowCardOverlay = true;
          break;
        case CardValidationClass.valid_front_CCCD:
        case CardValidationClass.valid_front_CMND:
        case CardValidationClass.valid_front_chip:
        case CardValidationClass.valid_back_CCCD:
        case CardValidationClass.valid_back_chip:
        case CardValidationClass.valid_back_CMND:
          message = "Vui lòng sử dụng đúng loại giấy tờ";
          break;
        case CardValidationClass.invalid_hand_cover_CCCD_front:
        case CardValidationClass.invalid_hand_cover_CCCD_back:
        // case CardValidationClass.invalid_insert_text_paper_CCCD_front:
        // case CardValidationClass.invalid_insert_text_paper_CCCD_back:
        // case CardValidationClass.invalid_icon_CCCD_back:
        case CardValidationClass.invalid_spotlight_CCCD_front:
        case CardValidationClass.invalid_spotlight_CCCD_back:
        case CardValidationClass.invalid_spotlight_CMND_front:
        case CardValidationClass.invalid_spotlight_CMND_back:
        case CardValidationClass.invalid_hand_cover_CMND_front:
        case CardValidationClass.invalid_hand_cover_CMND_back:
        // case CardValidationClass.invalid_insert_text_paper_CMND_front:
        // case CardValidationClass.invalid_insert_text_paper_CMND_back:
        // case CardValidationClass.invalid_icon_CMND_front:
        // case CardValidationClass.invalid_icon_CMND_back:
        case CardValidationClass.invalid_spotlight_CHIP_front:
        case CardValidationClass.invalid_spotlight_CHIP_back:
        // case CardValidationClass.invalid_insert_text_paper_CHIP_front:
        // case CardValidationClass.invalid_insert_text_paper_CHIP_back:
        // case CardValidationClass.invalid_icon_CHIP_front:
        // case CardValidationClass.invalid_icon_CHIP_back:
        case CardValidationClass.invalid_hand_cover_CHIP_front:
        case CardValidationClass.invalid_hand_cover_CHIP_back:
          message = "Ảnh bị loá";
          break;
          // case CardValidationClass.invalid_device_CCCD:
          // case CardValidationClass.invalid_device_CMND:
          // case CardValidationClass.invalid_device_CHIP:
          // message= "Không sử dụng thẻ photo hoặc bị hư hại";
          // break;
          break;
        case CardValidationClass.valid_PASSPORT:
          message = "Sẵn sàng chụp";
          break;
        default:
          isShowCardOverlay = true;
          message = "Vui lòng đặt trang 2 Hộ chiếu\n nằm trong khung hình";
          break;
      }
    }
    if ((ouputR?.cardValidationClass == null ||
        ouputR?.cardValidationClass ==
            CardValidationClass.invalid_background)) {
      status = CardValidationStatus.DEFAULT;
    } else if (ouputR?.cardValidationResult == true &&
        ((ouputR?.cardValidationClass == CardValidationClass.valid_PASSPORT &&
                widget.cardValidationType == CardValidationType.PASSPORT) ||
            ((ouputR?.cardValidationClass ==
                        CardValidationClass.valid_front_CMND ||
                    ouputR?.cardValidationClass ==
                        CardValidationClass.valid_front_CCCD ||
                    ouputR?.cardValidationClass ==
                        CardValidationClass.valid_front_chip ||
                    ouputR?.cardValidationClass ==
                        CardValidationClass.valid_back_CMND ||
                    ouputR?.cardValidationClass ==
                        CardValidationClass.valid_back_CCCD ||
                    ouputR?.cardValidationClass ==
                        CardValidationClass.valid_back_chip) &&
                widget.cardValidationType == CardValidationType.CCCD))) {
      status = CardValidationStatus.VALID;
    } else {
      status = CardValidationStatus.INVALID;
    }
    switch (status) {
      case CardValidationStatus.DEFAULT:
        return CardStatus(
            messageColor: kNeutral800Color,
            icTakePath: "assets/images/ic_take_picture_disable.svg",
            borderColor: kNeutral500Color,
            message: message,
            status: status,
            isShowCardOverlay: isShowCardOverlay);
      case CardValidationStatus.INVALID:
        return CardStatus(
            messageColor: kError300Color,
            icTakePath: "assets/images/ic_take_picture_disable.svg",
            borderColor: kError300Color,
            message: message,
            status: status,
            isShowCardOverlay: isShowCardOverlay);
      case CardValidationStatus.VALID:
        return CardStatus(
            messageColor: kSuccess400Color,
            icTakePath: "assets/images/ic_take_picture_enable.svg",
            borderColor: kSuccess400Color,
            message: message,
            status: status,
            isShowCardOverlay: isShowCardOverlay);
      default:
        return CardStatus(
            messageColor: kNeutral800Color,
            icTakePath: "assets/images/ic_take_picture_enable.svg",
            borderColor: kNeutral500Color,
            message: widget.cardValidationType == CardValidationType.PASSPORT
                ? "Vui lòng đặt trang 2 Hộ chiếu \n nằm trong khung hình"
                : "Vui lòng đặt CCCD nằm trong khung hình",
            status: status,
            isShowCardOverlay: isShowCardOverlay);
    }
  }
}

class CardStatus {
  Color messageColor;
  Color borderColor;
  String icTakePath;
  String message;
  bool isShowCardOverlay;
  CardValidationStatus status;

  CardStatus(
      {required this.messageColor,
      required this.borderColor,
      required this.icTakePath,
      required this.message,
      required this.status,
      required this.isShowCardOverlay});
}
