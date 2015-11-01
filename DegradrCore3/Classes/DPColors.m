//
//  DPColors.m
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPColors.h"

@implementation DPColors

+ (DPVector3) rgba_2_HSL:(DPVector4) color
{
    DPVector3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
    
    float min = fmin(fmin(color.r, color.g), color.b);    //Min. value of RGB
    float max = fmax(fmax(color.r, color.g), color.b);    //Max. value of RGB
    float delta = max - min;             //Delta RGB value
    
    hsl.z = (max + min) * 0.5; // Luminance
    
    if (delta == 0.0)   //This is a gray, no chroma...
    {
        hsl.x = 0.0;	// Hue
        hsl.y = 0.0;	// Saturation
    }
    else                //Chromatic data...
    {
        if (hsl.z < 0.5)
            hsl.y = delta / (max + min); // Saturation
        else
            hsl.y = delta / (2.0 - max - min); // Saturation
        
        float deltaR = (((max - color.r) / 6.0) + (delta * 0.5)) / delta;
        float deltaG = (((max - color.g) / 6.0) + (delta * 0.5)) / delta;
        float deltaB = (((max - color.b) / 6.0) + (delta * 0.5)) / delta;
        
        if (color.r == max )     hsl.x = deltaB - deltaG; // Hue
        else if (color.g == max) hsl.x = 0.33333 + deltaR - deltaB; // Hue
        else if (color.b == max) hsl.x = 0.66667 + deltaG - deltaR; // Hue
        
        if (hsl.x < 0.0)       hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)  hsl.x -= 1.0; // Hue
    }
    
    return hsl;
}

float hue_2_rgb(float f1, float f2, float hue)
{
    if (hue < 0.0)      hue += 1.0;
    else if (hue > 1.0) hue -= 1.0;
    
    float res;
    
    if ((6.0 * hue) < 1.0)      res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0) res = f2;
    else if ((3.0 * hue) < 2.0) res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else                        res = f1;
    return res;
}

+ (DPVector4) HSL_2_rgba:(DPVector3) hsl
{
    DPVector4 rgb; rgb.a = 1.0;
    
    if (hsl.y == 0.0) rgb = (DPVector4){hsl.z,hsl.z,hsl.z,1.0f}; // Luminance
    else
    {
        float f2;
        
        if (hsl.z < 0.5) f2 = hsl.z * (1.0 + hsl.y);
        else             f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
        
        float f1 = 2.0 * hsl.z - f2;
        
        rgb.r = hue_2_rgb(f1, f2, hsl.x + 0.33333);
        rgb.g = hue_2_rgb(f1, f2, hsl.x);
        rgb.b = hue_2_rgb(f1, f2, hsl.x - 0.33333);
    }
    
    return rgb;
}


@end
