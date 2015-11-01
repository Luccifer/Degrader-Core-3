//
//  DPbrightnessFilter.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 02/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
typedef struct{
    float         brightness;
    DPBlending    blending;
} DPBrightnessAdjustment;

@interface DPBrightnessFilter : DPFilter
/**
 *  Brightness ranges from -1.0 to 10., with 0.0 as the normal level
 */
@property (nonatomic,assign) DPBrightnessAdjustment adjustment;
@end
