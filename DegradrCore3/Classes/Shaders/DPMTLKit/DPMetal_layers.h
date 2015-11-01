//
//  DPMetal_layers.metal
//  DegradrCore3
//
//  Created by denn on 03.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#ifndef __DPMETAL_LAYERS
#define __DPMETAL_LAYERS

#include <metal_stdlib>
#include <simd/simd.h>
#include "DPMetal_stdlib.h"
#include "DPMetal_structures.h"

using namespace metal;
using namespace dpmetal;


kernel void kernel_histogramLayer(texture2d<float, access::read>    inTexture   [[texture(0)]],
                                  texture2d<float, access::write>   outTexture  [[texture(1)]],
                                  constant DPHistogramComponentsIn  &components [[buffer(0)]],
                                  uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);    
        
    float  width             = inTexture.get_width();
    float  height            = inTexture.get_height();    
    float  y_position        = (height-gid.y);
    
    uint   histogramBinIndex = uint(gid.x/width*255/components.width);   // normalize to histogram length
    float  delim = height/components.max_component*components.height;
    
    if (gid.x>width*components.width){
        outTexture.write(inColor, gid);
        return;
    }
    
    uint   redBinValue       = uint(components.reds[histogramBinIndex]*delim);   // red bin value
    uint   greenBinValue     = uint(components.greens[histogramBinIndex]*delim); // green bin value
    uint   blueBinValue      = uint(components.blues[histogramBinIndex]*delim);  // blue bin value
    uint   lumaBinValue      = uint(components.lumas[histogramBinIndex]*delim);  // luma bin value
    
    float  redBinOpacity     = y_position>=redBinValue?0.0:1.0*float4(components.reds_color).w;
    float  greenBinOpacity   = y_position>=greenBinValue?0.0:1.0*float4(components.greens_color).w;
    float  blueBinOpacity    = y_position>=blueBinValue?0.0:1.0*float4(components.blues_color).w;
    float  lumaBinOpacity    = y_position>=lumaBinValue?0.0:1.0*float4(components.lumas_color).w;
        
    float4 red_color         = float4(components.reds_color.rgb,   redBinOpacity);
    float4 green_color       = float4(components.greens_color.rgb, greenBinOpacity);
    float4 blue_color        = float4(components.blues_color.rgb,  blueBinOpacity);
    float4 luma_color        = float4(components.lumas_color.rgb,  lumaBinOpacity);
    
    float4 result = blendNormal(inColor, red_color);
    result = blendNormal(result, green_color);
    result = blendNormal(result, blue_color);
    result = blendNormal(result, luma_color);
    
    outTexture.write(result, gid);
}

#endif

