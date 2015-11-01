//
//  DPMetal_samplers.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 09/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//
//  Acknowledgement:
//  http://www.codeproject.com/Articles/236394/Bi-Cubic-and-Bi-Linear-Interpolation-with-GLSL
//

#ifndef __DPMETAL_SAMPLERS
#define __DPMETAL_SAMPLERS

#include "DPMetal_types.h"
#include "DPMetal_stdlib.h"

using namespace metal;
using namespace dpmetal;

DPMETAL_NAMESPACE_BEGIN


/**
 *  Classic biLinear sampler
 *
 */
kernel void kernel_biLinear22Sampler(texture2d<float, access::sample> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);

    float  texelWidth = 1.0/inTexture.get_width();
    float  texelHeight = 1.0/inTexture.get_height();
    
    float2 inputCoord = float2(gid) * float2(1.0/outTexture.get_width(), 1.0/outTexture.get_height()); // normalized coords
    
    float4 s1 = inTexture.sample(s, inputCoord);
    float4 s2 = inTexture.sample(s, inputCoord + float2(texelWidth, 0         ));
    float4 s3 = inTexture.sample(s, inputCoord + float2(0,          texelHeight));
    float4 s4 = inTexture.sample(s, inputCoord + float2(texelWidth, texelHeight));
    
    float a = fract( inputCoord.x * outTexture.get_width() );
    float b = fract( inputCoord.y * outTexture.get_height());
    
    float4 q0 = mix( s1, s2, a );
    float4 q1 = mix( s3, s4, a );
    
    outTexture.write(mix( q0, q1, b ), gid);
}

/**
 *  Classic bicubic sampler
 *
 */
kernel void kernel_biLinear33Sampler(texture2d<float, access::sample> inTexture [[texture(0)]],
                                     texture2d<float, access::write> outTexture [[texture(1)]],
                                     uint2 gid [[thread_position_in_grid]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::pixel);

    float2 inputCoord = float2(gid) * float2(1.0/outTexture.get_width(), 1.0/outTexture.get_height()); // normalized coords
    
    float2 size(inTexture.get_width(),inTexture.get_height());
    float2 coords = inputCoord * size;
    
    float4 xy;
    xy  = inTexture.sample(s, coords + float2(-1,-1));
    xy += inTexture.sample(s, coords + float2( 0,-1));
    xy += inTexture.sample(s, coords + float2( 1,-1));
    xy += inTexture.sample(s, coords + float2(-1, 0));
    xy += inTexture.sample(s, coords + float2( 0, 0));
    xy += inTexture.sample(s, coords + float2( 1, 0));
    xy += inTexture.sample(s, coords + float2(-1, 1));
    xy += inTexture.sample(s, coords + float2( 0, 1));
    xy += inTexture.sample(s, coords + float2( 1, 1));
    
    constexpr float w = 1.0/9.0;
    
    outTexture.write(xy * w, gid);
}


/**
 * Resample filtering
 */
kernel void kernel_resamplerFilter(texture2d<float, access::sample> inTexture [[texture(0)]],
                                 texture2d<float, access::write>   outTexture [[texture(1)]],
                                 texture2d<float, access::read> sampleWeights [[texture(2)]],
                                 uint2 gid [[thread_position_in_grid]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::pixel);

    float4 nSum  ( 0.0, 0.0, 0.0, 0.0 );
    float4 nDenom( 0.0, 0.0, 0.0, 0.0 );
    
    float2 texelSize(inTexture.get_width(),inTexture.get_height());
    
    float2 inputCoord = float2(gid) * float2(1.0/outTexture.get_width(), 1.0/outTexture.get_height()); // normalized coords
    float2 coords     = inputCoord * texelSize;
    
    int width = sampleWeights.get_width();
    int size  = (width+1)/2 - width%2 ;
    
    for( int m = -size; m <=size; m++ )
    {
        for( int n = -size; n<=size; n++)
        {
            float4 rgba = inTexture.sample(s, coords + float2(m,n));
            
            float4 fx = sampleWeights.read(uint2(m+size, 0)).rrrr;
            float4 fy = sampleWeights.read(uint2(n+size, 0)).rrrr;
            
            nSum = nSum + ( rgba * fx * fy  );
            nDenom = nDenom + ( fx * fy );
        }
    }
    
    outTexture.write(nSum/nDenom, gid);
}

/**
 *  Convolution
 *
 */
kernel void kernel_convolution(texture2d<float, access::read>  inTexture [[texture(0)]],
                                texture2d<float, access::write> outTexture [[texture(1)]],
                                texture2d<float, access::read>  weights [[texture(2)]],
                                uint2 gid [[thread_position_in_grid]])
{
    int size = weights.get_width();
    int radius = size / 2;
    
    float4 accumColor(0, 0, 0, 0);
    
    for (int j = 0; j < size; ++j)
    {
        for (int i = 0; i < size; ++i)
        {
            uint2 kernelIndex  = uint2(i, j);
            uint2 textureIndex = uint2(gid.x + (i - radius), gid.y + (j - radius));
            
            accumColor += float4(weights.read(kernelIndex).rrrr * inTexture.read(textureIndex).rgba);
        }
    }
    
    outTexture.write(float4(accumColor.rgb, 1.0), gid);
}

kernel void kernel_unsharpMask(texture2d<float, access::read>  blurredTexture  [[texture(0)]],
                               texture2d<float, access::write> outTexture      [[texture(1)]],
                               texture2d<float, access::read>  inTexture       [[texture(2)]],
                               constant float  &intensity [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    float4 blurColor = blurredTexture.read(gid);
    
    float4 mask   = float4((inColor.rgb - blurColor.rgb) * intensity, inColor.a);
    float4 result = inColor + mask;
    
    outTexture.write(result, gid);
}


kernel void kernel_softUnsharpMask(texture2d<float, access::read>  blurredTexture  [[texture(0)]],
                               texture2d<float, access::write> outTexture      [[texture(1)]],
                               texture2d<float, access::read>  inTexture       [[texture(2)]],
                               constant DPSoftUnsharpMaskIntensityIn  &intensity [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    float4 blurColor = blurredTexture.read(gid);
    
    float4 mask   = float4((inColor.rgb - blurColor.rgb) * 1.0, inColor.a);
    float4 result = inColor + mask;
    
    float4 lighten = blendLighten(inColor, result);
    float4 darken  = blendDarken (inColor, result);
    
    darken = blendNormal(inColor, float4(darken.rgb,  intensity.dark));    
    
    result = blendNormal(darken, float4(lighten.rgb, intensity.light));
    
    if (intensity.blending.mode == 0)
        outTexture.write(blendLuminosity(inColor, float4(result.rgb, intensity.blending.opacity)), gid);  
    else
        outTexture.write(blendNormal(inColor, float4(result.rgb, intensity.blending.opacity)), gid);  
}


DPMETAL_NAMESPACE_END

#endif /* __DPMETAL_SAMPLERS */