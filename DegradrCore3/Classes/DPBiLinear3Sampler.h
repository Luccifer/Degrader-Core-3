//
//  DPBiCubicSampler.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 21/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPSampleFilter.h"

/**
 * Compromised bi-linear sampler. It uses 3x3 sampling.
 */
@interface DPBiLinear3Sampler : DPFilter<DPSampleFilterProtocol>
@end
