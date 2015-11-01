//
//  DPMetal_adjustment.metal
//  DegradrCore3
//
//  Created by denis svinarchuk on 29/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//
//
//  Acknowledgement:
//  http://www.sunsetlakesoftware.com/ - the famous great work for Image Processing with GPU 
//  A lot of ideas were taken from the Brad Larson project: https://github.com/BradLarson/GPUImage
//

#ifndef __DPMETAL_ADJUSTMENT
#define __DPMETAL_ADJUSTMENT

#include "DPMetal_types.h"
#include "DPMetal_stdlib.h"

using namespace metal;
using namespace dpmetal;

DPMETAL_NAMESPACE_BEGIN


METAL_FUNC float4 adjustExposure(float4 inColor, constant DPExposureAdjustmentIn &adjustment){
    
    float4 result = float4(inColor.rgb * pow(2.0, adjustment.exposure), adjustment.blending.opacity);

    if (adjustment.blending.mode == 0) 
        result = blendLuminosity(inColor, result);    
    else // only two modes yet
        result = blendNormal(inColor, result);

    return result;
}

METAL_FUNC float4 adjustBrightness(float4 inColor, constant DPBrightnessAdjustmentIn &adjustment){
    
    float4 result = float4(inColor.rgb + float3(adjustment.brightness), adjustment.blending.opacity);
    
    if (adjustment.blending.mode == 0) 
        result = blendLuminosity(inColor, result);
    else // only two modes yet
        result = blendNormal(inColor, result);
    
    return result;
}

/**
 * Auto white balance adjustment
 * The main idea has taken from http://zhur74.livejournal.com/44023.html
 */

METAL_FUNC float4 adjustAwb(float4 inColor, constant DPAWBAdjustmentIn &adjustment) {
    
    
    float4 averageColor = float4(adjustment.averageColor);

    float4 invert_color = float4((1.0 - averageColor.rgb), 1.0);
        
    constexpr float4 grey128 = float4(0.5,    0.5, 0.5,      1.0);
    constexpr float4 grey130 = float4(0.5098, 0.5, 0.470588, 1.0);
    
    invert_color             = blendLuminosity(invert_color, grey128); // compensate brightness
    invert_color             = blendOverlay(invert_color, grey130);    // compensate blue
        
    //
    // write result
    //
    float4 awb = blendOverlay(inColor, invert_color);
    
    float4 result = float4(awb.rgb, adjustment.blending.opacity);
    
    if (adjustment.blending.mode == 0) 
        return blendLuminosity(inColor, result);    
    else
        return blendNormal(inColor, result);
}


//
// See: GPUImage SDK
//

/*
 ** Gamma correction
 ** Details: http://blog.mouaif.org/2009/01/22/photoshop-gamma-correction-shader/
 */

#define GammaCorrection(color, gamma)	pow(color, 1.0 / gamma)

/*
 ** Levels control (input (+gamma), output)
 ** Details: http://blog.mouaif.org/2009/01/28/levels-control-shader/
 */

template<typename T> METAL_FUNC vec<T, 3> LevelsControlInputRange(vec<T, 3> color, vec<T, 3> minInput, vec<T, 3> maxInput){
    return min(
               max(clamp(color - minInput, vec<T, 3>(0.0), vec<T, 3>(1.0)), vec<T, 3>(0.0)) / 
               clamp(maxInput - minInput, vec<T, 3>(0.0), vec<T, 3>(1.0)), vec<T, 3>(1.0));
}

template<typename T> METAL_FUNC vec<T, 3> LevelsControlInput(vec<T, 3> color, vec<T, 3> minInput, vec<T, 3> gamma, vec<T, 3> maxInput){
    return clamp(GammaCorrection(clamp(LevelsControlInputRange(color, minInput, maxInput), vec<T, 3>(0.0), vec<T, 3>(1.0)), gamma), vec<T, 3>(0.0), vec<T, 3>(1.0));
}

template<typename T> METAL_FUNC vec<T, 3> LevelsControlOutputRange(vec<T, 3> color, vec<T, 3> minOutput, vec<T, 3> maxOutput){
    return clamp( mix(minOutput, maxOutput, color), vec<T, 3>(0.0), vec<T, 3>(1.0));
}

template<typename T> METAL_FUNC vec<T, 3> LevelsControl(vec<T, 3> color, vec<T, 3> minInput, vec<T, 3> gamma, vec<T, 3> maxInput, vec<T, 3> minOutput, vec<T, 3> maxOutput){
    return clamp(LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput), vec<T,3>(0.0), vec<T,3>(1.0));
}

METAL_FUNC float4 adjustLevels(float4 inColor, constant DPLevelsAdjustmentIn &adjustment){
    
    float4 color = float4(LevelsControl(inColor.rgb,
                                        float4(adjustment.minimum).rgb,
                                        float4(adjustment.middle).rgb,
                                        float4(adjustment.maximum).rgb,
                                        float4(adjustment.minOutput).rgb,
                                        float4(adjustment.maxOutput).rgb), inColor.a);

    float4 result;
    
    if (adjustment.blending.mode == 0) {
        result = blendLuminosity(inColor, float4(color.rgb, adjustment.blending.opacity));
    }
    else {// only two modes yet
        result = blendNormal(inColor, float4(color.rgb, adjustment.blending.opacity));
    }
    
    return result;
}

/**
 *  Adjusting tone curve by curve texture
 *
 */

METAL_FUNC float4 adjustCurve(
                              float4 inColor,
                              texture2d<float, access::sample> curveTexure,
                              constant DPCurveAdjustIn &adjustment
                              )
{
    
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    
    half red   = curveTexure.sample(s, float2(inColor.r, 0.0)).r;
    half green = curveTexure.sample(s, float2(inColor.g, 0.0)).g;
    half blue  = curveTexure.sample(s, float2(inColor.b, 0.0)).b;
    
    float4 result = float4(red, green, blue, adjustment.blending.opacity);
    
    if (adjustment.blending.mode == 0)
        result = blendLuminosity(inColor, result);
    
    else // only two modes yet
        result = blendNormal(inColor, result);
    
    
    return result;
}



//
// See GPUImage SDK
//
METAL_FUNC float4 adjustHighlightsShadows(float4 source, constant DPHighlightsShadowsIn &adjustment)
{
    constexpr float3 luminanceWeighting = float3(0.3, 0.3, 0.3);
    float3 rgb = source.rgb;
    float luminance = dot(rgb, luminanceWeighting);
        
    float shadows          = float2(adjustment.shadows).x;
    float shadows_width    = float2(adjustment.shadows).y - 1.0;
    
    float highlights       = 1.0 - float2(adjustment.highlights).x;
    float highlights_width = float2(adjustment.highlights).y - 1.0;
    
    float shadow    = clamp((pow(luminance, float(1.0/(shadows+1.0))) + (shadows_width)*pow(luminance, float(2.0/(shadows+1.0)))) - luminance, float(0.0), float(1.0));
    float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-highlights)) + (highlights_width)*pow(1.0-luminance, 2.0/(2.0-highlights)))) - luminance, -1.0, 0.0);
    
    float3 result   = float3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((rgb - float3(0.0, 0.0, 0.0))/(luminance - 0.0));
    
    if (adjustment.blending.mode == 0)
        return blendLuminosity(source, float4(float3(result), adjustment.blending.opacity));
    else // only two modes yet
        return blendNormal    (source, float4(float3(result), adjustment.blending.opacity));
}

//
// HSL/V/B
//

METAL_FUNC float hue_normal_distribution(float x, float mu, float sigma, float denom, float4 ramp){
    float fi = 1.0;
    float mux = mix(mu, mu+1.0, clamp(sign(x*360.0-ramp.w*2.0),0.0,1.0));
    return clamp(gaus_distribution(x,fi,mux,sigma)/denom,0.0,1.0);
}


METAL_FUNC float hue_normal_weight(float x, float4 ramp){
    
    constexpr float te    = 1.0/360.0;
    constexpr float width = 1.0;

    float where = clamp(sign(ramp.w-ramp.x), 0.0, 1.0);
    
    float denom = te*width;
    float sigma = mix((ramp.y-360-ramp.z)*denom, (ramp.z-ramp.y)*denom, where);
    float mu    = mix((ramp.x-360.0+ramp.w)*0.5, (ramp.w+ramp.x)*0.5, where);
    
    return hue_normal_distribution(x*te, mu*te, sigma, 1, ramp);
}


METAL_FUNC float3 adjust_lightness_legacy(float3 hsv, float4 ramp, float hue, float4 levelOut)
{
    float v = levelOut.z * hue_normal_weight(hue,ramp) * hsv.y;
    hsv.z = mix (hsv.z * (1.0 + v), hsv.z + (v * (1.0 - hsv.z)), clamp(sign(v), 0.0, 1.0));
    return hsv;
}

METAL_FUNC float weightOf(float hue, texture2d<float, access::sample>  weights, uint index){
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::pixel);
    return weights.sample(s,float2(hue*360,index)).x;
}

METAL_FUNC float3 adjust_lightness(float3 hsv, float4 levelOut, float hue, texture2d<float, access::sample>  weights, uint index)
{
    float v = levelOut.z * hsv.y * weightOf(hue,weights, index);
    hsv.z = mix (hsv.z * (1.0 + v), hsv.z + (v * (1.0 - hsv.z)), clamp(sign(v), 0.0, 1.0));
    return hsv;
}


METAL_FUNC float3 adjust_saturation_legacy(float3 hsv, float4 ramp, float hue, float4 levelOut)
{
    float v = 1.0 + levelOut.y * hue_normal_weight(hue,ramp);
    hsv.y = clamp(hsv.y * v, 0.0, 1.0);
    return hsv;
}

METAL_FUNC float3 adjust_saturation(float3 hsv, float4 levelOut, float hue, texture2d<float, access::sample>  weights, uint index)
{
    float v = 1.0 + levelOut.y * weightOf(hue,weights,index);
    hsv.y = clamp(hsv.y * v, 0.0, 1.0);
    return hsv;
}

METAL_FUNC float3 adjust_hue_legacy(float3 hsv, float4 ramp, float hue, float4 levelOut){
    
    //
    // hue rotates with overlap ranages
    //
    hsv.x  = hsv.x + 0.5 * levelOut.x * hue_normal_weight(hue,ramp);
    return hsv;
}

METAL_FUNC float3 adjust_hue(float3 hsv, float4 levelOut, float hue, texture2d<float, access::sample>  weights, uint index){
    
    //
    // hue rotates with overlap ranages
    //
    hsv.x  = hsv.x + 0.5 * levelOut.x * weightOf(hue,weights,index);
    return hsv;
}

METAL_FUNC float4 adjustHSV(float4 input_color,
                            texture2d<float, access::sample>  hueWeights,
                            constant DPHSVAdjustIn           &adjust
                            ){

    float3 hsv = rgb_2_HSV(input_color.rgb);
    
    float  hue = hsv.x;
    //float  h   = hsv.x;
    
    float4 areds(adjust.reds);
    float4 ayellows(adjust.yellows);
    float4 agreens(adjust.greens);
    float4 acyans(adjust.cyans);
    float4 ablues(adjust.blues);
    float4 amagentas(adjust.magentas);
    
    //
    // LIGHTNESS photoshop changes before saturation!
    //
    hsv = adjust_lightness(hsv, areds,     hue, hueWeights, 0); // REDS
    hsv = adjust_lightness(hsv, ayellows,  hue, hueWeights, 1); // YELLOWS
    hsv = adjust_lightness(hsv, agreens,   hue, hueWeights, 2); // GREENS
    hsv = adjust_lightness(hsv, acyans,    hue, hueWeights, 3); // CYANS
    hsv = adjust_lightness(hsv, ablues,    hue, hueWeights, 4); // BLUES
    hsv = adjust_lightness(hsv, amagentas, hue, hueWeights, 5); // MAGENTAS
    
    
    //
    // SATURATION!
    //
    //hsv = adjust_saturation(hsv, reds,    hue, areds);     // REDS
    hsv = adjust_saturation(hsv, areds,    hue, hueWeights, 0);  // REDS
    hsv = adjust_saturation(hsv, ayellows, hue, hueWeights, 1);  // YELLOWS
    hsv = adjust_saturation(hsv, agreens,  hue, hueWeights, 2);  // GREENS
    hsv = adjust_saturation(hsv, acyans,   hue, hueWeights, 3);  // CYANS
    hsv = adjust_saturation(hsv, ablues,   hue, hueWeights, 4);  // BLUES
    hsv = adjust_saturation(hsv, amagentas,hue, hueWeights, 5);  // MAGENTAS

    
    //
    // HUES!
    //
    hsv = adjust_hue(hsv, areds,     hue, hueWeights, 0); // REDS
    hsv = adjust_hue(hsv, ayellows,  hue, hueWeights, 1); // YELLOWS
    hsv = adjust_hue(hsv, agreens,   hue, hueWeights, 2); // GREENS
    hsv = adjust_hue(hsv, acyans,    hue, hueWeights, 3); // CYANS
    hsv = adjust_hue(hsv, ablues,    hue, hueWeights, 4); // BLUES
    hsv = adjust_hue(hsv, amagentas, hue, hueWeights, 5); // MAGENTAS

    
    float3 rgb(HSV_2_rgb(hsv));

    if (adjust.blending.mode == 0)
        return blendLuminosity(input_color, float4(rgb, adjust.blending.opacity));
    else        
        return blendNormal(input_color, float4(rgb, adjust.blending.opacity));
}



DPMETAL_NAMESPACE_END

#endif /* __DPMETAL_ADJUSTMENT */
