//
//  DPUnsharpMaskFilter.m
//  DegradrCore3
//
//  Created by denn on 11.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPUnsharpMaskFilter.h"
#import "DPGaussianBlur.h"


@interface __internal_DPSharpFilter : DPFilter

@property (nonatomic,assign) float          intensity;
@property (nonatomic,strong) id<MTLBuffer>  intensityUniform;
@property (nonatomic,strong) DPTextureRef   sharpTexture;
@end

@implementation __internal_DPSharpFilter
{
    DPFunction     *kernel_filter;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {
        self.intensity =1.0f;
        [self addFunction: kernel_filter = [DPFunction newFunction:@"kernel_unsharpMask" context:self.context]];
    }
    
    return self;
}

- (void) setIntensity:(float)intensity{
    _intensity=intensity;
    if (!_intensityUniform) {
        _intensityUniform  = [self.context.device newBufferWithLength:sizeof(_intensity) options:MTLResourceOptionCPUCacheModeDefault];
    }
    memcpy([_intensityUniform contents], &_intensity, sizeof(_intensity));
    self.dirty = YES;
}


- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    if (function == kernel_filter) {                
        [commandEncoder setTexture:self.sharpTexture atIndex:2];
        [commandEncoder setBuffer:self.intensityUniform offset:0 atIndex:0];
    }
}


@end


@interface __internal_DPSoftSharpFilter : DPFilter

@property (nonatomic,assign) DPSoftUnsharpMaskIntensity    intensity;
@property (nonatomic,strong) id<MTLBuffer>  intensityUniform;
@property (nonatomic,strong) DPTextureRef   sharpTexture;
@end

@implementation __internal_DPSoftSharpFilter
{
    DPFunction     *kernel_filter;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {
        self.intensity = (DPSoftUnsharpMaskIntensity){1.0f,1.0f, (DPBlending){DP_BLENDING_NORMAL, 1.0f}};
        [self addFunction: kernel_filter = [DPFunction newFunction:@"kernel_softUnsharpMask" context:self.context]];
    }
    
    return self;
}

- (void) setIntensity:(DPSoftUnsharpMaskIntensity)intensity{
    _intensity=intensity;
    if (!_intensityUniform) {
        _intensityUniform  = [self.context.device newBufferWithLength:sizeof(_intensity) options:MTLResourceOptionCPUCacheModeDefault];
    }
    memcpy([_intensityUniform contents], &_intensity, sizeof(_intensity));
}


- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    if (function == kernel_filter) {                
        [commandEncoder setTexture:self.sharpTexture atIndex:2];
        [commandEncoder setBuffer:self.intensityUniform offset:0 atIndex:0];
    }
}


@end


@interface DPUnsharpMaskFilter()
@property (nonatomic, strong)    __internal_DPSharpFilter *sharpFilter;
@end

@implementation DPUnsharpMaskFilter
{
    DPFunction               *kernel_filter;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {        
        self.radius    = 8.0f;
        [self addFilter:self.sharpFilter];
    }
    
    return self;
}

- (__internal_DPSharpFilter*) sharpFilter{
    if (!_sharpFilter) {
        _sharpFilter = [__internal_DPSharpFilter newWithContext:self.context];                
    }
    return _sharpFilter;
}

- (void) setSource:(DPImageProvider *)source{
    [super setSource:source];
    self.sharpFilter.sharpTexture=self.source.texture;
}

- (void) setIntensity:(float)intensity{
    self.sharpFilter.intensity = intensity;
}

- (float) intensity{
    return self.sharpFilter.intensity;
}

@end


@interface DPSoftUnsharpMaskFilter()
@property (nonatomic, strong)    __internal_DPSoftSharpFilter *sharpFilter;
@end

@implementation DPSoftUnsharpMaskFilter
{
    DPFunction               *kernel_filter;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {        
        self.radius    = 8.0f;
        [self addFilter:self.sharpFilter];
    }
    
    return self;
}

- (__internal_DPSoftSharpFilter*) sharpFilter{
    if (!_sharpFilter) {
        _sharpFilter = [__internal_DPSoftSharpFilter newWithContext:self.context];                
    }
    return _sharpFilter;
}

- (void) setSource:(DPImageProvider *)source{
    [super setSource:source];
    self.sharpFilter.sharpTexture=self.source.texture;
}

- (void) setIntensity:(DPSoftUnsharpMaskIntensity)intensity{
    self.sharpFilter.intensity = intensity;
    self.dirty = YES;
}

- (DPSoftUnsharpMaskIntensity) intensity{
    return self.sharpFilter.intensity;
}

@end
