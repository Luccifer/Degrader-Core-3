//
//  DPUImageProvider.h
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPImageProvider.h"

/**
 *  Provide texture from UIImage object.
 */
@interface DPUIImageProvider : DPImageProvider

/**
 *  Create new provider with image.
 *
 *  @param image    UIImage object
 *  @param aContext processing context
 *
 *  @return new provider instance
 */
+ (instancetype) newWithImage:(UIImage*)anImage context:(DPContext *)aContext;

/**
 *  Create new scaled provider with image.
 *
 *  @param filePath file path to image
 *  @param aContext processing context
 *  @param the desired max size of output texture
 *
 *  @return texture provider.
 */
+ (instancetype) newWithImage:(UIImage*)anImage context:(DPContext *)aContext maxSize:(CGFloat)maxSize;

/**
 *  Update provider from new image.
 *
 *  @param aImage UIImage object.
 */
- (void) updateFromImage:(UIImage*)anImage;

/**
 *  Update provider from file.
 *
 *  @param filePath file path 
 *  @param scale    he desired max size of output texture, size can't be the exact size
 */
- (void) updateFromImage:(UIImage*)anImage maxSize:(CGFloat)maxSize;

@end
