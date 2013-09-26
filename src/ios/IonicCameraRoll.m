/**
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
    return library;
  }
  
/**
 * Get all the photos in the library.
 *
 * TODO: This should support block-type reading with a set of images
 */
- (void)getPhotos:(CDVInvokedUrlCommand*)command
{
  NSString *targetWidth = [command argumentAtIndex:0];
  NSString *targetHeight = [command argumentAtIndex:1];
  
  
  // Grab the asset library
  ALAssetsLibrary *library = [IonicCameraRoll defaultAssetsLibrary];
  
  // Run a background job
  [self.commandDelegate runInBackground:^{
    __block int count = 0;
    // Enumerate all of the group saved photos, which is our Camera Roll on iOS
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
      
      // When there are no more images, the group will be nil
      if(group == nil) {
        
        // Send a null response to indicate the end of photostreaming
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      
      } else {
        
        // Enumarate this group of images
        
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
          
          UIImage* thumbImage = [UIImage imageWithCGImage:[asset thumbnail]];
    
          if(thumbImage) {
            NSData *data = UIImagePNGRepresentation(thumbImage);
            
            //[fileImage addObject:myImage];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[data base64EncodedStringWithOptions:0]];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            
            NSLog(@"Count: %d", count);
            count++;
            if(count > 32) {
              stop = YES;
            }
          }
          
          /*
          NSDictionary *urls = [asset valueForProperty:ALAssetPropertyURLs];
          
          [urls enumerateKeysAndObjectsUsingBlock:^(id key, NSURL *obj, BOOL *stop) {
            NSString* imageUrl = obj.absoluteString;
            UIImage* image = nil;
            
            
            // Send the URL for this asset back to the JS callback
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:obj.absoluteString];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
          
          }];
          */
        }];
      }
    } failureBlock:^(NSError *error) {
      // Ruh-roh, something bad happened.
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
  }];

}
  
  - (UIImage*)imageByScalingAndCroppingForSize:(UIImage*)anImage toSize:(CGSize)targetSize
  {
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
      CGFloat widthFactor = targetWidth / width;
      CGFloat heightFactor = targetHeight / height;
      
      if (widthFactor > heightFactor) {
        scaleFactor = widthFactor; // scale to fit height
      } else {
        scaleFactor = heightFactor; // scale to fit width
      }
      scaledWidth = width * scaleFactor;
      scaledHeight = height * scaleFactor;
      
      // center the image
      if (widthFactor > heightFactor) {
        thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
      } else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
      }
    }
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
      NSLog(@"could not scale image");
    }
    
    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
  }

@end

