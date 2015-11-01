//
//  DPSampleFilter.h
//  DegradrCore3
//
//  Created by denn on 13.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPMath.h"

@protocol DPSampleFilterProtocol <DPFilterProtocol>

@required

/**
 * The final image size in pixels.
 */
@property (nonatomic,assign) CGFloat imageSize;

/**
 * Sampler resolution. It means how many texels involved to sample computation.
 */
@property (nonatomic,assign) CGFloat sampleResolution;

@optional
/**
 * Some samplers, like lanczos, need additional parameteres.
 */
@property (nonatomic,assign) CGFloat kernelWidth;

@end

/**
 * Abstract sampler filter. Specific convolution defines in a specific sampler object.
 */
@interface DPSampleFilter : DPFilter
/**
 * Kernel convolution array.
 */
@property (nonatomic,strong) NSArray *kernel;
/**
 * The final image size.
 */
@property (nonatomic,assign) CGFloat  imageSize;
@end
