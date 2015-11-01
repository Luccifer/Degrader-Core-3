//
//  DPMetal_common.metal
//  DegradrCore3
//
//  Created by denn on 31.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//


#ifndef __DPMETAL_COMMON
#define __DPMETAL_COMMON

#include "DPMetal_types.h"
#include "DPMetal_constants.h"

DPMETAL_NAMESPACE_BEGIN


// maxComponent

METAL_FUNC float sinc(float x){
    return sin(x*M_PI_H)/(x*M_PI_H);
}

METAL_FUNC float lanczos(float x, float a){
    if (x == 0.0) { return 1.0;}
    if (abs(x)<a) {return sinc(x) * sinc(x/a); }
    return 0.0;
}

METAL_FUNC float gaus_distribution(float x, float fi, float mu, float sigma){
    return fi * exp(- pow( (x-mu),2.0) / (2* pow(sigma,2.0)));
}

template<typename T> METAL_FUNC T max_component(vec<T, 2> v) {
    return max(v[0], v[1]);
}

template<typename T> METAL_FUNC T max_component(vec<T, 3> v) {
    return max(v[0], max(v[1], v[2]));
}

template<typename T> METAL_FUNC T max_component(vec<T, 4> v) {
    vec<T, 2> v2 = max(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
    return max(v2[0], v2[1]);
}

// minComponent

template<typename T> METAL_FUNC T min_component(vec<T, 2> v) {
    return min(v[0], v[1]);
}

template<typename T> METAL_FUNC T min_component(vec<T, 3> v) {
    return min(v[0], min(v[1], v[2]));
}

template<typename T> METAL_FUNC T min_component(vec<T, 4> v) {
    vec<T, 2> v2 = min(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
    return min(v2[0], v2[1]);
}


template<typename T> METAL_FUNC T lum(vec<T, 3> c) {
    return dot(c, luma_factor);
}


METAL_FUNC float3 clipcolor_wlum(float3 c, float wlum) {
    
    float l = wlum;
    float n = min_component(c);
    float x = max_component(c);
    
    if (n < 0.0) {
        float v = 1.0/(l - n);
        c.r = l + ((c.r - l) * l) * v;
        c.g = l + ((c.g - l) * l) * v;
        c.b = l + ((c.b - l) * l) * v;
    }
    if (x > 1.0) {
        float v = 1.0/(x - l);
        c.r = l + ((c.r - l) * (1.0 - l)) * v;
        c.g = l + ((c.g - l) * (1.0 - l)) * v;
        c.b = l + ((c.b - l) * (1.0 - l)) * v;
    }
    
    return c;
}

METAL_FUNC float3 clipcolor(float3 c) {
    return clipcolor_wlum(c,lum(c));
}

METAL_FUNC float3 setlum(float3 c, float l) {
    float ll = lum(c);
    float d = l - ll;
    c = c + float3(d);
    return clipcolor_wlum(c,ll);
}


METAL_FUNC  float sat(float3 c) {
    float n = min_component(c);
    float x = max_component(c);
    return x - n;
}

METAL_FUNC  float mid(float cmin, float cmid, float cmax, float s) {
    return ((cmid - cmin) * s) / (cmax - cmin);
}

METAL_FUNC  float3 setsat(float3 c, float s) {
    if (c.r > c.g) {
        if (c.r > c.b) {
            if (c.g > c.b) {
                /* g is mid, b is min */
                c.g = mid(c.b, c.g, c.r, s);
                c.b = 0.0;
            } else {
                /* b is mid, g is min */
                c.b = mid(c.g, c.b, c.r, s);
                c.g = 0.0;
            }
            c.r = s;
        } else {
            /* b is max, r is mid, g is min */
            c.r = mid(c.g, c.r, c.b, s);
            c.b = s;
            c.r = 0.0;
        }
    } else if (c.r > c.b) {
        /* g is max, r is mid, b is min */
        c.r = mid(c.b, c.r, c.g, s);
        c.g = s;
        c.b = 0.0;
    } else if (c.g > c.b) {
        /* g is max, b is mid, r is min */
        c.b = mid(c.r, c.b, c.g, s);
        c.g = s;
        c.r = 0.0;
    } else if (c.b > c.g) {
        /* b is max, g is mid, r is min */
        c.g = mid(c.r, c.g, c.b, s);
        c.b = s;
        c.r = 0.0;
    } else {
        c = float3(0.0);
    }
    return c;
}

//
// flow control
//

METAL_FUNC float when_eq(float x, float y) {
    return 1.0 - abs(sign(x - y));
}

METAL_FUNC float when_neq(float x, float y) {
    return abs(sign(x - y));
}

METAL_FUNC float when_gt(float x, float y) {
    return max(sign(x - y), 0.0);
}

METAL_FUNC float when_lt(float x, float y) {
    return min(1.0 - sign(x - y), 1.0);
}

METAL_FUNC float when_ge(float x, float y) {
    return 1.0 - when_lt(x, y);
}

METAL_FUNC float when_le(float x, float y) {
    return 1.0 - when_gt(x, y);
}

METAL_FUNC float  when_and(float a, float b) {
    return a * b;
}

METAL_FUNC float  when_between_and(float x, float y, float h) {
    return when_ge(x - h, 0) * when_le(y - h, 0);
}

METAL_FUNC float  when_or(float a, float b) {
    return min(a + b, 1.0);
}

METAL_FUNC float when_not(float a) {
    return 1.0 - a;
}

//
// gamma
//

// Inverse of sRGB "gamma" function. (approx 2.2)
METAL_FUNC float inv_gam_sRGB(float ic) {
    if ( ic <= 0.04045 )
        return ic/12.92;
    else
        return pow( (ic+0.055)/(1.055), 2.4);
}

// sRGB "gamma" function (approx 2.2)
METAL_FUNC float gam_sRGB(float v) {
    if(v<=0.0031308)
        v *= 12.92;
    else
        v = 1.055*pow(v,0.41667)-0.055;
    return (v+0.001961);
}

//
// sampling
//
METAL_FUNC float4 sampledColor(
                               texture2d<float, access::sample> inTexture,
                               texture2d<float, access::write> outTexture,
                               uint2 gid
                               ){
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    float w = outTexture.get_width();
    return mix(inTexture.sample(s, float2(gid) * float2(1.0/w, 1.0/outTexture.get_height())),
               inTexture.read(gid),
               when_eq(inTexture.get_width(), w) // whe equal read exact texture color
               );
}

DPMETAL_NAMESPACE_END

#endif /* DPMETAL_NAMESPACE_END */
