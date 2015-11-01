//
//  DPSmartResizeFilter.m
//  DegradrCore3
//
//  Created by denn on 26.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPSmartResizeFilter.h"
#import "DPLanczosSampler.h"
#import "DPResizeFilter.h"

#define __DP_BASE_RESOLUTION 7.1f
#define __DP_BASE_MAXSIZE    3264.0f

@interface DPSmartResizeFilter()
@end

@implementation DPSmartResizeFilter
{
    DPResizeFilter                   *resizer;
}
@synthesize sampler = _sampler;


- (DPFilter<DPSampleFilterProtocol>*) sampler{
    return _sampler;
} 

- (void) setSampler:(DPFilter<DPSampleFilterProtocol> *)sampler{
    _sampler=sampler;
    self.dirty = YES;
}

- (void) setImageSize:(CGFloat)imageSize{
    self.sampler.imageSize = imageSize;
}

- (CGFloat) imageSize{
    return self.sampler.imageSize;
}

- (void) setSource:(DPImageProvider *)source{
    [self flush];
    [super setSource:source];
}

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithContext:aContext];
    if (self) {
        _sampler = [DPLanczosSampler newWithContext:self.context];
        _sampler.kernelWidth = 2.0f;
        _sampler.sampleResolution = __DP_BASE_RESOLUTION;        
        resizer = [[DPResizeFilter alloc] initWithContext:self.context withSampler:_sampler];
        resizer.maskRadius = 0.66;
        DPSoftUnsharpMaskIntensity intensity = resizer.intensity;
        intensity.dark = 1.0;
        intensity.light = 0.46;
        intensity.blending.mode = DP_BLENDING_NORMAL;
        intensity.blending.opacity = 1.0;
        resizer.intensity = intensity;
        [self addFilter:resizer];
    }
    return self;
}

- (void) apply{
    CGFloat max   = MAX([self.source.texture width], [self.source.texture height]);
    CGFloat scale = max/__DP_BASE_MAXSIZE;
    CGFloat resolution = __DP_BASE_RESOLUTION * scale;
    _sampler.sampleResolution = resolution<1.0?1.0:resolution;
    if (_sampler.sampleResolution<3.0f) {
        _sampler.kernelWidth = 3.0f;
    }
    else
        _sampler.kernelWidth = 2.0f;
    
    NSLog(@" *** DPSmartResizeFilter resolution = %f", resolution);
    
    [super apply];
}

@end
