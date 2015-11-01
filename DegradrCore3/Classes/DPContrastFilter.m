//
//  DPContrastFilter.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPContrastFilter.h"

@implementation DPContrastFilter

- (void) setRangeWithMin:(CGFloat)min withMax:(CGFloat)max withOpacity:(CGFloat)opacity blend:(DPFilterBlending)blend{
    self.adjustment = (DPLevelsAdjustment){
        
        (DPVector4){min,  min,  min,  1.0f}, //min
        (DPVector4){1.0f, 1.0f, 1.0f, 1.0f}, //mid
        (DPVector4){max,  max,  max,  1.0f}, //max
        
        (DPVector4){0.0f, 0.0f, 0.0f, 1.0f}, //min out
        (DPVector4){1.0f, 1.0f, 1.0f, 1.0f}, //max out
        
        (DPBlending){
            (int)blend,                           //blend mode
            opacity}                              //opacity
    };
    self.dirty = YES;
}

- (void) setAdjustmentContrast:(DPContrastAdjustment)adjustmentContrast{
    [self setRangeWithMin:adjustmentContrast.minimum withMax:adjustmentContrast.maximum withOpacity:adjustmentContrast.blending.opacity blend:adjustmentContrast.blending.mode];
    self.dirty = YES;
}

@end
