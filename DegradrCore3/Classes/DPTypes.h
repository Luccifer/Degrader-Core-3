//
//  DPKernelTypes.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#ifndef DegradrCore3_DPKernelTypes_h
#define DegradrCore3_DPKernelTypes_h

#import "DPTexture.h"
#import "DPImageProvider.h"
#import <GLKit/GLKMath.h>

typedef enum {
    DP_BLENDING_LUMINOSITY = 0,
    DP_BLENDING_NORMAL
} DPFilterBlending;

typedef struct {
    int   mode;
    float opacity;
}DPBlending;

typedef struct{
    uint32_t   width;
    uint32_t   height;
    float  resampleFactor;
} DPOutputTextureInfo;


@class DPFilter;
typedef void (^processImageProvider)(DPImageProvider*);

#endif
