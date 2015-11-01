//
//  DPPixelBufferProvider.h
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPImageProvider.h"

/**
 *  Cachable well-performance texture representation from camera frame stream.
 */
@interface DPPixelBufferProvider : DPImageProvider
/**
 *  Update provider from camera stream.
 *
 *  @param pixelBuffer  camera frame pixel buffer
 */
- (void) updateFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end
