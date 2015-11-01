//
//  DPGaussianBlur.h
//  DegradrCore3
//
//  Created by denn on 20.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPConvolveFilter.h"

@interface DPGaussianBlur : DPConvolveFilter
@property (nonatomic,assign) float  radius;
@end
