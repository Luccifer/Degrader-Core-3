//
//  UIImage+DPImageProvider.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 07/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DPImageProvider;

/**
 *  UIImage extention. Avoid use UIImage representation for larg images.
 */
@interface UIImage(DPImageProvider)

/**
 *  Create UIImage with image texture provider.
 *
 *  @param provider image texture provider
 *
 *  @return UIImage instance
 */
+ (UIImage*) imageWithImageProvider:(DPImageProvider*)provider;

/**
 *  Create UIImage with image texture provider.
 *
 *  @param provider    texture provider
 *  @param scale       scale factor
 *  @param orientation image orientation
 *
 *  @return UIImage instance.
 */
+ (UIImage*) imageWithImageProvider:(DPImageProvider*)provider scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;

-(UIImage*) drawText:(NSString*) text atPoint:(CGPoint)   point;
@end

