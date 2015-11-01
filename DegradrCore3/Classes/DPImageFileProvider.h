//
//  DPImageFileProvider.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 23/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPImageProvider.h"

/**
 *  Texture provider is bound with image file (current version supports only jpeg).
 */
@interface DPImageFileProvider : DPImageProvider
/**
 *  New texture provider associated with image file.
 *
 *  @param filePath file path to image
 *  @param aContext processing context
 *
 *  @return texture provider.
 */
+ (instancetype) newWithImageFile:(NSString*)filePath context:(DPContext *)aContext;

/**
 *  New scaled texture provider associated with image file.
 *
 *  @param filePath file path to image
 *  @param aContext processing context
 *  @param the desired max size of output texture, size can't be the exact size
 *
 *  @return texture provider.
 */
+ (instancetype) newWithImageFile:(NSString*)filePath context:(DPContext *)aContext maxSize:(CGFloat)maxSize;
+ (instancetype) newWithImageFile:(NSString*)filePath context:(DPContext *)aContext maxSize:(CGFloat)maxSize orientation:(UIImageOrientation)orientation;

/**
 *  Update provider from file.
 *
 *  @param filePath file path 
 *  @param error    error description or nil
 *  @param scale    he desired max size of output texture, size can't be the exact size
 */
- (void)         updateFromImageFile:(NSString*)filePath error:(NSError **)error maxSize:(CGFloat)maxSize;
- (void)         updateFromImageFile:(NSString*)filePath error:(NSError **)error maxSize:(CGFloat)maxSize orientation:(UIImageOrientation)orientation;
@end
