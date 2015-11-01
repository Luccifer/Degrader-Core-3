//
//  DPLanczosResampler.m
//  DegradrCore3
//
//  Created by denn on 10.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPLanczosSampler.h"
#import "DPBiLinearSampler.h"

@implementation DPLanczosSampler

- (instancetype) initWithContext:(DPContext *)aContext{    
    self = [super initWithContext:aContext];
    if (self) {    
        self.sampleResolution = 5.0f;
        self.kernelWidth = 2.0f;
    }
    return self;
}

- (CGFloat) sync:(CGFloat)x{
    return sin(M_PI*x)/(M_PI*x);
}

- (CGFloat) convolution:(CGFloat)t{

    if (t == 0.0)
        return 1.0;
    
    if (ABS(t) > self.kernelWidth)
        return 0.0;
    
    return  [self sync:t] * [self sync:t/self.kernelWidth];
}

@end

