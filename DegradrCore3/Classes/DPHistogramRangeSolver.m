//
//  DPHistogramRangeSolver.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramRangeSolver.h"
#import "DPHistogramMath.h"

@implementation DPHistogramRangeSolver

@synthesize histogramAnalizer=_histogramAnalizer;

- (instancetype) init{
    self = [super init];
    if (self) {
        _clippingShadows    = 0.05f/100.0f;
        _clippingHighlights = 0.01f/100.0f;
    }
    return self;
}

- (GLfloat) minimum:(float *)hist pixels:(float)denom
{
    return dpGetHistogramShadowsClipping(hist, denom, self.clippingShadows);
}

- (GLfloat) maximum:(float *)hist pixels:(float) denom{
    return dpGetHistogramHighlightsClipping(hist, denom, self.clippingHighlights);
}

- (void) updateSolverWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{
    float  denom = (float)(count);
    
    _min.r = [self minimum:histogram[0] pixels:denom];
    _min.g = [self minimum:histogram[1] pixels:denom];
    _min.b = [self minimum:histogram[2] pixels:denom];
    _min.a = [self minimum:histogram[3] pixels:denom];
    
    _max.r = [self maximum:histogram[0] pixels:denom];
    _max.g = [self maximum:histogram[1] pixels:denom];
    _max.b = [self maximum:histogram[2] pixels:denom];
    _max.a = [self maximum:histogram[3] pixels:denom];
    
    if (self.histogramAnalizer && self.histogramAnalizer.histogramSolverUpdatedBlock) {
        self.histogramAnalizer.histogramSolverUpdatedBlock(self, histogram, imageSize, count);
    }
}

@end
