/**
 * Camera Roll PhoneGap Plugin.
 *
 * Reads photos from the iOS Camera Roll.
 *
 * Copyright 2013 Drifty Co.
 * http://drifty.com/
 *
 * See LICENSE in this project for licensing info.
 */

#import "IonicCameraRoll.h"
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <CoreLocation/CoreLocation.h>

@implementation IonicCameraRoll

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });

    // TODO: Dealloc this later?
    return library;
}

- (void)saveToCameraRoll:(CDVInvokedUrlCommand*)command
{
    NSString *base64String = [command argumentAtIndex:0];
    NSURL *url = [NSURL URLWithString:base64String];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:imageData];

    // save the image to photo album
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"saved"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
/**
 * Get all the photos in the library.
 *
 * TODO: This should support block-type reading with a set of images
 */
- (void)getPhotos:(CDVInvokedUrlCommand*)command
{
    NSUInteger limit = 0;
    if ([command.arguments count] > 0) {
        NSString* limitStr = [command.arguments objectAtIndex:0];
        limit = [limitStr integerValue];
    }
    bool hasLimit = limit > 0;

    NSLog(@"getPhotos called with limit: %tu", limit);

    // Grab the asset library
    __block NSUInteger count = 0;
    ALAssetsLibrary *library = [IonicCameraRoll defaultAssetsLibrary];

    // Block called at the end of the photostreaming
    __block bool enumerationEnded = false;
    void (^signalEnumerationEnd)() = ^void() {
        if (enumerationEnded) return;
        enumerationEnded = true;

        // Send empty JSON to indicate the end of photostreaming
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{}];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };

    // Run a background job
    [self.commandDelegate runInBackground:^{

        // Enumerate all of the group saved photos, which is our Camera Roll on iOS
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

            // When there are no more images, the group will be nil
            if(group == nil || (hasLimit && count >= limit)) {
                signalEnumerationEnd();
                return;
            }

            // Enumarate this group of images
            [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

            // When there are no more images, the group will be nil
            if(group == nil || (hasLimit && count >= limit)) {
                signalEnumerationEnd();
                return;
            }
            
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
            if (result)
            {
                 if(hasLimit && count >= limit) {
                    signalEnumerationEnd();
                    return;
                }

                NSDictionary *urls = [result valueForProperty:ALAssetPropertyURLs];
                NSDate* date = [result valueForProperty:ALAssetPropertyDate];

                [urls enumerateKeysAndObjectsUsingBlock:^(id key, NSURL *obj, BOOL *stop) {

                    if(hasLimit && count >= limit) {
                        signalEnumerationEnd();
                        return;
                    }

                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"path": obj.absoluteString, @"date": [NSNumber numberWithLongLong:date.timeIntervalSince1970*1000]}];
                    [pluginResult setKeepCallbackAsBool:YES];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    count++;
                }];                
             }
                
            }];
        } failureBlock:^(NSError *error) {
            // Ruh-roh, something bad happened.
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];

}

- (void)getVideos:(CDVInvokedUrlCommand*)command
{
    NSUInteger limit = 0;
    if ([command.arguments count] > 0) {
        NSString* limitStr = [command.arguments objectAtIndex:0];
        limit = [limitStr integerValue];
    }
    bool hasLimit = limit > 0;

    NSLog(@"getPhotos called with limit: %tu", limit);

    // Grab the asset library
    __block NSUInteger count = 0;
    ALAssetsLibrary *library = [IonicCameraRoll defaultAssetsLibrary];

    // Block called at the end of the photostreaming
    __block bool enumerationEnded = false;
    void (^signalEnumerationEnd)() = ^void() {
        if (enumerationEnded) return;
        enumerationEnded = true;

        // Send empty JSON to indicate the end of photostreaming
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{}];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };

    // Run a background job
    [self.commandDelegate runInBackground:^{

        // Enumerate all of the group saved photos, which is our Camera Roll on iOS
        [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

            // When there are no more images, the group will be nil
            if(group == nil || (hasLimit && count >= limit)) {
                signalEnumerationEnd();
                return;
            }
            
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
            if (result)
            {
                 if(hasLimit && count >= limit) {
                    signalEnumerationEnd();
                    return;
                }

                NSDictionary *urls = [result valueForProperty:ALAssetPropertyURLs];
                NSDate* date = [result valueForProperty:ALAssetPropertyDate];

                [urls enumerateKeysAndObjectsUsingBlock:^(id key, NSURL *obj, BOOL *stop) {

                    if(hasLimit && count >= limit) {
                        signalEnumerationEnd();
                        return;
                    }

                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"path": obj.absoluteString, @"thum":[generateThumbImage(obj.absoluteString)], @"date": [NSNumber numberWithLongLong:date.timeIntervalSince1970*1000]}];
                    [pluginResult setKeepCallbackAsBool:YES];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    count++;
                }];                
             }
                
            }];

        } failureBlock:^(NSError *error) {
            // Ruh-roh, something bad happened.
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];

}

-(UIImage *)generateThumbImage : (NSString *)filepath
{
    NSURL *url = [NSURL fileURLWithPath:filepath];

    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
self.imageGenerator.appliesPreferredTrackTransform = YES; 
        CMTime time = [asset duration];
        time.value = 0;
        Float duration = CMTimeGetSeconds([myAsset duration]);
   for(Float i = 0.0; i<duration; i=i+0.1)
    {
     CGImageRef imgRef = [self.imageGenerator copyCGImageAtTime:CMTimeMake(i, duration) actualTime:NULL error:nil];
     UIImage* thumbnail = [[UIImage alloc] initWithCGImage:imgRef scale:UIViewContentModeScaleAspectFit orientation:UIImageOrientationUp];
    [thumbnailImages addObject:thumbnail];
    }
}

@end
