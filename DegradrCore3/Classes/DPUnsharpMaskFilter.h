//
//  DPUnsharpMaskFilter.h
//  DegradrCore3
//
//  Created by denn on 11.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPGaussianBlur.h"


@interface DPUnsharpMaskFilter : DPGaussianBlur
@property (nonatomic,assign) float intensity;
@end

typedef struct {
    float dark;    // dark  edge intensity 
    float light;   // light edge intensity 
    DPBlending blending;
}DPSoftUnsharpMaskIntensity;

@interface DPSoftUnsharpMaskFilter : DPGaussianBlur
@property (nonatomic,assign) DPSoftUnsharpMaskIntensity intensity;
@end
