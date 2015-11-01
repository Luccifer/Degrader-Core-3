//
//  DPImageURLProvider.h
//  DegradrCore3
//
//  Created by denn on 04.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPImageProvider.h"

/**
 *  Texture provider is bound with image from URL.
 */
@interface DPImageURLProvider : DPImageProvider
/**
*  New texture provider associated with image URL.
*
*  @param url of image
*  @param aContext processing context
*
*  @return texture provider.
*/
+ (instancetype) newWithImageURL:(NSURL*)url context:(DPContext *)aContext;

/**
 *  New scaled texture provider associated with image URL.
 *
 *  @param url of image
 *  @param aContext processing context
 *  @param the desired max size of output texture
 *
 *  @return texture provider.
 */
+ (instancetype) newWithImageURL:(NSURL*)url context:(DPContext *)aContext maxSize:(CGFloat)maxSize;

/**
 *  Update provider from url.
 *
 *  @param url path 
 *  @param error    error description or nil
 *  @param scale    he size of output texture
 */
- (void)         updateFromImageURL:(NSURL*)url error:(NSError **)error maxSize:(CGFloat)maxSize;

@end
