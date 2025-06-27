typedef FaceValidationCallback = Future<void> Function(
    bool faceValidationResult,
    String videoPath,
    String errorCode,
    String message,
    Future<void> Function(dynamic result));
