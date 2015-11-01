//
//  DPNSDataProvider.h
//  DegradrCore3
//
//  Created by denn on 13.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPImageProvider.h"

/**
 *  Texture provider is bound with image from raw data (current version supports only jpeg).
 */
@interface DPNSDataProvider : DPImageProvider
/**
 *  New texture provider associated with image file.
 *
 *  @param data raw data of image
 *  @param aContext processing context
 *
 *  @return texture provider.
 */
+ (instancetype) newWithData:(NSData*)data context:(DPContext *)aContext;

/**
 *  New scaled texture provider associated with image file.
 *
 *  @param data raw data of image
 *  @param aContext processing context
 *  @param the desired max size of output texture, size can't be the exact size
 *
 *  @return texture provider.
 */
+ (instancetype) newWithData:(NSData*)data context:(DPContext *)aContext maxSize:(CGFloat)maxSize;
+ (instancetype) newWithData:(NSData*)data context:(DPContext *)aContext maxSize:(CGFloat)maxSize orientation:(UIImageOrientation)orientation;

/**
 *  Update provider from file.
 *
 *  @param data raw data of image
 *  @param error    error description or nil
 *  @param scale    he desired max size of output texture, size can't be the exact size
 */
- (void)         updateFromData:(NSData*)data maxSize:(CGFloat)maxSize;
- (void)         updateFromData:(NSData*)data maxSize:(CGFloat)maxSize orientation:(UIImageOrientation)orientation;

@end
