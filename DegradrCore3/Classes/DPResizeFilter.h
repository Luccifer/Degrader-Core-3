//
//  DPSmartSharpFilter.h
//  DegradrCore3
//
//  Created by denn on 19.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPUnsharpMaskFilter.h"
#import "DPLanczosSampler.h"
#import "DPKernelSampler.h"
#import "DPSampleFilter.h"

@interface DPResizeFilter : DPFilter
@property (nonatomic,assign) CGFloat                          maskRadius;
@property (nonatomic,assign) DPSoftUnsharpMaskIntensity       intensity;
@property (nonatomic,strong) DPFilter<DPSampleFilterProtocol> *sampler;
- (instancetype) initWithContext:(DPContext *)aContext withSampler:(DPFilter<DPSampleFilterProtocol>*)sampler;
@end
