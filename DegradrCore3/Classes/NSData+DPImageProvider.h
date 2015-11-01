//
//  NSData+DPImageProvider.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 07/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

@class DPImageProvider;

/**
 *  Make NSDaata object represented as jpeg data in memory.
 */
@interface NSData(DPImageProvider)
/**
 *  Create jpeg in memory uses NSData as a storage.
 *
 *  @param provider texture provider
 *  @param quality  jpeg quality: 0-1
 *
 *  @return data
 */
+ (NSData*) jpegWithImageProvider:(DPImageProvider*)provider quality:(CGFloat)quality;

@end