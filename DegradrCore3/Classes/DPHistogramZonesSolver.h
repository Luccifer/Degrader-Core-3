//
//  DPHistogramZonesSolver.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPHistogramAnalizer.h"

typedef struct{
    CGFloat    zones[12];
    DPVector3 spots;
    DPVector3 range;
    DPVector3 balance;
} DPHistogramZones;

@interface DPHistogramZonesSolver: NSObject<DPHistogramSolverProtocol>
@property(nonatomic,readonly) DPHistogramZones interest;
@end
