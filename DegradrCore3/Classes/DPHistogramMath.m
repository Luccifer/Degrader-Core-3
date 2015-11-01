//
//  DPMath.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 14.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramMath.h"

float dpGetHistogramShadowsClipping(const float hist[256], const float totalBins, const float clipping)
{
    float min = 0.0;
    float left = 0.0;
    
    for (int i=1; i<256; i++) {
        left += hist[i];
        
        if (left/totalBins>=clipping) {
            i = i>0?i-1:0;
            min = ((float)i)/255.0f;
            break;
        }
    }
    
    return min;
}

float dpGetHistogramHighlightsClipping(const float hist[256], const float totalBins, const float clipping){
    float max =0.0;
    float right = 0.0;
    for (int i=255; i>=0; i--) {
        right +=hist[i];
        
        if (right/totalBins >=clipping) {
            i = i<255?i+1:255;
            max = ((float)i)/255.0f;
            break;
        }
    }
    return max;
}

float dpGetHistogramConvolvedSum(const float hist[256], const float index[256], float tempbuffer[256]){
    float  rOU1;
    vDSP_vmul(hist, 1, index, 1, tempbuffer, 1, 256);
    vDSP_sve(tempbuffer, 1, &rOU1, 256);
    return rOU1;
}

void dpCreateNormalWeights(float x[256], const float mu, const float sigma, const float denom){
    //float fi = 1.0/(sigma*sqrt(2*M_PI));
    //float centerx = mu;
    //float maxval = dpGetGaussDistribution(centerx,fi,mu,sigma);
    for (int i = 0; i<255; i++) {
        x[i] = [[DPMathDistribution gaussYPointAtX:@((float)i/255.0f) withFi:@1 withMu:@(mu) withSigma:@(sigma)] floatValue];//   dpGetGaussDistribution(((float)i)/255.0,fi,mu,sigma)/maxval/denom;
        x[i] = x[i]>1.0?1.0:x[i];
    }
}

