import 'package:uiux_ekyc_flutter_sdk/models/sdk_config.dart';

class AppConfig {
  AppConfig._();
  static bool isInit = false;
  static final AppConfig _instance = AppConfig._();
  factory AppConfig() => _instance;
  String apiUrl = "https://ekyc-prod-local.tunnel.techainer.com/api/v1/ekyc";
  String apiUrlPdf = "https://ekyc-prod-local.tunnel.techainer.com/api/v1/ekyc";
  String apiUrlAuthenVideo =
      "https://ekyc-prod-local.tunnel.techainer.com/api/v1/ekyc";
  String source = "VDT";
  String env = "dev";
  String token = "4780bba4704800149fca952cb20fb276d8245c11";
  int timeOut = 10;
  String email = "";
  String phone = "";
  late String backRoute = "/";
  SdkCallback? sdkCallback;
}
