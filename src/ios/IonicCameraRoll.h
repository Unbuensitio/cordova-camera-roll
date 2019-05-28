#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManager.h>
#import <Cordova/CDVPlugin.h>

@interface IonicCameraRoll : CDVPlugin
{}

- (void)getPhotos:(CDVInvokedUrlCommand*)command;
- (void)getVideos:(CDVInvokedUrlCommand*)command;
- (void)saveToCameraRoll:(CDVInvokedUrlCommand*)command;

@end
