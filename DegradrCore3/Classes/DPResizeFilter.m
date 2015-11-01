//
//  DPSmartSharpFilter.m
//  DegradrCore3
//
//  Created by denn on 19.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPResizeFilter.h"

@implementation DPResizeFilter
{
    DPSoftUnsharpMaskFilter *softSharpFilter;
}

@synthesize sampler = _sampler;

- (instancetype) initWithContext:(DPContext *)aContext withSampler:(DPFilter<DPSampleFilterProtocol>*)sampler{
    self = [super initWithContext:aContext];
    if (self) {
        softSharpFilter = [DPSoftUnsharpMaskFilter newWithContext:self.context];
        _sampler = sampler;
        [self addFilter:_sampler];
        [self addFilter:softSharpFilter];
    }
    return self;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithContext:aContext];
    if (self) {
        softSharpFilter = [DPSoftUnsharpMaskFilter newWithContext:self.context];
        _sampler = [DPLanczosSampler newWithContext:self.context];
        [self addFilter:_sampler];
        [self addFilter:softSharpFilter];
    }
    return self;
}


- (DPFilter<DPSampleFilterProtocol>*) sampler{
    if (!_sampler) {
        _sampler = [DPLanczosSampler newWithContext:self.context];
    }
    return _sampler;
}

- (void) setMaskRadius:(CGFloat)maskRadius{
    [_sampler flush];
    [softSharpFilter flush];
    softSharpFilter.radius = maskRadius;
    self.dirty = YES;
}

- (CGFloat) maskRadius{
    return softSharpFilter.radius;
}

- (void) setIntensity:(DPSoftUnsharpMaskIntensity)intensity{
    [_sampler flush];
    [softSharpFilter flush];
    softSharpFilter.intensity = intensity;
    self.dirty = YES;
}

- (DPSoftUnsharpMaskIntensity) intensity{
    return softSharpFilter.intensity;
}

- (void) setSampler:(DPFilter<DPSampleFilterProtocol> *)sampler{

    [_sampler flush];
    [softSharpFilter flush];

    [self removeAllFilters];    
    _sampler = sampler;
    [self addFilter:_sampler];
    [self addFilter:softSharpFilter];
    
    self.dirty = YES;
}

@end
