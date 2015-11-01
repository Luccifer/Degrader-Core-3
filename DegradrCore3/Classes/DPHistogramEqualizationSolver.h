//
//  DPHistogramEqualizationSolver.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPHistogramAnalizer.h"

typedef struct {
    float weights[256];
}DPHistogramEqualizationWeights;

@interface DPHistogramEqualizationSolver : NSObject<DPHistogramSolverProtocol>
@property (nonatomic,readonly) DPHistogramEqualizationWeights equalization;
@end
