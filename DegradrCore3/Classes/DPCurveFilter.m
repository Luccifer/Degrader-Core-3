//
//  DPCurveFilter.m
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright © 2015 Degradr.Photo. All rights reserved.
//

#import "DPCurveFilter.h"

@interface NSArray (DPGLExtention)
/**
 *  Hash lookup kye uses to find already prepared spline curve.
 *  Hash decreases precision floating in initial curve points to increase total perfomance...
 *  @return hash key
 */
- (NSString*) hashLookUp;
@end

@implementation NSArray(DPGLExtention)

- (NSString*) hashLookUp{
    
    NSMutableString *key = [[NSMutableString alloc] initWithString:@"Curve-"];
    
    for (NSValue *value in self) {
        CGPoint point = [value CGPointValue];
        [key appendFormat:@"%.2f-%.2f",point.x,point.y];
    }
    
    return key;
}

@end


@interface DPCurveFilter()

@property (nonatomic, strong)   id<MTLBuffer>    adjustmentUniform;

@property (nonatomic, assign) GLubyte *toneCurveByteArray;

@property (nonatomic, strong) NSArray *redCurve;
@property (nonatomic, strong) NSArray *greenCurve;
@property (nonatomic, strong) NSArray *blueCurve;
@property (nonatomic, strong) NSArray *rgbCompositeCurve;

@property (nonatomic, strong) NSMutableDictionary *splineCache;

@end

@implementation DPCurveFilter
{
    DPFunction *kernel_filter;
}


- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {
        
        [self addFunction: kernel_filter = [DPFunction newFunction:@"kernel_adjustCurve" context:self.context]];
        self.adjustment = (DPCurveAdjustment){
            (DPBlending){DP_BLENDING_LUMINOSITY,
                1.0}
        };
                
        _splines = [[DPCurveSplines alloc] initWithContext:self.context];        
    }    
    return self;
}


#pragma mark - 
#pragma mark - Adjustment

- (void) setAdjustment:(DPCurveAdjustment)adjustment{
    _adjustment = adjustment;
    if (!_adjustmentUniform) {
        _adjustmentUniform  = [self.context.device newBufferWithLength:sizeof(_adjustment) options:MTLResourceOptionCPUCacheModeDefault];
    }
    memcpy([_adjustmentUniform contents], &_adjustment, sizeof(_adjustment));
    self.dirty = YES;
}

- (void) setSplines:(DPCurveSplines *)splines{
    self.dirty = YES;
    _splines = splines;
}

- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    
    if (function == kernel_filter) {
        [commandEncoder setTexture:self.splines.texture atIndex:2];
        [commandEncoder setBuffer:_adjustmentUniform offset:0 atIndex:0];
    }
}

@end
