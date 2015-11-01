//
//  DPExposureFilter.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 02/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"


typedef struct{
    float         exposure;
    DPBlending   blending;
} DPExposureAdjustment;

@interface DPExposureFilter : DPFilter
/**
 *  Exposure ranges from -10.0 to 10.0, with 0.0 as the normal level
 */
@property (nonatomic,assign) DPExposureAdjustment adjustment;
@end
