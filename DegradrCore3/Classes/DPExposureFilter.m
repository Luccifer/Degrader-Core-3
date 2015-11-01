//
//  DPExposureFilter.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 02/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPExposureFilter.h"

@interface DPExposureFilter()
@property (nonatomic, strong)   id<MTLBuffer>    adjustmentUniform;
@end

@implementation DPExposureFilter
{
    DPFunction *kernel_filter;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {
        [self addFunction: kernel_filter = [DPFunction newFunction:@"kernel_adjustExposure" context:self.context]];
        self.adjustment = (DPExposureAdjustment){0.0f, (DPBlending){DP_BLENDING_LUMINOSITY,1.0f}};
    }
    
    return self;
}

- (void) setAdjustment:(DPExposureAdjustment)adjustment{
    _adjustment = adjustment;
    if (!_adjustmentUniform) {
        _adjustmentUniform  = [self.context.device newBufferWithLength:sizeof(_adjustment) options:MTLResourceOptionCPUCacheModeDefault];
    }
    memcpy([_adjustmentUniform contents], &_adjustment, sizeof(_adjustment));
    self.dirty = YES;
}

- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    
    if (function == kernel_filter) {
        [commandEncoder setBuffer:_adjustmentUniform offset:0 atIndex:0];
    }
}


@end