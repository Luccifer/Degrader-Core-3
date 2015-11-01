//
//  DPLevelsFilter.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"

typedef struct{

    DPVector4 minimum;
    DPVector4 middle;
    DPVector4 maximum;
    
    DPVector4 minOutput;
    DPVector4 maxOutput;
    
    DPBlending  blending;
    
} DPLevelsAdjustment;


@interface DPLevelsFilter : DPFilter
@property (nonatomic,assign) DPLevelsAdjustment adjustment;
@property (nonatomic,assign) CGFloat            exposureCompensation;
- (void) setMinOut:(CGFloat)minOut mid:(CGFloat)mid maxOut:(CGFloat)maxOut; 
@end
