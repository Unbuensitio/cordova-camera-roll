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
#import <MediaPlayer/MediaPlayer.h>
#import "CDVFile.h"
#import <Photos/Photos.h>

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

- (void)obtenerLivePhotos:(CDVInvokedUrlCommand*)command
{
    NSUInteger limit = 0;
    if ([command.arguments count] > 0) {
        NSString* limitStr = [command.arguments objectAtIndex:0];
        limit = [limitStr integerValue];
    }
    bool hasLimit = limit > 0;
    __block NSUInteger count = 0;
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    //options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    //options.predicate = [NSPredicate predicateWithFormat:@"mediaSubtype == %d", PHAssetMediaSubtypePhotoLive];
    
    NSPredicate *imagesPredicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    //NSPredicate *liveImagesPredicate = [NSPredicate predicateWithFormat:@"mediaSubtype == %d", PHAssetMediaSubtypePhotoLive];
    //options.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[imagesPredicate, liveImagesPredicate]];
    options.fetchLimit = 9;
    //options.fetchOffset = 12;
    options.includeAllBurstAssets = NO;
    PHFetchResult *allLivePhotos = [PHAsset fetchAssetsWithOptions:options];
    //NSMutableArray *arrAllLiveImagesGroups = [NSMutableArray array];

    //for (int i = 12; i < 24; i++)
    //{
        //PHAsset *asset = [allLivePhotos objectAtIndex:i];
    for (PHAsset *asset in allLivePhotos) {
                                [asset requestContentEditingInputWithOptions:nil
                                   completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                       if(asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive)
                                       {
                                               PHLivePhotoEditingContext *context = [[PHLivePhotoEditingContext alloc] initWithLivePhotoEditingInput:contentEditingInput];
                                               CIImage *ciImage =  context.fullSizeImage;
                                               CIContext *ciContext = [CIContext contextWithOptions:nil];
                                               CGImageRef imgRef = [ciContext createCGImage:ciImage fromRect:[ciImage extent]];
                                               UIImage* thumbnail = [[UIImage alloc] initWithCGImage:imgRef];
                                               NSString *rutaImagen;
                                               NSData *imageData = UIImageJPEGRepresentation(thumbnail, 100);
                                               if(imageData)
                                               {
                                                    NSString *inicio = @"data:image/jpeg;base64,";
                                                    NSString *final = [imageData base64EncodedStringWithOptions:0];
                                                    rutaImagen = [inicio stringByAppendingString:final];
                                               }
                                               else
                                               {
                                                    rutaImagen = @"ok";
                                               }
                                               /*UIImage* thumbnail = [UIImage imageWithCIImage:ciImage];
                                               NSURL *urlMov = [contentEditingInput.livePhoto valueForKey:@"videoURL"];
                                               NSString *myString = urlMov.absoluteString;
                                               UIImage *thumbnail;
                                               AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:urlMov options:nil];
                                               AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                                               generate.appliesPreferredTrackTransform = YES;
                                               NSError *err = NULL;
                                               Float64 quality = 100;
                                               Float64 position = 0;
                                               CMTime time = CMTimeMakeWithSeconds(position, 1000);
                                               CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
                                               thumbnail = [[UIImage alloc] initWithCGImage:imgRef];
                                               CGImageRelease(imgRef);
                                               NSData *imageData = UIImageJPEGRepresentation(thumbnail, 100);
                                               NSString *inicio = @"data:image/jpeg;base64,";
                                               NSString *final = [imageData base64EncodedStringWithOptions:0];
                                               NSString* rutaImagen = [inicio stringByAppendingString:final];*/
                                               CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"imagen":rutaImagen}];
                                               [pluginResult setKeepCallbackAsBool:YES];
                                               [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                               count++;
                                       }
                                       else
                                       {
                                                CIImage *ciImage = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
                                                CIContext *ciContext = [CIContext contextWithOptions:nil];
                                                CGImageRef imgRef = [ciContext createCGImage:ciImage fromRect:[ciImage extent]];
                                                UIImage* thumbnail = [[UIImage alloc] initWithCGImage:imgRef];
                                           
                                                NSString *rutaImagen;
                                                NSData *imageData = UIImageJPEGRepresentation(thumbnail, 100);
                                                if(imageData)
                                                {
                                                    NSString *inicio = @"data:image/jpeg;base64,";
                                                    NSString *final = [imageData base64EncodedStringWithOptions:0];
                                                    rutaImagen = [inicio stringByAppendingString:final];
                                                }
                                                else
                                                {
                                                    rutaImagen = @"ok";
                                                }
                                           
                                                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"imagen":rutaImagen}];
                                                [pluginResult setKeepCallbackAsBool:YES];
                                                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                                count++;
                                       }
                                   }];
    }
}

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
    //ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

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
            
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
           // [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
            if (group.numberOfAssets > 0) 
            {
                    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
                            if (result)
                            {
                                 if(hasLimit && count >= limit) {
                                    //signalEnumerationEnd();
                                    return;
                                }

                                NSDictionary *urls = [result valueForProperty:ALAssetPropertyURLs];
                                NSDate* date = [result valueForProperty:ALAssetPropertyDate];

                                [urls enumerateKeysAndObjectsUsingBlock:^(id key, NSURL *obj, BOOL *stop) {

                                    if(hasLimit && count >= limit) {
                                        signalEnumerationEnd();
                                        return;
                                    }
                                   
                                    NSString* rutaImagen = obj.absoluteString;
                                    
                                    if ([rutaImagen rangeOfString:@"asset/asset.(null)"].location == NSNotFound) {
                                        /*NSURL *url = [NSURL URLWithString:ruta];
                                        NSData *data = [NSData dataWithContentsOfURL:url];
                                        UIImage *image = [UIImage imageWithData:data];
                                        
                                        NSURL *filePath = [self obtainURLForPath:ruta];
                                        NSData *imagenData = [NSData dataWithContentsOfURL:filePath];
                                        UIImage *img = [UIImage imageWithData:imagenData];
                                        NSData *imageData = UIImageJPEGRepresentation(image, 1);
                                        NSString *inicio = @"data:image/jpeg;base64,";
                                        NSString *final = [imageData base64EncodedStringWithOptions:0];
                                        NSString* rutaImagen = [inicio stringByAppendingString:final];*/
                                        
                                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"path": rutaImagen, @"date": [NSNumber numberWithLongLong:date.timeIntervalSince1970*1000]}];
                                        [pluginResult setKeepCallbackAsBool:YES];
                                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                        count++;
                                        
                                    } else {
                                      NSLog(@"string contains bla!");
                                    }
                                   
                                }];                
                             }
                     }];
               }                                                        

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
                    NSString* ruta = obj.absoluteString;
                    
                    
                    UIImage *thumbnail;
                    NSURL *url = [self obtainURLForPath:ruta];
                    
                    AVAsset *asset = [AVAsset assetWithURL:url];
                    AVAssetImageGenerator *generate = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                    generate.appliesPreferredTrackTransform = YES;

                    NSError *err = NULL;
                    Float64 quality = 100;
                    Float64 position = 0;
                    CMTime time = CMTimeMakeWithSeconds(position, 1000);
                    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
                    thumbnail = [[UIImage alloc] initWithCGImage:imgRef];
                    CGImageRelease(imgRef);
                    NSData *imageData = UIImageJPEGRepresentation(thumbnail, quality);
                    
                    NSString *inicio = @"data:image/jpeg;base64,";
                    NSString *final = [imageData base64EncodedStringWithOptions:0];
                    NSString* rutaImagen = [inicio stringByAppendingString:final];
                    //UIImage* thumb = [self VideoThumbNail:videoURL];
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"path": obj.absoluteString, @"imagen": rutaImagen, @"date": [NSNumber numberWithLongLong:date.timeIntervalSince1970*1000]}];
                    //CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"path": obj.absoluteString, @"date": [NSNumber numberWithLongLong:date.timeIntervalSince1970*1000]}];
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

- (NSURL *) obtainURLForPath:(NSString *)path {
    if ([path hasPrefix:@"cdvfile://"]) {
        // use the File API to get the appropriate URL, given the path
        // based on media plugin's code for obtaining file paths
        CDVFile *filePlugin = [self.commandDelegate getCommandInstance:@"File"];
        CDVFilesystemURL *fsURL = [CDVFilesystemURL fileSystemURLWithString:path];
        NSString *filePath = [filePlugin filesystemPathForURL:fsURL];
        if (filePath) {
            return [NSURL URLWithString:[[@"file://" stringByAppendingString:filePath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        } else {
            return [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
    } else {
        if ([path rangeOfString:@"://"].location == NSNotFound) {
            NSString *pathForResource = [self.commandDelegate pathForResource:path];
            if (pathForResource) {
                return [NSURL URLWithString:[[@"file://" stringByAppendingString:pathForResource] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            } else {
                return NULL;
            }
        }
        else {
            return [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
    }
}

/*-(UIImage *)loadThumbNail:(NSURL *)urlVideo {
     
     AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:urlVideo options:nil];
    
     AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
     generate.appliesPreferredTrackTransform=TRUE;
     
     NSError *err = NULL;
     CMTime time = CMTimeMake(1, 60);
     CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
   
     NSLog(@"err==%@, imageRef==%@", err, imgRef);
     return [[UIImage alloc] initWithCGImage:imgRef];
}

- (UIImage *)VideoThumbNail:(NSURL *)videoURL
{
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
    UIImage *thumbnail = [player thumbnailImageAtTime:52.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
    [player stop];
    return thumbnail;
}*/

@end
