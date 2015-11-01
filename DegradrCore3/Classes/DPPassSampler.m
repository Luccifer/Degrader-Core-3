//
//  DPPassSampler.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 20/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPPassSampler.h"
#import "DPConstants.h"

@implementation DPPassSampler

@synthesize sampleResolution=_sampleResolution;
@synthesize kernelWidth = _kernelWidth;
@synthesize imageSize = _imageSize;

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithVertex:DP_VERTEX_DEF_FUNCTION withFragment:DP_FRAGMENT_DEF_FUNCTION context:aContext];
    return self;
}
@end
