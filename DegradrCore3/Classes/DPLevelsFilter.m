//
//  DPLevelsFilter.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPLevelsFilter.h"

@interface DPLevelsFilter()
@property (nonatomic, strong)   id<MTLBuffer>    adjustmentUniform;
@end

@implementation DPLevelsFilter
{
    DPFunction *kernel_filter;
}
@synthesize exposureCompensation=_exposureCompensation;

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {
        [self addFunction: kernel_filter = [DPFunction newFunction:@"kernel_adjustLevels" context:self.context]];
        self.adjustment = (DPLevelsAdjustment){
            
            (DPVector4){0.0f, 0.0f, 0.0f, 1.0f}, //min
            (DPVector4){1.0f, 1.0f, 1.0f, 1.0f}, //mid
            (DPVector4){1.0f, 1.0f, 1.0f, 1.0f}, //max
            
            (DPVector4){0.0f, 0.0f, 0.0f, 1.0f}, //min out
            (DPVector4){1.0f, 1.0f, 1.0f, 1.0f}, //max out
            
            (DPBlending){(int)DP_BLENDING_LUMINOSITY,               //blend mode
                (float)1.0f}                                //opacity
        };
    }
    
    return self;
}

- (void) setAdjustment:(DPLevelsAdjustment)adjustment{
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

- (void) setMinOut:(CGFloat)minOut mid:(CGFloat)mid maxOut:(CGFloat)maxOut{
    
    float opacity = _adjustment.blending.opacity;
    DPFilterBlending blend = _adjustment.blending.mode;
    
    self.adjustment = (DPLevelsAdjustment){
        
        (DPVector4){0.0f, 0.0f, 0.0f, 1.0f}, //min
        (DPVector4){mid,  mid,  mid,  1.0f}, //mid
        (DPVector4){1.0f, 1.0f, 1.0f, 1.0f}, //max
        
        (DPVector4){minOut, minOut, minOut, 1.0f}, //min out
        (DPVector4){maxOut, maxOut, maxOut, 1.0f}, //max out
        
        (DPBlending){(int)blend,               //blend mode
            (float)opacity}            //opacity
    };
    
    self.dirty = YES;
}

- (void) setExposureCompensation:(CGFloat)exposureCompensation{
    self.dirty = YES;
    _exposureCompensation = exposureCompensation;
    GLfloat m1 = (GLfloat)(1.0-(1.0f-_exposureCompensation)*6.0/8.0);
    GLfloat m2 = (GLfloat)(1.0-(1.0f-_exposureCompensation)*2.0/8.0);
    [self setMinOut:0 mid:m1 maxOut:m2];
}

@end
