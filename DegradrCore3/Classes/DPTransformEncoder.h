//
//  DPMatrix2x2.h
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>


/**
 *  Transformation Encoder keeps chains of object tranformation.
 */
@interface DPTransformEncoder : NSObject

/**
 *  Create new encoder matrices.
 *
 *  @return encoder instance.
 */
+ (DPTransformEncoder *)newEncoder;

/**
 *  Create new instance.
 */
- (instancetype)init;

/**
 *  Copy encoder.
 *
 *  @return new instance.
 */
- (instancetype)copy;

/**
 *  Scale bi-direction factor.
 *
 *  @param scale scale factor.
 */
- (void)scale:(float)scale;

/**
 *  Scale by X and Y.
 *
 *  @param x x-scale factor.
 *  @param y y-scale factor.
 */
- (void)scale:(float)x y:(float)y;

/**
 *  Rotate object on angleRad radians. 
 *
 *  @param angleRad rotation angle in radians.
 */
- (void)rotate:(float)angleRad;

/**
 * Move object acording to vector (x,y).
 * A movment translation moves every point of a figure 
 * or a space by the same amount in a given direction.
 *
 *  @param x move image on x pixels 
 *  @param y move image on 
 */
- (void)move:(float)x y:(float)y;

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
 *  Get raw data of encoded tranformations.
 *
 *  @return bytes.
 */
- (void *)raw;

/**
 *  Raw encoder data size.
 *
 *  @return bytes count.
 */
- (NSUInteger)size;

/**
 *  Recompute degrees to radians.
 *
 *  @param degrees degrees
 *
 *  @return radians
 */
+ (float)degreesToRad:(float)degrees;

@end
