//
//  DPHistogramEqualizationSolver.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramEqualizationSolver.h"

@implementation DPHistogramEqualizationSolver

@synthesize histogramAnalizer=_histogramAnalizer;

- (void) updateSolverWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{
    float cumulative = 0.0;
    for (int i=0; i<256; i++) {
        cumulative += histogram[3][i];// Luminance;
        _equalization.weights[i] = cumulative/count;
    }
    if (self.histogramAnalizer && self.histogramAnalizer.histogramSolverUpdatedBlock) {
        self.histogramAnalizer.histogramSolverUpdatedBlock(self, histogram, imageSize, count);
    }
}

@end
