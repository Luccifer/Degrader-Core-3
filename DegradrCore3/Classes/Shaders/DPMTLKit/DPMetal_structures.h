//
//  DPMetal_structures.metal
//  DegradrCore3
//
//  Created by denn on 31.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//


#ifndef __DPMETAL_STRUCTURES
#define __DPMETAL_STRUCTURES

#include "DPMetal_types.h"

DPMETAL_NAMESPACE_BEGIN


typedef struct {
    packed_float2 position;
    packed_float2 texcoord;
} VertexIn;

typedef struct{
    uint   width;
    uint   height;
    float  resampleFactor;
} OutputTextureInfo;

typedef struct {
    float4 position [[position]];
    float2 texcoord;
} VertexOut;

typedef struct {
    float         transform[9];
    float4x4      transition;
} Transform;

typedef struct {
    float4x4  matrix;
} OrthoMatrix;

typedef struct {
    int    mode;
    float  opacity;
} DPBlending;


//
// Histogram
//
typedef struct {
    atomic_uint reds  [256];
    atomic_uint greens[256];
    atomic_uint blues [256];
    atomic_uint lumas [256];
    atomic_uint count;
}DPHistogramBufferIn;


//
// Adjustments 
//

typedef struct{
    float         exposure;
    DPBlending    blending;
} DPExposureAdjustmentIn;


typedef struct{
    float         brightness;
    DPBlending    blending;
} DPBrightnessAdjustmentIn;


typedef struct{
    packed_float4 averageColor;
    DPBlending    blending;
} DPAWBAdjustmentIn;


typedef struct{
    
    packed_float4 minimum;
    packed_float4 middle;
    packed_float4 maximum;
    
    packed_float4 minOutput;
    packed_float4 maxOutput;
    
    DPBlending    blending;

} DPLevelsAdjustmentIn;


typedef struct{
    DPBlending    blending;
} DPCurveAdjustIn;


typedef struct{
    packed_float2 shadows;    // [level, tonal width]
    packed_float2 highlights; // [level, tonal width]
    DPBlending    blending;
} DPHighlightsShadowsIn;


typedef struct {
    packed_float4 reds;
    packed_float4 yellows;
    packed_float4 greens;
    packed_float4 cyans;
    packed_float4 blues;
    packed_float4 magentas;
    DPBlending    blending;
} DPHSVAdjustIn;


typedef struct {
    float dark;    // dark  edge intensity 
    float light;   // light edge intensity 
    DPBlending    blending;
}DPSoftUnsharpMaskIntensityIn;


typedef struct{
    float  reds  [256];
    float  greens[256];
    float  blues [256];
    float  lumas [256];
    float  max_component;
    float4 reds_color;
    float4 greens_color;
    float4 blues_color;
    float4 lumas_color;
    float  x;
    float  y;
    float  width;
    float  height;
}DPHistogramComponentsIn;


typedef struct{
    float saturation;
    float black;
    float white;
} DPGrayClippingIn;


DPMETAL_NAMESPACE_END

#endif /* DPMETAL_NAMESPACE_END */
