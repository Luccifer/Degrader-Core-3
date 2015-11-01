//
//  DPCurveFilter.h
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPCurveSplines.h"

typedef struct{
    DPBlending       blending;
} DPCurveAdjustment;

@interface DPCurveFilter : DPFilter

@property(nonatomic, assign) DPCurveAdjustment  adjustment; 
@property(nonatomic, strong) DPCurveSplines    *splines;

@end
