//
//  DPHSVFilter.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 18/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"

typedef struct {
    
    DPVector4 reds;
    DPVector4 yellows;
    DPVector4 greens;
    DPVector4 cyans;
    DPVector4 blues;
    DPVector4 magentas;
    
    DPBlending  blending;
    
} DPHSVAdjustment;


@interface DPHSVFilter : DPFilter
//
// precomputed weights of hues, it uses for adjustment overlaps
//
+ (DPTextureRef) defaultHueWeightsWithContext:(DPContext*)context;
@property (nonatomic, readonly)   DPTextureRef      hueWeights;
@property (nonatomic, assign)     DPHSVAdjustment   adjustment;
@end
