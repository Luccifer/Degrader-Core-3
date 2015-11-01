//
//  DPTransform.m
//  DegradrCore3
//
//  Created by denn on 16.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPTransform.h"

@implementation DPTransform

- (instancetype) init{
    self = [super init];
    if (self) {
        _encoder = [DPTransformEncoder newEncoder];
        _resampleFactor = 1.0f;
        _keepAspectRatio = NO;
        _cropRegion.bottom = 0.0f;
        _cropRegion.top = 0.0f;
        _cropRegion.left = 0.0f;
        _cropRegion.right = 0.0f;
        self.cropRegion = _cropRegion;
    }
    
    return self;
}

@synthesize resampleFactor = _resampleFactor;

+ (float)degreesToRadians:(CGFloat)degrees{
    return GLKMathDegreesToRadians(degrees);
}

+ (float)radiansToDegrees:(CGFloat)radians{
    return GLKMathRadiansToDegrees(radians);
}


- (instancetype) copyWithZone:(NSZone *)zone{
    DPTransform *newObj = [[self class] allocWithZone:zone];
    newObj->_cropRegion = self->_cropRegion;
    newObj->_cropRect = self->_cropRect;
    newObj->_encoder = [self->_encoder copy];
    newObj->_resampleFactor = self->_resampleFactor;
    newObj->_keepAspectRatio = self->_keepAspectRatio;
    newObj->_rotationDegrees = self->_rotationDegrees;
    newObj->_rotationRadians = self->_rotationRadians;
    newObj->_translation = self->_translation;
    newObj->_scale = self->_scale;
    return newObj;
}

- (NSDictionary*) toDictionary{
    return @{
             @"Scale": @(self.scale),
             @"Resample Factor": @(self.resampleFactor),
             @"Keep Aspect Ratio": @(self.keepAspectRatio),
             @"Rotation Radians": @(self.rotationRadians),
             @"Translation": @{@"x":@(self.translation.x), @"y":@(self.translation.y)},
             @"Crop Rect": @{
                     @"origin": @{@"x":@(self.cropRect.origin.x), @"y":@(self.cropRect.origin.y)},
                     @"size":   @{@"width":@(self.cropRect.size.width), @"height":@(self.cropRect.size.height)},
                     },
             };
}

- (void) fromDictionary:(NSDictionary *)dictionary{
    
    id<DPTransformDelegate> tmp_delegate = self.delegate;
    
    self.delegate = nil;
    
    self.scale=[dictionary[@"Scale"] floatValue];
    self.resampleFactor=[dictionary[@"Resample Factor"] floatValue];
    self.keepAspectRatio=[dictionary[@"Keep Aspect Ratio"] boolValue];
    self.rotationRadians=[dictionary[@"Rotation Radians"] floatValue];
    NSDictionary *value = dictionary[@"Translation"];
    self.translation= CGPointMake([value[@"x"] floatValue], [value[@"y"] floatValue]);
    value = dictionary[@"Crop Rect"];

    NSDictionary *origin = value[@"origin"];
    NSDictionary *size   = value[@"size"];
    self.cropRect= (CGRect){
        CGPointMake([origin[@"x"] floatValue], [origin[@"y"] floatValue]),
        CGSizeMake([size[@"width"] floatValue], [size[@"height"] floatValue])
    };
    
    self.delegate = tmp_delegate;
    
    [self checkUpdate];
}

- (void) checkUpdate{
    if (self.delegate && [self.delegate respondsToSelector:@selector(transform:didUpdateAtTime:)]) {
        [self.delegate transform:self didUpdateAtTime:CMTimeMakeWithSeconds([NSDate timeIntervalSinceReferenceDate], 1)];
    }
}

-(void) setResampleFactor:(CGFloat)resampleFactor{
    _resampleFactor=resampleFactor;
    [self checkUpdate];
}

- (void) setCropRegion:(DPCropRegion)cropRegion{
    _cropRect = CGRectMake(cropRegion.left, cropRegion.top, 1.0-(cropRegion.right+cropRegion.left), 1.0-(cropRegion.bottom+cropRegion.top));
    _cropRegion = cropRegion;
    [self checkUpdate];
}

- (void) setCropRect:(CGRect)cropRect{
    _cropRect = cropRect;

    _cropRect.origin.x    =  _cropRect.origin.x<0.0?0.0:_cropRect.origin.x;
    _cropRect.origin.x    =  _cropRect.origin.x>1.0?1.0:_cropRect.origin.x;
    _cropRect.size.width  =  _cropRect.size.width+_cropRect.origin.x>1.0?1.0-_cropRect.origin.x>1:_cropRect.size.width;
    _cropRect.size.height =  _cropRect.size.height+_cropRect.origin.y>1.0?1.0-_cropRect.origin.y>1:_cropRect.size.height;
    
    _cropRegion = (DPCropRegion){cropRect.origin.y, 1.0f-(cropRect.size.width+cropRect.origin.x), cropRect.origin.x, 1.0f-(cropRect.size.height+cropRect.origin.y)};
    
    [self checkUpdate];
}

- (void) setScale:(CGFloat)scale{
    _scale = scale;
    [self.encoder scale:_scale];
    [self checkUpdate];
}

- (void) setRotationDegrees:(CGFloat)rotationDegrees{
    _rotationDegrees = rotationDegrees;
    _rotationRadians = [DPTransform degreesToRadians:_rotationDegrees];
    [self.encoder rotate:_rotationRadians];
    [self checkUpdate];
}

- (void) setRotationRadians:(CGFloat)rotationRadians{
    _rotationRadians = rotationRadians;
    _rotationDegrees = [DPTransform radiansToDegrees:_rotationRadians];
    [self.encoder rotate:_rotationRadians];
    [self checkUpdate];
}

- (void) setTranslation:(CGPoint)translation{
    _translation = translation;
    [self.encoder move:translation.x y:translation.y];
    [self checkUpdate];
}

- (void) rotateLeft{
    [self.encoder rotateLeft];
    [self checkUpdate];
}

- (void) rotateRight{
    [self.encoder rotateRight];
    [self checkUpdate];
}

- (void) rotate180{
    [self.encoder rotate180];
    [self checkUpdate];
}

- (void) flipHorizontal{
    [self.encoder flipHorizontal];
    [self checkUpdate];
}

- (void) flipVertical{
    [self.encoder flipVertical];
    [self checkUpdate];
}

@end
