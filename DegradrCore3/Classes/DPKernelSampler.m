//
//  DPFancySampler.m
//  DegradrCore3
//
//  Created by denn on 19.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPKernelSampler.h"
#import "DPSampleFilter.h"


@interface __DSampler_private : DPSampleFilter // hide lanczos kernel
@end

@interface __DSampler_private()
@property (nonatomic, strong)   id<MTLBuffer>    kernelSizeUniform;
@end

@implementation __DSampler_private
- (instancetype) initWithContext:(DPContext *)aContext{    
    self = [super initWithContext:aContext];
    if (self) {    
        
        //
        // precomputed private_fancy convolution kernel one pass row
        // sampleResolution = 4
        //
        
        self.kernel = @[
                        @0.0625,
                        @0.25,
                        @0.375,
                        @0.25,
                        @0.0625
                        ];
    }
    return self;
}
@end

@implementation DPKernelSampler
{
    __DSampler_private *private_fancy;
}

@synthesize kernelWidth = _kernelWidth;
@synthesize sampleResolution = _sampleResolution;
@synthesize imageSize = _imageSize;

- (instancetype) initWithContext:(DPContext *)aContext{    
    self = [super initWithContext:aContext];
    if (self) {    
        private_fancy  = [__DSampler_private newWithContext:self.context];
        _kernelWidth = 2.0;
        self.sampleResolution = 4.0f;
        [self addFilter:private_fancy];
    }
    return self;
}

- (void) setSampleResolution:(CGFloat)sampleResolution{
    _sampleResolution=sampleResolution;
    [self rebuildConvolution];
}

- (void) setImageSize:(CGFloat)imageSize{
    private_fancy.imageSize = imageSize;
    [private_fancy flush];
}

- (void) setKernelWidth:(CGFloat)kernelWidth{
    _kernelWidth = kernelWidth;
    [self rebuildConvolution];
}

- (CGFloat) kernelWidth{
    return _kernelWidth;
}

- (CGFloat) imageSize{
    return private_fancy.imageSize;
}

- (CGFloat) convolution: (CGFloat)t{
    CGFloat f = t / 2.0;
    
    if( f < 0.0 )
    {
        return ( f + 1.0 );
    }
    else
    {
        return ( 1.0 - f );
    }
    return 0.0;
}

- (void) rebuildConvolution{
    [private_fancy flush];
    
    NSMutableArray *convolve = [NSMutableArray new];
    
    CGFloat weightSum = 0.0;
    
    CGFloat step = self.kernelWidth/self.sampleResolution;
    
    
    for (CGFloat t = -self.kernelWidth; t<=self.kernelWidth; t+=step) {
        NSNumber *l = [NSNumber numberWithFloat:[self convolution:t]];
        if ([l floatValue]>0.0) {
            [convolve addObject:l];            
            weightSum += [l floatValue];            
        }                
    }
    CGFloat weightScale = 1.0/weightSum;
    
    for (NSUInteger i=0; i<convolve.count; i++) {
        NSNumber *l = [convolve objectAtIndex:i];
        convolve[i] = [NSNumber numberWithFloat: [l floatValue] * weightScale];            
    }       
    
    private_fancy.kernel = convolve;     
}

@end
