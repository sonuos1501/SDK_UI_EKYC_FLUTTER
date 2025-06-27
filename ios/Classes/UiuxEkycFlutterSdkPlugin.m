#import "UiuxEkycFlutterSdkPlugin.h"
#if __has_include(<uiux_ekyc_flutter_sdk/uiux_ekyc_flutter_sdk-Swift.h>)
#import <uiux_ekyc_flutter_sdk/uiux_ekyc_flutter_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "uiux_ekyc_flutter_sdk-Swift.h"
#endif

@implementation UiuxEkycFlutterSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftUiuxEkycFlutterSdkPlugin registerWithRegistrar:registrar];
}
@end
