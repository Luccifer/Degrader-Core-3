//
//  DPHistogramMath.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 14.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPMath.h"

/**
 * Find maximum of shadows clipped index normalized in histogram width (1/256).
 */
extern float dpGetHistogramShadowsClipping(const float hist[256], const float totalBins, const float clipping);

/**
 * Find minimum of highlights clipped index normalized in histogram width.
 */
extern float dpGetHistogramHighlightsClipping(const float hist[256], float totalBins, const float clipping);

/**
 * Apply convolution with weigths to input histogram uses tempbuffer and sum up the result.
 */
extern float dpGetHistogramConvolvedSum(const float hist[256], const float weights[256], float tempbuffer[256]);

/**
 * Fill outputWeghts with normalized Gauss Distribution.
 */
extern void dpCreateNormalWeights(float outputWeights[256], const float mu, const float sigma, const float denom);

