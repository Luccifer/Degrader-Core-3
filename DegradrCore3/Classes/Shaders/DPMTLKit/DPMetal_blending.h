//
//  DPMetal_blending.h
//  DegradrCore3
//
//  Created by denn on 31.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//
//
//  Acknowledgement:
//  http://www.sunsetlakesoftware.com/ - the famous great work for Image Processing with GPU
//  A lot of ideas were taken from the Brad Larson project: https://github.com/BradLarson/GPUImage
//
//  Photoshop blending examples: https://mouaif.wordpress.com/2009/01/05/photoshop-math-with-glsl-shaders/
//

//
// TODO: add common blending functions
//


#ifndef __DPMETAL_BLENDING
#define __DPMETAL_BLENDING

#include "DPMetal_types.h"
#include "DPMetal_common.h"
#include "DPMetal_colorSpaces.h"

DPMETAL_NAMESPACE_BEGIN

#define blendLighten(base, blend) 		max(blend, base)
#define blendDarken(base, blend) 		min(blend, base)

METAL_FUNC  float4 blendLuminosity(float4 baseColor, float4 overlayColor)
{
    return float4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(baseColor.rgb, lum(overlayColor.rgb)) * overlayColor.a, baseColor.a);
}

METAL_FUNC  float4 blendOverlay(float4 base, float4 overlay)
{
    float ra;
    if (2.0 * base.r < base.a) {
        ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    } else {
        ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    }
    
    float ga;
    if (2.0 * base.g < base.a) {
        ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    } else {
        ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    }
    
    float ba;
    if (2.0 * base.b < base.a) {
        ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    } else {
        ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    }
    
    return float4(ra, ga, ba, 1.0);
}

METAL_FUNC  float4 blendNormal(float4 base, float4 overlay)
{
    float4 c2 = base;
    float4 c1 = overlay;
    
    float4 outputColor;
    
    float a = c1.a + c2.a * (1.0 - c1.a);
    float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output
    
    outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.a = a;
    
    return clamp(outputColor, float4(0.0), float4(1.0));
}


#define BlendAddf(base, blend) 		    min(base + blend, 1.0)
#define BlendLinearDodgef 			    BlendAddf
#define BlendColorDodgef(base, blend) 	((blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0))
#define BlendSubstractf(base, blend) 	max(base + blend - 1.0, 0.0)
#define BlendLinearBurnf 			    BlendSubstractf
#define BlendLinearLightf(base, blend) 	(blend < 0.5 ? BlendLinearBurnf(base, (2.0 * blend)) : BlendLinearDodgef(base, (2.0 * (blend - 0.5))))
#define BlendScreenf(base, blend) 		(1.0 - ((1.0 - base) * (1.0 - blend)))

#define Blend(base, blend, funcf) 		float4(funcf(base.r, blend.r), funcf(base.g, blend.g), funcf(base.b, blend.b), blend.a)

METAL_FUNC float4 blendLinearLight(float4 base, float4 blend){
    return Blend(base, blend, BlendLinearLightf);
}

METAL_FUNC float4 blendScreen(float4 base, float4 blend){
    return Blend(base, blend, BlendScreenf);
}

METAL_FUNC float4 blendMultiply(float4 base, float4 blend){
    return base*blend;
}


DPMETAL_NAMESPACE_END

#endif /* DPMETAL_NAMESPACE_END */
