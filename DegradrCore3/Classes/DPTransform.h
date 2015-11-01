//
//  DPTransform.h
//  DegradrCore3
//
//  Created by denn on 16.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "DPArchiver.h"
#import "DPTransformEncoder.h"
#import "DPTypes.h"

typedef struct {
    float top;   float right;
    float left;  float bottom;
} DPCropRegion;


@class DPTransform;

@protocol DPTransformDelegate <NSObject>

- (void) transform:(DPTransform*)transform didUpdateAtTime:(CMTime)time;

@end

/**
 *  Tranformation command buffer.
 */
@interface DPTransform : NSObject <NSCopying,DPCoding>

@property (nonatomic,strong) id<DPTransformDelegate> delegate;

/**
 *  Transformation encoder.
 */
@property (nonatomic, readonly) DPTransformEncoder  *encoder;

/**
 *  Set region where any transformations apply.
 *  [top,right
 *  left,bottom]
 */
@property (nonatomic, assign)   DPCropRegion  cropRegion;

/**
 *  Set rectangle where any transformations apply.
 *  [x,y width,height] in normilized form (i.e. 0...1)
 */
@property (nonatomic, assign)   CGRect        cropRect;

/**
 *  Set resample factor for tranformations.
 */
@property (nonatomic, assign)   CGFloat      resampleFactor; // up/downscale

/**
 * Keep aspect ratio when texture transformation applaing.
 */
@property (nonatomic, assign)   BOOL         keepAspectRatio;

/**
 *  Scale bi-direction factor.
 *
 *  @param scale scale factor.
 */
@property (nonatomic, assign)   CGFloat scale;

/**
 * Transformation rotation in degrees
 */
@property (nonatomic, assign)   CGFloat rotationDegrees;

/**
 * Transformation rotation in radians
 */
@property (nonatomic, assign)   CGFloat rotationRadians;

/**
 * Translate (move) texture within view port to  distance equal point distance.
 * 
 * Move an object acording to vector CGPoint(x,y).
 * A movment translation moves every point of a figure or a space by the same amount in a given direction.
 */
@property (nonatomic, assign)  CGPoint  translation;


/**
 *  Default rotations.
 */
- (void)rotateLeft;
- (void)rotateRight;
- (void)rotate180;

/**
 *  Reflect object vertical.
 */
- (void)flipVertical;

/**
 *  Reflect object horizontal.
 */
- (void)flipHorizontal;

/**
 *  Recompute degrees to radians.
 *
 *  @param degrees degrees
 *
 *  @return radians
 */
+ (float)degreesToRadians:(CGFloat)degrees;
+ (float)radiansToDegrees:(CGFloat)radians;

@end
