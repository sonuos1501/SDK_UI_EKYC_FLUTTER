import 'package:ekyc_flutter_sdk/src/ai_service/models/detection.dart';
import 'package:image/image.dart' as imglib;

typedef Future<void> FaceValidationCallback(
    bool faceValidationResult,
    String videoPath,
    String errorCode,
    String message,
    Future<void> Function(dynamic result));
