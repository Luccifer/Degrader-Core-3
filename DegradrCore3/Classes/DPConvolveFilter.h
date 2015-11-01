//
//  DPСonvolveFilter.h
//  DegradrCore3
//
//  Created by denn on 10.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"

/**
 * A fast convolve filter. It uses simmetric convolution matrix in two-pass-filtering manner.
 * To reduce GPU utilization from matrix removes right-bottom part at intialization step.
 */
@interface DPConvolveFilter : DPFilter
@property (nonatomic,assign)  float  scale;
/**
 * Must be simmetric matrix of convolution weights
 */
@property (nonatomic,strong)  NSMutableArray *weights;
@end
