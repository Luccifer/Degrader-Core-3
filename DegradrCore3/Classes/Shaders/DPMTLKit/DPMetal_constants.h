//
//  DPMetal_constants.h
//  DegradrCore3
//
//  Created by denn on 31.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//


#ifndef __DPMETAL_CONSTANTS
#define __DPMETAL_CONSTANTS

#include "DPMetal_types.h"

DPMETAL_NAMESPACE_BEGIN

#define CIELAB_REF_X  95.047
#define CIELAB_REF_Y  100.000
#define CIELAB_REF_Z  108.883

// avarage
static constant float3 luma_factor = float3(0.299, 0.587, 0.114);

static constant float3 luma_avg_factor = float3(0.3333, 0.3333, 0.3333);

// sRGB luminance(Y) values
static constant float3 luma_Y_factor = float3(0.2125, 0.7154, 0.0721);

//
// color circle
//
constant float4 reds     = float4(315.0, 345.0, 15.0,   45.0);
constant float4 yellows  = float4( 15.0,  45.0, 75.0,  105.0);
constant float4 greens   = float4( 75.0, 105.0, 135.0, 165.0);
constant float4 cyans    = float4(135.0, 165.0, 195.0, 225.0);
constant float4 blues    = float4(195.0, 225.0, 255.0, 285.0);
constant float4 magentas = float4(255.0, 285.0, 315.0, 345.0);


DPMETAL_NAMESPACE_END

#endif /* DPMETAL_NAMESPACE_END */
