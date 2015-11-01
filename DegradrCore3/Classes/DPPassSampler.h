//
//  DPPassSampler.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 20/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPSampleFilter.h"

/**
 * Sampler does nothing.
 */
@interface DPPassSampler : DPFilter<DPSampleFilterProtocol>
@end
