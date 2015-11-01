//
//  DPHistogramAvarageSolver.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramAvarageSolver.h"
#import "DPHistogramMath.h"

@implementation DPHistogramAvarageSolver
{
    float            buffer[256];
    float            index[256];
}

@synthesize histogramAnalizer=_histogramAnalizer;

- (instancetype)init{
    self = [super init];
    if (self) {
        for (int i=0; i<256; i++) {
            index[i]=(float)i/255.0f;
        }
    }
    return self;
}

- (void) updateSolverWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{    
    _avarageColor.r  = dpGetHistogramConvolvedSum(histogram[0], index, buffer)/(float)count;
    _avarageColor.g  = dpGetHistogramConvolvedSum(histogram[1], index, buffer)/(float)count;
    _avarageColor.b  = dpGetHistogramConvolvedSum(histogram[2], index, buffer)/(float)count;
    _avarageColor.a  = dpGetHistogramConvolvedSum(histogram[3], index, buffer)/(float)count;
    if (self.histogramAnalizer && self.histogramAnalizer.histogramSolverUpdatedBlock) {
        self.histogramAnalizer.histogramSolverUpdatedBlock(self, histogram, imageSize, count);
    }
}
@end
