typedef Future<void> UIUXCardValidationCallback(
    bool cardValidationResult,
    String rawCardImagePath,
    String cardImagePath,
    String message,
    Future<void> Function(var backResult));
