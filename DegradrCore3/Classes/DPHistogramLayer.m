//
//  DPHistogramLayer.m
//  DegradrCore3
//
//  Created by denn on 03.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramLayer.h"
#import "DPConstants.h"
#import <Accelerate/Accelerate.h>

typedef struct{
    float reds  [256];
    float greens[256];
    float blues [256];
    float lumas [256];
    float max_component;
    DPVector4 reds_color;
    DPVector4 greens_color;
    DPVector4 blues_color;
    DPVector4 lumas_color;
    float x;
    float y;
    float width;
    float height;
}DPHistogramComponents;

@interface DPHistogramLayer()
@property (nonatomic,assign) DPHistogramComponents components;
@property (nonatomic, strong)   id<MTLBuffer>    componentsUniform;
@end

@implementation DPHistogramLayer
{
    DPFunction *kernel_filter;
}

@synthesize histogramAnalizer=_histogramAnalizer;

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithVertex:DP_VERTEX_DEF_FUNCTION withFragment:DP_FRAGMENT_DEF_FUNCTION context:aContext];
    
    if (self) {
                
        [self addFunction: kernel_filter = [DPFunction newFunction:@"kernel_histogramLayer" context:self.context]];
        
        float reds[256];
        float greens[256];
        float blues[256];
        float lumas[256];
        
        _components.max_component = MAXFLOAT;
        
        _settings.colors.reds   = (DPVector4){1.0f, 0.1f, 0.1f, 0.5f};
        _settings.colors.greens = (DPVector4){0.1f, 1.0f, 0.1f, 0.5f};
        _settings.colors.blues  = (DPVector4){0.1f, 0.1f, 1.0f, 0.5f};
        _settings.colors.lumas  = (DPVector4){1.0f, 1.0f, 1.0f, 0.5f};
        _settings.position = CGPointMake(0.0f, 0.0f);
        _settings.size = CGSizeMake(1.0f, 0.5f);
        
        self.settings = _settings;
        
        [self updateReds:reds greens:greens blues:blues lumas:lumas];
    }   
    
    return self;
}

- (void) setSettings:(DPHistogramLayerSettings)settings{

    _settings = settings;
    _components.reds_color = _settings.colors.reds;
    _components.greens_color = _settings.colors.greens;
    _components.blues_color = _settings.colors.blues;
    _components.lumas_color = _settings.colors.lumas;
    _components.x = _settings.position.x;
    _components.y = _settings.position.y;
    _components.width = _settings.size.width;
    _components.height = _settings.size.height;
    
    self.dirty = YES;

}

- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    
    if (function == kernel_filter) {
        [commandEncoder setBuffer:_componentsUniform offset:0 atIndex:0];
    }
}

- (void) updateSolverWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{
    float *reds   = histogram[0];
    float *greens = histogram[1];
    float *blues  = histogram[2];
    float *lumas  = histogram[3];
    [self updateReds:reds greens:greens blues:blues lumas:lumas];
    
    if (self.histogramAnalizer && self.histogramAnalizer.histogramSolverUpdatedBlock) {
        self.histogramAnalizer.histogramSolverUpdatedBlock(self, histogram, imageSize, count);
    }
}

- (void) updateReds:(const float *)reds greens:(const float *)greens blues:(const float *)blues lumas:(const float *)lumas{

    if (!_componentsUniform) {
        _componentsUniform  = [self.context.device newBufferWithLength:sizeof(_components) options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    memcpy(_components.reds, reds, sizeof(_components.reds));
    memcpy(_components.greens, greens, sizeof(_components.greens));
    memcpy(_components.blues, blues, sizeof(_components.blues));
    memcpy(_components.lumas, lumas, sizeof(_components.lumas));
    
    float red_max; 
    vDSP_maxv(&reds[1], 1, &red_max, 254);
    
    float green_max;
    vDSP_maxv(&greens[1], 1, &green_max, 254);
    
    float blue_max;
    vDSP_maxv(&blues[1], 1, &blue_max, 254);
    
    float luma_max;
    vDSP_maxv(&lumas[1], 1, &luma_max, 254);
    
    _components.max_component = fmaxf(luma_max, fmax(red_max, fmax(green_max, blue_max)));
        
    memcpy([_componentsUniform contents], &_components, sizeof(_components));
    self.dirty = YES;

}

@end
