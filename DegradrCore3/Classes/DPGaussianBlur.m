//
//  DPGaussianBlur.m
//  DegradrCore3
//
//  Created by denn on 20.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPGaussianBlur.h"

@interface DPGaussianBlur()
@property (nonatomic,assign) float sigma;
@end

@implementation DPGaussianBlur
{
    DPFunction *kernel_filter_passFirst;
    DPFunction *kernel_filter_passSecond;
    NSMutableArray *gaussianWeights;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    if (self) {
        self.radius = 0.0;
    }
    
    return self;
}

//
//  by Warren Moore on 10/8/14.
//
- (void)generateGaussian
{
    NSAssert(self.radius >= 0, @"Blur radius must be non-negative");
    
    if (self.radius==0) {
        gaussianWeights = [NSMutableArray new];
        [gaussianWeights addObject:@(1.0)];
        return;
    }
    
    const float radius = self.radius;
    const float sigma  = self.sigma;
    const int   size   = (round(radius) * 2) + 1;
    
    float delta = 0;
    float expScale = 0;;
    if (radius > 0.0)
    {
        delta = (radius * 2) / (size - 1);;
        expScale = -1 / (2 * sigma * sigma);
    }
    
    float *weights = malloc(sizeof(float) * size * size);
    
    float weightSum = 0;
    float y = -radius;

    float x = -radius;
    
    for (int i = 0; i < size; ++i, x += delta)
    {
        float weight = expf((x * x + y * y) * expScale);
        weights[i] = weight;
        weightSum += weight;
    }
    
    gaussianWeights = [NSMutableArray new];
    
    const float weightScale = 1 / weightSum;
    for (int i = 0; i < size; ++i)
    {
        weights[i] *= weightScale;
        [gaussianWeights addObject:@(weights[i])];
    }
                
    free(weights);
}

- (void)setRadius:(float)radius
{
    self.dirty = YES;

    _radius = radius;
    _sigma  = _sigma<=0.0?radius / 2:_sigma;    
    [self generateGaussian];    
    self.weights = gaussianWeights;    
}

- (void)setSigma:(float)sigma
{
    _sigma = sigma;
}

- (void) setScale:(float)scale{
    [super setScale:scale];
}

@end
