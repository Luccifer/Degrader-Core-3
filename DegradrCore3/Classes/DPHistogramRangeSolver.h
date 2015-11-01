//
//  DPHistogramRangeSolver.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 15.09.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPHistogramAnalizer.h"

@interface DPHistogramRangeSolver : NSObject<DPHistogramSolverProtocol>
/**
 * Shadows minimum.
 */
@property(nonatomic,readonly) DPVector4 min;
/**
 * Highlights maximum.
 */
@property(nonatomic,readonly) DPVector4 max;
/**
 *  Shadows threshold clipping, in %
 */
@property(nonatomic, assign) GLfloat clippingShadows;
/**
 *  Highlights threshold clipping, in %
 */
@property(nonatomic, assign) GLfloat clippingHighlights;
@end
