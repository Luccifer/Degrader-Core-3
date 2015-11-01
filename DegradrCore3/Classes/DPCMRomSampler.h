//
//  DPCMRomSampler.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 20/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPKernelSampler.h"

/**
 * A Catmull-rom spline interpolation sampler.
 * It based on https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
 */
@interface DPCMRomSampler : DPKernelSampler
@end
