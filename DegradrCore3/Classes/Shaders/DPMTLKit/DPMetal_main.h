//
//  File.metal
//  DegradrCore3
//
//  Created by denis svinarchuk on 10/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//
//
//
//  Acknowledgement:
//  http://www.sunsetlakesoftware.com/ - the famous great work for Image Processing with GPU 
//  A lot of ideas were taken from the Brad Larson project: https://github.com/BradLarson/GPUImage
//
//
//

#ifndef __DPMETAL_MAIN
#define __DPMETAL_MAIN

#include <metal_stdlib>
#include <simd/simd.h>
#include "DPMetal_stdlib.h"
#include "DPMetal_adjustment.h"
#include "DPMetal_samplers.h"
#include "DPMetal_histogram.h"
#include "DPMetal_layers.h"

using namespace metal;
using namespace dpmetal;

/**
 *  Pass through vertex
 *
 */
vertex VertexOut vertex_passthrough(
                                    device VertexIn*    verticies   [[ buffer(0) ]],
                                    device Transform&   transform   [[ buffer(1) ]],
                                    device OrthoMatrix& orthoMatrix [[ buffer(2) ]],
                                    unsigned int        vid         [[ vertex_id ]]
                                    ) {
    VertexOut out;
    
    device float         *m = transform.transform;
    
    float3x3 tranformMatrix = float3x3(
                                       float3( m[0], m[1], m[2]),
                                       float3( m[3], m[4], m[5]),
                                       float3( m[6], m[7], m[8])
                                       );
    
    device VertexIn& v = verticies[vid];
    
    float3 position = tranformMatrix * float3(float2(v.position) , 0.0);
    
    out.position = (float4(position, 1.0) * orthoMatrix.matrix) * transform.transition;
    
    out.texcoord = float2(v.texcoord);
    
    return out;
}

/**
 * View rendering vertex
 */
vertex VertexOut vertex_passview(
                                 device VertexIn*    verticies [[ buffer(0) ]],
                                 unsigned int        vid       [[ vertex_id ]]
                                 ) {
    VertexOut out;
    
    device VertexIn& v = verticies[vid];
    
    float3 position = float3(float2(v.position) , 0.0);
    
    out.position = float4(position, 1.0);
    
    out.texcoord = float2(v.texcoord);
    
    return out;
}


/**
 *  Pass through fragment
 *
 */
fragment half4 fragment_passthrough(
                                    VertexOut in [[ stage_in ]],
                                    texture2d<float, access::sample> texture [[ texture(0) ]]
                                    ) {
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    float3 rgb = texture.sample(s, in.texcoord).rgb;
    return half4(half3(rgb), 1.0);
}


/**
 * Base adjust kernel functions
 */

kernel void kernel_adjustExposure(
                                  texture2d<float, access::sample> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  constant DPExposureAdjustmentIn &adjustment [[buffer(0)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    outTexture.write(adjustExposure(inColor,adjustment),gid);
}


kernel void kernel_adjustBrightness(
                                    texture2d<float, access::sample> inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    constant DPBrightnessAdjustmentIn &adjustment [[buffer(0)]],
                                    uint2 gid [[thread_position_in_grid]]) {
    
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    outTexture.write(adjustBrightness(inColor,adjustment),gid);
}


kernel void kernel_adjustAwb(
                             texture2d<float, access::sample> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             constant DPAWBAdjustmentIn &adjustment [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    outTexture.write(adjustAwb(inColor,adjustment),gid);
}

kernel void kernel_adjustLevels(
                                texture2d<float, access::sample> inTexture [[texture(0)]],
                                texture2d<float, access::write> outTexture [[texture(1)]],
                                constant DPLevelsAdjustmentIn &adjustment [[buffer(0)]],
                                uint2 gid [[thread_position_in_grid]]) {
    
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    outTexture.write(adjustLevels(inColor,adjustment), gid);
}

kernel void kernel_adjustSaturation(texture2d<float, access::sample> inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    constant float &saturation [[buffer(0)]],
                                    uint2 gid [[thread_position_in_grid]]
                                    )
{
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    
    float  value     = lum(inColor.rgb);
    
    float4 grayColor = float4(value, value, value, 1.0);
    
    float4 outColor  = mix(grayColor, inColor, saturation);
    
    outTexture.write(outColor, gid);
}


kernel void kernel_adjustCurve(texture2d<float, access::sample>  inTexture  [[texture(0)]],
                               texture2d<float, access::write>  outTexture  [[texture(1)]],
                               texture2d<float, access::sample> curveTexure [[texture(2)]],
                               constant DPCurveAdjustIn &adjustment  [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    outTexture.write(adjustCurve(inColor,curveTexure,adjustment),gid);
}


/**
 * Common functions
 */
kernel void kernel_invert(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    
    float4 outColor  = float4(1.0 - inColor.rgb.r, 1.0 - inColor.rgb.g, 1.0 - inColor.rgb.b, 1.0);
    
    outTexture.write(outColor, gid);
}

kernel void kernel_passthrough(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    outTexture.write(inColor, gid);
}

kernel void kernel_adjustHSV(texture2d<float, access::sample>  inTexture       [[texture(0)]],
                             texture2d<float, access::write>   outTexture      [[texture(1)]],
                             texture2d<float, access::sample>  hueWeights      [[texture(2)]],
                             constant DPHSVAdjustIn           &adjustment      [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]){
    
    
    float4 input_color   = inTexture.read(gid);
    float4 result = adjustHSV(input_color, hueWeights, adjustment);
    
    outTexture.write(result, gid);
}


#endif

