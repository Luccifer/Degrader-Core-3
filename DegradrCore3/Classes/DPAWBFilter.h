//
//  DPAWBFilter.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPMath.h"

typedef struct {
    DPVector4   averageColor;
    DPBlending  blending;
} DPAWBAdjustment;

@interface DPAWBFilter : DPFilter
@property (nonatomic,assign) DPAWBAdjustment adjustment;
@end
