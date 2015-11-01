//
//  DPUImageProvider.m
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPUIImageProvider.h"
#include "DPTransform.h"

@implementation DPUIImageProvider

+ (instancetype) newWithImage:(UIImage *)anImage context:(DPContext *)aContext{
    DPUIImageProvider *this = [super newWithContext:aContext];
    if (this)
        [this updateFromImage:anImage];
    return this;
}

+(instancetype) newWithImage:(UIImage *)anImage context:(DPContext *)aContext maxSize:(CGFloat)maxSize {
    DPUIImageProvider *this = [super newWithContext:aContext];
    if (this)
        [this updateFromImage:anImage maxSize:maxSize];
    return this;
}

- (void) updateFromImage:(UIImage *)aImage{
    self.texture = [self textureWithImage:aImage withContext:self.context maxSize:0.0];
}

- (void) updateFromImage:(UIImage *)anImage maxSize:(CGFloat)maxSize{
    self.texture = [self textureWithImage:anImage withContext:self.context maxSize:maxSize];
}

- (DPTextureRef) textureWithImage:(UIImage *)anImage withContext:(DPContext *)context maxSize:(CGFloat)maxSize
{
    CGImageRef imageRef  = [anImage CGImage];
    CGSize     imageSize = [anImage size];
    
    CGSize imageAdjustedSize = [DPContext sizeTextureFitForSize:imageSize];
    
    //
    // downscale acording to GPU hardware limit size
    //
    NSUInteger width  = (NSUInteger)floor(imageAdjustedSize.width);
    NSUInteger height = (NSUInteger)floor(imageAdjustedSize.height);
    
    CGFloat scale = 1.0f;
    
    if (maxSize>0 && (maxSize<width || maxSize<height)) {
        scale = fmin(maxSize/width,maxSize/height);

        imageAdjustedSize.width  = width  *= scale;
        imageAdjustedSize.height = height *= scale;
    }
    
    UIImage *image = [UIImage imageWithCGImage:anImage.CGImage scale:1.0f/scale orientation:anImage.imageOrientation];
    
    width = (NSUInteger)floor(image.size.width);
    height = (NSUInteger)floor(image.size.height);
        
    CGFloat resultWidth = width;
    CGFloat resultHeight = height;
    
    
    uint8_t    *rawData      = (uint8_t *)calloc(resultHeight * resultWidth * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow   = bytesPerPixel * resultWidth;
    NSUInteger bitsPerComponent = 8;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef bitmapContext = CGBitmapContextCreate(rawData, resultWidth, resultHeight,
                                                       bitsPerComponent, bytesPerRow, colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
            
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, resultWidth, resultHeight), imageRef);
    
    CGContextRelease(bitmapContext);    
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:resultWidth
                                                                                                height:resultHeight
                                                                                             mipmapped:NO];
    DPTextureRef texture = [context.device newTextureWithDescriptor:textureDescriptor];        
    
    MTLRegion region = MTLRegionMake2D(0, 0, resultWidth, resultHeight);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    
    free(rawData);
    
    self.imageOrientation = image.imageOrientation;
    
    return texture;
}

- (void) dealloc{
    self.texture = nil;
}


@end