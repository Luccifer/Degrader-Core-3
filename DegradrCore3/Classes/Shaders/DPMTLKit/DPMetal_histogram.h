//
//  DPMetal_histogram.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 03/08/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#ifndef __DPMETAL_HISTOGRAM
#define __DPMETAL_HISTOGRAM

#include "DPMetal_types.h"
#include "DPMetal_structures.h"
#include "DPMetal_stdlib.h"

DPMETAL_NAMESPACE_BEGIN

typedef struct {
    float top;   float right;
    float left;  float bottom;
} DPCropRegionIn;


METAL_FUNC  float coordsIsInsideBox(float2 v, float2 bottomLeft, float2 topRight) {
    float2 s =  step(bottomLeft, v) - step(topRight, v);
    return s.x * s.y;
}

METAL_FUNC float4 histogramSampledColor(
                                         texture2d<float, access::sample>  inTexture,
                                         texture2d<float, access::write>   outTexture,
                                         constant DPCropRegionIn          &regionIn,
                                         uint2 gid){
    float2 coords  = float2(gid) * float2(1.0/outTexture.get_width(),1.0/outTexture.get_height());
    float  isBoxed = coordsIsInsideBox(coords, float2(regionIn.left,regionIn.bottom), float2(1.0-regionIn.right,1.0-regionIn.top));
    return sampledColor(inTexture,outTexture,gid) * isBoxed;
}

//
// accumulate bins in out MTLBuffer
//
kernel void kernel_histogram(texture2d<float, access::sample>  inTexture  [[texture(0)]],
                             texture2d<float, access::write>   outTexture [[texture(1)]],
                             device   DPHistogramBufferIn &out [[ buffer(0) ]],
                             constant DPCropRegionIn &regionIn [[ buffer(1) ]],
                             uint2 gid [[thread_position_in_grid]]
                             )
{
    float4 inColor = histogramSampledColor(inTexture,outTexture,regionIn,gid);

    float  luma      = dot(inColor.rgb,luma_factor) * inColor.a;
    
    if (inColor.a>0.0 && luma>0.0){
        atomic_fetch_add_explicit(&out.reds  [uint(inColor.rgb.r*255.0)], 1, memory_order_relaxed);
        atomic_fetch_add_explicit(&out.greens[uint(inColor.rgb.g*255.0)], 1, memory_order_relaxed);
        atomic_fetch_add_explicit(&out.blues [uint(inColor.rgb.b*255.0)], 1, memory_order_relaxed);
        atomic_fetch_add_explicit(&out.lumas [uint(luma*255.0)],      1, memory_order_relaxed);
    }
    
    atomic_fetch_add_explicit(&out.count, 1, memory_order_relaxed);
    
    //
    // convert to texture reader for vDSP functions
    //
    inColor.rgb = float3(inColor.rgb.b, inColor.rgb.g, inColor.rgb.r);
    outTexture.write(float4(inColor.rgb * inColor.a,luma), gid);
}

METAL_FUNC int weight_ramp(float4 ramp, float hue){
    
    constexpr int _30_degrees = int(255.0/30.0);

    int weight      = _30_degrees;

    if      (ramp.x<=hue && hue<=ramp.y) {
        weight = (hue-ramp.x)*_30_degrees;
    }
    else if (ramp.z<=hue && hue<=ramp.w){
        weight = (ramp.w-hue)*_30_degrees;
    }
    
    return weight;
}

METAL_FUNC void circle_bin_position(float3 hsv, device DPHistogramBufferIn &out){
    float  hue =  hsv.x * 360.0;

    //
    // Change REDS
    //
    if ((hue>=reds.x && hue<=360.0) || (hue>=0.0 && hue<=reds.w))
        atomic_fetch_add_explicit(&out.lumas  [0], weight_ramp(reds, hue), memory_order_relaxed);
    
    //
    // Change YELLOWS
    //
    if (hue>=yellows.x && hue<=yellows.w)
        atomic_fetch_add_explicit(&out.lumas  [1], weight_ramp(yellows, hue), memory_order_relaxed);
    
    //
    // Change GREENS
    //
    if (hue>=greens.x && hue<=greens.w)
        atomic_fetch_add_explicit(&out.lumas  [2], weight_ramp(greens, hue), memory_order_relaxed);

    //
    // Change CYANS
    //
    if (hue>=cyans.x && hue<=cyans.w)
        atomic_fetch_add_explicit(&out.lumas  [3], weight_ramp(cyans, hue), memory_order_relaxed);
    
    //
    // Change BLUES
    //
    if (hue>=blues.x && hue<=blues.w)
        atomic_fetch_add_explicit(&out.lumas  [4], weight_ramp(blues, hue), memory_order_relaxed);
    
    //
    // Change MAGENTAS
    //
    if (hue>=magentas.x && hue<=magentas.w)
        atomic_fetch_add_explicit(&out.lumas  [5], weight_ramp(magentas, hue), memory_order_relaxed);

}

//
// Compute gray weights
//
kernel void kernel_neutralWeights(texture2d<float, access::sample>  inTexture  [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              device DPHistogramBufferIn &out            [[ buffer(0) ]],
                              constant DPCropRegionIn    &regionIn       [[ buffer(1) ]],
                              constant DPGrayClippingIn  &clipping       [[ buffer(2) ]],
                              uint2 gid [[thread_position_in_grid]])
{    
    float4 inColor = histogramSampledColor(inTexture,outTexture,regionIn,gid);

    float3 color     = inColor.rgb;
    
    float alpha = 0.0;
    
    if (inColor.a>0.0){
        float3 hsv = rgb_2_HSV(color);
        
        circle_bin_position(hsv,out);
        
        if (hsv.y <= clipping.saturation){
            
            alpha = 1.0;
            
            if (hsv.z <= clipping.black) {
                alpha = 0.0;
                //
                // Out of range
                //
                atomic_fetch_add_explicit(&out.lumas  [253], 1, memory_order_relaxed);
            }
            else if (hsv.z >= (1.0-clipping.white)) {
                alpha = 0.0;
                //
                // Out of range
                //
                atomic_fetch_add_explicit(&out.lumas  [254], 1, memory_order_relaxed);
            }
            else{
                //
                // GRAYS
                //
                atomic_fetch_add_explicit(&out.lumas  [255], 1, memory_order_relaxed);
            }
        }
        else{
            //
            // COLORED
            //
            atomic_fetch_add_explicit(&out.lumas  [252], 1, memory_order_relaxed);
        }
        
        atomic_fetch_add_explicit(&out.reds  [uint(inColor.r*255.0)], 1, memory_order_relaxed);
        atomic_fetch_add_explicit(&out.greens[uint(inColor.g*255.0)], 1, memory_order_relaxed);
        atomic_fetch_add_explicit(&out.blues [uint(inColor.b*255.0)], 1, memory_order_relaxed);
        
    }
    // count
    atomic_fetch_add_explicit(&out.count, 1, memory_order_relaxed);
    outTexture.write(float4(color, alpha), gid);
}

DPMETAL_NAMESPACE_END

#endif /* DPMETAL_NAMESPACE_END */