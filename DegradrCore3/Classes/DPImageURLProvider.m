//
//  DPImageURLProvider.m
//  DegradrCore3
//
//  Created by denn on 04.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPImageURLProvider.h"
#import "DPConstants.h"
#import <ImageIO/ImageIO.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation DPImageURLProvider

+ (instancetype) newWithImageURL:(NSURL *)url context:(DPContext *)aContext maxSize:(CGFloat)maxSize{
    DPImageURLProvider *this = [super newWithContext:aContext];
    if (this) {
        NSError *error;
        [this updateFromImageURL:url error:&error maxSize:maxSize];
        if (error) {
            NSLog(@" *** DPImageProvider: %@", error);
        }
    }
    return this;
}

+ (instancetype) newWithImageURL:(NSURL *)url context:(DPContext *)aContext{
    return [[self class] newWithImageURL:url context:aContext maxSize:0.0f];
}

- (void) updateFromImageURL:(NSURL *)url error:(NSError *__autoreleasing *)error maxSize:(CGFloat)maxSize{    
    
    CGDataProviderRef provider = CGDataProviderCreateWithURL(( __bridge CFURLRef) url);
    
    if (!provider) {
        if (error) {
            *error = [[NSError alloc ] initWithDomain:@""DP_QUEUE_PREFIX"jpeg.url"
                                                 code: ENOENT
                                             userInfo: @{
                                                         NSLocalizedDescriptionKey:  [NSString stringWithFormat:NSLocalizedString(@"Image url %@ can't be open", nil),url],
                                                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Url can't be openned", nil),
                                                         }];
        }
        self.texture = nil;
        return;
    }
    
    NSMutableDictionary *options = [@{
                                 (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                 (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                 } mutableCopy];

    if (maxSize>0.0f) {
        [options addEntriesFromDictionary:@{(NSString *)kCGImageSourceThumbnailMaxPixelSize : @(maxSize)}];
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) options);
    self.imageOrientation = UIImageOrientationUp;
    
    CFRelease(source);
    CFRelease(provider);
    
    if (!imageRef) {
        if (error) {
            *error = [[NSError alloc ] initWithDomain:@""DP_QUEUE_PREFIX"jpeg.url"
                                                 code: ENOENT
                                             userInfo: @{
                                                         NSLocalizedDescriptionKey:  [NSString stringWithFormat:NSLocalizedString(@"Image url %@ error converting", nil),url],
                                                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Image can't be convrted", nil),
                                                         }];
        }
        self.texture = nil;
        return;
    }
    
    CGSize     imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    CGSize imageAdjustedSize = [DPContext sizeTextureFitForSize:imageSize];
    
    //
    // downscale acording to GPU hardware limit size
    //
    NSUInteger width  = (NSUInteger)floor(imageAdjustedSize.width);
    NSUInteger height = (NSUInteger)floor(imageAdjustedSize.height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint8_t    *rawData      = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow   = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef bitmapContext = CGBitmapContextCreate(rawData, width, height,
                                                       bitsPerComponent, bytesPerRow, colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(bitmapContext);
    CGImageRelease(imageRef);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:width
                                                                                                height:height
                                                                                             mipmapped:NO];
    DPTextureRef texture = [self.context.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    
    free(rawData);
    
    self.texture = texture;
}
@end
