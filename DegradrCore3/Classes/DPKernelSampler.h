//
//  DPFancySampler.h
//  DegradrCore3
//
//  Created by denn on 19.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//


#import "DPFilter.h"
#import "DPSampleFilter.h"

/**
 * The base abstract sampler with triangular convolution by default.
 */
@interface DPKernelSampler : DPFilter<DPSampleFilterProtocol>
- (CGFloat) convolution:(CGFloat)t;
@end

