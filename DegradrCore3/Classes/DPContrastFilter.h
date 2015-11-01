//
//  DPContrastFilter.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPLevelsFilter.h"

typedef struct{    
    float minimum;
    float maximum;
    DPBlending  blending;
} DPContrastAdjustment;

@interface DPContrastFilter : DPLevelsFilter
@property (nonatomic,assign) DPContrastAdjustment adjustmentContrast;
@end
