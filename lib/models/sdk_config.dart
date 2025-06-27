class SdkConfig {
  late String? apiUrl;
  late String source;
  late String env;
  late String token;
  late int timeOut;
  late String email;
  late String phone;
  SdkCallback? sdkCallback;
  late String backRoute;
  late String urlVideoDetectFaceGuide;
  late String urlVideoAuthenGuide;

  SdkConfig({
    required this.apiUrl,
    required this.source,
    required this.env,
    required this.token,
    required this.timeOut,
    required this.email,
    required this.phone,
    required this.backRoute,
    this.sdkCallback,
    required this.urlVideoDetectFaceGuide,
    required this.urlVideoAuthenGuide,
  });
}

class ResponseFromServer<R> {
  late ResponseCode code;
  late String? message;
  late R? data;

  ResponseFromServer({required this.code, this.message, this.data});
}

class ResponseEformCreate {
  String pathFilePdf;
  String traceId;
  String documentCode;

  ResponseEformCreate(
      {required this.pathFilePdf,
      required this.documentCode,
      required this.traceId});
}

class RequestEformConfirm {
  String documentCode;
  String traceId;
  String fullName;
  String idNumber;
  String province;
  String nation;
  String expireHour;

  RequestEformConfirm(
      {required this.traceId,
      required this.documentCode,
      required this.fullName,
      required this.idNumber,
      required this.province,
      required this.nation,
      required this.expireHour});
}

class ResponseDetailCertificate {
  String traceId;
  String fullName;
  String idNumber;
  String province;
  String nation;
  String serialCertificate;
  String company;
  String effectDate;
  String expireDate;

  ResponseDetailCertificate(
      {required this.traceId,
      required this.fullName,
      required this.idNumber,
      required this.province,
      required this.nation,
      required this.serialCertificate,
      required this.company,
      required this.effectDate,
      required this.expireDate});
}

enum ResponseCode { SUCCESS, ERROR, TIMEOUT, ERROR_NOT_RETRY }

abstract class SdkCallback {
  Future<void> initSDKSucceed(bool isSucceed);

  Future<void> generateSessionID(
      bool isSucceed, String errorCode, String errorMessage, String sessionID);

  Future<void> frontCardDeviceCheck(bool isSucceed, String errorCode,
      String errorMessage, String frontCardImagePath);

  Future<void> frontCardCloudCheck(
      bool isSucceed, String errorCode, String errorMessage);

  Future<void> backCardDeviceCheck(bool isSucceed, String errorCode,
      String errorMessage, String backCardImagePath);

  Future<void> backCardCloudCheck(
      bool isSucceed, String errorCode, String errorMessage);

  Future<void> faceDeviceCheck(bool isSucceed, String errorCode,
      String errorMessage, String faceVideoPath);

  Future<void> faceCloudCheck(
      bool isSucceed, String errorCode, String errorMessage);

  Future<void> recordAuthenVideoDeviceCheck(String faceVideoPath);

  Future<void> ekycResult(
      bool isCompleted,
      bool isSucceed,
      String errorCode,
      String errorMessage,
      double similarity,
      String name,
      String dateOfBirth,
      String id,
      String placeOfOrigin,
      String placeOfResidence,
      String dateOfExpiry,
      String dateOfIssue,
      String sex,
      String ethnicity,
      String personalIdentification,
      String nationality);

  Future<void> destroy(bool isCompleted);
}
