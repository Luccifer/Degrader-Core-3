//
//  DPMatrix2x2.m
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPTransformEncoder.h"

typedef struct {
    GLKMatrix3 transform;
    GLKMatrix4 transition;
} DPTransformMatrix;

static float __matrix[] = {
    1.0f, 0.0f, 0.0f,
    0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f,
};

static float __matrix_flip_horizontal[] = {
   -1.0f, 0.0f, 0.0f,
    0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f,
};

static float __matrix_flip_vertical[] = {
    1.0f, 0.0f, 0.0f,
    0.0f,-1.0f, 0.0f,
    0.0f, 0.0f, 0.0f,
};


@implementation DPTransformEncoder
{
    DPTransformMatrix matrix;
}

#pragma mark - Matrix creation

+ (DPTransformEncoder *)newEncoder{
    DPTransformEncoder *encoder = [[DPTransformEncoder alloc] init];
    return encoder;
}

- (instancetype)init{
    self = [super init];
    if(self != nil){
        matrix.transform =  GLKMatrix3MakeWithArray(__matrix);
        matrix.transition = GLKMatrix4Identity;
    }
    return self;
}

- (instancetype)copy{
    DPTransformEncoder *mCopy = [[DPTransformEncoder alloc] init];
    mCopy->matrix.transform = self->matrix.transform;
    mCopy->matrix.transition = self->matrix.transition;
    return mCopy;
}


#pragma mark - Matrix transformation

- (void)move:(float)x y:(float)y{
    
     matrix.transition = (GLKMatrix4){
         1.0f, 0.0f, 0.0f, x,
         0.0f, 1.0f, 0.0f, y,
         0.0f, 0.0f, 1.0f, 0.0,
         0.0f, 0.0f, 0.0f, 1.0
    };
}

- (void) scale:(float)scale{
    [self scale:scale y:scale];
}

- (void)scale:(float)x y:(float)y{
    matrix.transform = GLKMatrix3Scale(matrix.transform, x, y, 0.0);
}

- (void)rotate:(float)angleRad{
    matrix.transform = GLKMatrix3Rotate(matrix.transform, angleRad, 0.0, 0.0, 1.0);
}


- (void) rotate180{
    return [self rotate:[DPTransformEncoder degreesToRad:180.0f]];
}

- (void) rotateLeft{
    return [self rotate:[DPTransformEncoder degreesToRad:(90.0f)]];
}

- (void) rotateRight{
    return [self rotate:[DPTransformEncoder degreesToRad:(-90.0f)]];
}

- (void) flipHorizontal{
    matrix.transform = GLKMatrix3Multiply(GLKMatrix3MakeWithArray(__matrix_flip_horizontal), matrix.transform);
}

- (void) flipVertical{
    matrix.transform = GLKMatrix3Multiply(GLKMatrix3MakeWithArray(__matrix_flip_vertical), matrix.transform);
}

- (void)multiply:(DPTransformEncoder *)matrixIn{
    matrix.transform = GLKMatrix3Multiply(matrixIn->matrix.transform, matrix.transform);
}


#pragma mark - Helping methods

- (void *)raw{
    return &matrix;
}

+ (float)degreesToRad:(float)degrees{
    return GLKMathDegreesToRadians(degrees);
}

+ (NSUInteger)length{
    return 25 ;
}

- (NSUInteger) size{
    return  sizeof(matrix);
}

- (NSString*) description{
    
    NSString *s1= [NSString stringWithFormat:@"%+2.2f,%+2.2f,%+2.2f", matrix.transform.m00,matrix.transform.m01,matrix.transform.m02];
    NSString *s2= [NSString stringWithFormat:@"%+2.2f,%+2.2f,%+2.2f", matrix.transform.m10,matrix.transform.m11,matrix.transform.m12];
    NSString *s3= [NSString stringWithFormat:@"%+2.2f,%+2.2f,%+2.2f", matrix.transform.m20,matrix.transform.m21,matrix.transform.m22];
    
    return [NSString stringWithFormat:@" *** matrix = \n [%@]\n [%@]\n [%@]", s1, s2, s3];
}

@end
