#import "SnowmScannerPlugin.h"
#if __has_include(<snowm_scanner/snowm_scanner-Swift.h>)
#import <snowm_scanner/snowm_scanner-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "snowm_scanner-Swift.h"
#endif

@implementation SnowmScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSnowmScannerPlugin registerWithRegistrar:registrar];
}
@end
