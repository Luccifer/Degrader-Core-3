//
//  DPHistogramZonesSolver.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramZonesSolver.h"
#import "DPConstants.h"
#import "DPHistogramMath.h"
#import <Accelerate/Accelerate.h>

@implementation DPHistogramZonesSolver
{
    float            tempBuffer[256];
    float            shadowsBalanceWeights[256];
    float            middleBalanceWeights[256];
    float            highlightsBalanceWeights[256];
    NSUInteger       zoneIndices[12];
}

@synthesize histogramAnalizer=_histogramAnalizer;

static void dpCreateZonesFromHistogram(const float hist[256], CGFloat zones[12], NSUInteger zoneIndices[12], NSUInteger binsCount){
    float zone_value;
    for (int i=0; i<12; i++) {
        NSUInteger is = zoneIndices[i];

        if (i==0 || i==11) {
           zones[i]=hist[is]/binsCount;
        }
        else{
            NSUInteger ie = zoneIndices[i+1];
            vDSP_sve(&hist[is], 1, &zone_value, ie-is );
            zones[i]=(CGFloat)zone_value/binsCount;
        }
    }
    
}

- (instancetype) init{
    self = [super init];
    if (self) {
        dpCreateNormalWeights(shadowsBalanceWeights,    0.0, 0.1, 1.1);
        dpCreateNormalWeights(middleBalanceWeights,     0.5, 0.1, 1.0);
        dpCreateNormalWeights(highlightsBalanceWeights, 1.0, 0.2, 1.0);
        
        zoneIndices[0]  =  0;   // 0    black
        zoneIndices[1]  =  1;   // I    dark, no details
        zoneIndices[2]  =  33;  // II   near dark
        zoneIndices[3]  =  51;  // III  shadows details
        zoneIndices[4]  =  72;  // IV   medium dark
        zoneIndices[5]  =  94;  // V    average gray, 18% gray
        zoneIndices[6]  =  118; // VI   mid-tone
        zoneIndices[7]  =  143; // VII  high-light
        zoneIndices[8]  =  169; // VIII lights
        zoneIndices[9]  =  197; // IX   near white
        zoneIndices[10] =  225; // X    white
        zoneIndices[11] =  255; // XI   pure white
    }
    return self;
}

- (void) updateSolverWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{
    //
    // http://dpanswers.com/content/tech_zonesystem.php
    // http://fall2014lightingclasspm.blogspot.ru/2014/09/lesson-1-inverse-square-law.html
    //
    
    float *hist    = histogram[3];

    dpCreateZonesFromHistogram(hist,_interest.zones,zoneIndices,count);
    
    DPVector3 balance;
    DPVector3 spots;
    DPVector3 dr;
    
    balance.x = dpGetHistogramConvolvedSum(hist, shadowsBalanceWeights,    tempBuffer)/count;
    balance.y = dpGetHistogramConvolvedSum(hist, middleBalanceWeights,     tempBuffer)/count;
    balance.z = dpGetHistogramConvolvedSum(hist, highlightsBalanceWeights, tempBuffer)/count;
    
    _interest.balance = [DPMathVector normalizeVector3:balance];// dpNormalizeVector3(balance);
    
    CGFloat *zone = self.interest.zones;
    
    spots.x = zone[3];
    spots.y = zone[5];
    spots.z = zone[7];
    
    _interest.spots = [DPMathVector normalizeVector3:spots];// dpNormalizeVector3(spots);
    
    dr.x = zone[1]+zone[2]+zone[3];
    dr.y = zone[4]+zone[5]+zone[6];
    dr.z = zone[7]+zone[8]+zone[9];
    
    _interest.range = [DPMathVector normalizeVector3:dr]; //dpNormalizeVector3(dr);
    
    if (self.histogramAnalizer && self.histogramAnalizer.histogramSolverUpdatedBlock) {
        self.histogramAnalizer.histogramSolverUpdatedBlock(self, histogram, imageSize, count);
    }
}

@end
