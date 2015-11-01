//
//  DPSmartResizeFilter.h
//  DegradrCore3
//
//  Created by denn on 26.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPSampleFilter.h"

@interface DPSmartResizeFilter : DPFilter
@property (nonatomic,assign) CGFloat imageSize;
@property (nonatomic,readonly) DPFilter<DPSampleFilterProtocol> *sampler;
@end
