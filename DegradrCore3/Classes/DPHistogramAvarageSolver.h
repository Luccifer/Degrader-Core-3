//
//  DPHistogramAvarageSolver.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPHistogramAnalizer.h"

@interface DPHistogramAvarageSolver : NSObject<DPHistogramSolverProtocol>
@property (nonatomic,readonly) DPVector4 avarageColor;
@end
