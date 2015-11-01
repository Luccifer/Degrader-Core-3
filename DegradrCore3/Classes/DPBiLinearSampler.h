//
//  DPBlinearSampler.h
//  DegradrCore3
//
//  Created by denn on 13.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPSampleFilter.h"

/**
 * Classic bi-linear sampler. It uses 2x2 sampling.
 */
@interface DPBiLinearSampler : DPFilter<DPSampleFilterProtocol>
@end
