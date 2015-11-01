//
//  DPBlinearSampler.m
//  DegradrCore3
//
//  Created by denn on 13.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPBiLinearSampler.h"

@implementation DPBiLinearSampler
{
    DPFunction *kernel_function;
}

@synthesize sampleResolution = _sampleResolution;
@synthesize imageSize = _imageSize;
@synthesize kernelWidth = _kernelWidth;

- (CGFloat) sampleResolution{
    return 2.0f;
}

- (CGFloat) kernelWidth{
    return 2.0f;
}

- (void) setSampleResolution:(CGFloat)sampleResolution{
    NSLog(@" *** BiLinear 2x2 sampler has fixed sampler resolution...");
}

- (void) setKernelWidth:(CGFloat)kernelWidth{
    NSLog(@" *** BiLinear 2x2 sampler has fixed kernel width...");
}

- (void) apply{
    if (self.imageSize>0.0 && self.imageSize<=[DPContext maximumTextureSize]) {
        CGFloat max   = MAX([self.source.texture width], [self.source.texture height]);
        CGFloat scale = self.imageSize/max;
        if (scale!=1.0f && scale>0.0f) {
            kernel_function.resampleFactor = (DPVector2){scale, scale};
        }
    }
    [super apply];
}

- (instancetype) initWithContext:(DPContext *)aContext{    
    self = [super initWithContext:aContext];
    if (self) {    
        [self addFunction: kernel_function  = [DPFunction newFunction:@"kernel_biLinear22Sampler" context:aContext]];
    }
    return self;
}


@end
