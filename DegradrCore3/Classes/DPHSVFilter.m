//
//  DPHSVFilter.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 18/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPHSVFilter.h"


@interface DPHueRamp : NSObject
@property (nonatomic,assign) DPVector4 ramp;
+ (instancetype) newWithRamp:(DPVector4) ramp;
@end

@implementation DPHueRamp

+ (instancetype) newWithRamp:(DPVector4)ramp{
    return [[DPHueRamp alloc] initWithRamp:ramp];
}

- (instancetype) initWithRamp:(DPVector4)ramp{
    self = [super init];
    if (self) {
        _ramp = ramp;
    }
    return self;
}

@end


@interface DPHSVFilter()
@property (nonatomic, strong)   DPTextureRef      hueWeights;

@property (nonatomic, strong)   id<MTLBuffer>    adjustmentUniform;
@end

@implementation DPHSVFilter
{
    DPFunction     *kernel_filter;
    DPTextureRef    hueWeightsUniforms[6];
}

+ (const NSArray*) circle{
    
    static NSMutableArray *_circle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _circle = [NSMutableArray new];
        
        [_circle addObject:[DPHueRamp newWithRamp:(DPVector4){315.0, 345.0, 15.0,   45.0}]]; // reds
        [_circle addObject:[DPHueRamp newWithRamp:(DPVector4){ 15.0,  45.0, 75.0,  105.0}]]; // yellows
        [_circle addObject:[DPHueRamp newWithRamp:(DPVector4){ 75.0, 105.0, 135.0, 165.0}]]; // greens
        [_circle addObject:[DPHueRamp newWithRamp:(DPVector4){135.0, 165.0, 195.0, 225.0}]]; // cyans
        [_circle addObject:[DPHueRamp newWithRamp:(DPVector4){195.0, 225.0, 255.0, 285.0}]]; // blues
        [_circle addObject:[DPHueRamp newWithRamp:(DPVector4){255.0, 285.0, 315.0, 345.0}]]; // magentas
    });
    
    return _circle;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {
        
        [self addFunction: kernel_filter = [DPFunction newFunction:@"kernel_adjustHSV" context:self.context]];
        self.adjustment = (DPHSVAdjustment){
            (DPVector4){0.0f, 0.0f, 0.0f, 0.0f}, // reds
            (DPVector4){0.0f, 0.0f, 0.0f, 0.0f}, // yellows
            (DPVector4){0.0f, 0.0f, 0.0f, 0.0f}, // greens
            (DPVector4){0.0f, 0.0f, 0.0f, 0.0f}, // cyans
            (DPVector4){0.0f, 0.0f, 0.0f, 0.0f}, // blues
            (DPVector4){0.0f, 0.0f, 0.0f, 0.0f}, // magentas
            (DPBlending){DP_BLENDING_NORMAL, 1.0f}
        };
    }
    
    return self;
}

- (void) setAdjustment:(DPHSVAdjustment)adjustment{
    _adjustment = adjustment;
    if (!_adjustmentUniform) {
        _adjustmentUniform  = [self.context.device newBufferWithLength:sizeof(_adjustment) options:MTLResourceOptionCPUCacheModeDefault];
    }
    memcpy([_adjustmentUniform contents], &_adjustment, sizeof(_adjustment));
    self.dirty = YES;
}

- (void) configureWeightsAtIndex:(NSUInteger)index uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    [commandEncoder setTexture:self.hueWeights atIndex:index];
}

- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    
    if (function == kernel_filter) {
        [commandEncoder setBuffer:_adjustmentUniform offset:0 atIndex:0];
        [self configureWeightsAtIndex:2 uniform:commandEncoder];
    }
}

static NSNumber *hue_normal_distribution(float x, float mu, float sigma, DPVector4 ramp){
    return [DPMathDistribution gaussYPointAtX:@(x) withFi:@1.0 withMu:@(mu) withSigma:@(sigma)];
}


static float hue_normal_weight(float x, DPVector4 ramp){
    
    float sigma= (ramp.z-ramp.y);
    float mu   = (ramp.w+ramp.x)/2.0f;
    
    if (ramp.y>ramp.z) {
        sigma = (360.0f-ramp.y+ramp.z);
        if (x>=0 && x<=360.0/2.0) {
            mu    = (360.0f-ramp.y-ramp.z)/2.0f;
        }else{
            mu    = (ramp.y+ramp.z);
        }
    }
    
    return [hue_normal_distribution(x, mu, sigma, ramp) floatValue];
}

+ (DPTextureRef) defaultHueWeightsWithContext:(DPContext *)context{
    DPTextureRef hueWeights;
    NSUInteger width  = 360;
    NSUInteger height = 6;
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Float
                                                                                                 width:width
                                                                                                height:height
                                                                                             mipmapped:NO];
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    
    float weights[width*height];
    hueWeights = [context.device newTextureWithDescriptor:textureDescriptor];
    
    NSUInteger gid=0;
    
    for (NSUInteger sectorIndex = 0; sectorIndex<height; sectorIndex++) {
        DPHueRamp *sector = [DPHSVFilter circle][sectorIndex];
        for (NSUInteger i=0; i<width; i++) {
            weights[gid++] = hue_normal_weight((float) i, sector.ramp);
        }
    }
    
    [hueWeights replaceRegion:region mipmapLevel:0 withBytes:weights bytesPerRow:sizeof(float) * width];
    return hueWeights;
}


- (DPTextureRef) hueWeights{
    if (!_hueWeights) {
        _hueWeights = [DPHSVFilter defaultHueWeightsWithContext:self.context];
    }
    return _hueWeights;
}

@end
