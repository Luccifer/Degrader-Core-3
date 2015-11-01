//
//  DPСonvolveFilter.m
//  DegradrCore3
//
//  Created by denn on 10.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPConvolveFilter.h"
#import "DPConstants.h"

@interface DPConvolveFilter()
@end

@implementation DPConvolveFilter
{
    DPFunction *kernel_filter_passFirst;
    DPFunction *kernel_filter_passSecond;
}

- (instancetype) initWithContext:(DPContext *)aContext{    
    self = [super initWithContext:aContext];
    if (self) {
        _scale = 1.0;
        self.weights = [@[ 
                     @0,@0,@0,
                     @0,@1,@0,
                     @0,@0,@0
                     ] mutableCopy];
    }
    
    return self;
}

- (void)setWeights:(NSMutableArray *)weights{
    self.dirty = YES;

    _weights = [weights mutableCopy];
    [_weights removeObjectsInRange:(NSRange){_weights.count/2+1,_weights.count-_weights.count/2-1}];
    _weights = [[[_weights reverseObjectEnumerator] allObjects] mutableCopy];
    [self rebuildSources];
}

- (void) rebuildSources{
    NSString *shaderFunction = @"\n\
    \n\
    #include <metal_stdlib>\n\
    using namespace metal;\n\
    \n\
    kernel void kernel_convolve%@(texture2d<float, access::sample> inTexture [[texture(0)]],\n\
    texture2d<float, access::write> outTexture [[texture(1)]],\n\
    uint2 gid [[thread_position_in_grid]])\n\
    {\n\
    \n\
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);\n\
    float2 texelSize(1.0/outTexture.get_width(), 1.0/outTexture.get_height());\n\
    float4 accumColor(0, 0, 0, 0);\n\
    \n\
    %@\n\
    \n\
    outTexture.write(float4(accumColor.rgb, 1.0), gid);\n\
    }\n";    
        
    
    NSMutableString *shaderLines = [NSMutableString new];
    
    [shaderLines appendFormat:@" accumColor += inTexture.sample(s, float2(gid) * texelSize).rgba * float4(%@).rrrr;\n", _weights[0]];
    
    for (NSUInteger i=1; i<_weights.count; i++) {
        NSString *gid1 = [NSString stringWithFormat:@"(gid + uint2(uint(%lu), 0))", (unsigned long)round(i*self.scale)];
        NSString *gid2 = [NSString stringWithFormat:@"(gid - uint2(uint(%lu), 0))", (unsigned long)round(i*self.scale)];

        [shaderLines appendFormat:@" accumColor += inTexture.sample(s, float2(%@) * texelSize).rgba * float4(%@).rrrr;\n", gid1, _weights[i]];
        [shaderLines appendFormat:@" accumColor += inTexture.sample(s, float2(%@) * texelSize).rgba * float4(%@).rrrr;\n", gid2, _weights[i]];
    }
    
    NSString *firstPassShader = [NSString stringWithFormat:shaderFunction ,@"FirstPass", shaderLines];
    
    shaderLines = [NSMutableString new];
    
    [shaderLines appendFormat:@" accumColor += inTexture.sample(s, float2(gid) * texelSize).rgba * float4(%@).rrrr;\n", _weights[0]];
    
    for (NSUInteger i=1; i<_weights.count; i++) {
        NSString *gid1 = [NSString stringWithFormat:@"(gid + uint2(0, uint(%lu)))", (unsigned long)round(i*self.scale)];
        NSString *gid2 = [NSString stringWithFormat:@"(gid - uint2(0, uint(%lu)))", (unsigned long)round(i*self.scale)];
        [shaderLines appendFormat:@" accumColor += inTexture.sample(s, float2(%@) * texelSize).rgba * float4(%@).rrrr;\n", gid1, _weights[i]];
        [shaderLines appendFormat:@" accumColor += inTexture.sample(s, float2(%@) * texelSize).rgba * float4(%@).rrrr;\n", gid2, _weights[i]];
    }
    
    NSString *secondPassShader = [NSString stringWithFormat:shaderFunction, @"SecondPass", shaderLines];    
    
    [self removeFunction:kernel_filter_passFirst];
    [self removeFunction:kernel_filter_passSecond];
    [self addFunction: kernel_filter_passFirst =[DPFunction newFunction:@"kernel_convolveFirstPass" withLibrarySource:firstPassShader context:self.context]];
    [self addFunction: kernel_filter_passSecond=[DPFunction newFunction:@"kernel_convolveSecondPass" withLibrarySource:secondPassShader context:self.context]];
}

- (void) setTransform:(DPTransform *)transform{
    [super setTransform:transform];
    [self rebuildSources];
}

- (void) setScale:(float)scale{
    self.dirty = YES;

    _scale = scale<=0?1.0:scale;
    [self rebuildSources];
}
@end
