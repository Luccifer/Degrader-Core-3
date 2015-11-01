//
//  UIImage+DPImageProvider.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 07/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "UIImage+DPImageProvider.h"
#import "DPImageProvider.h"
#import "DPConstants.h"

static void DPReleaseDataCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation UIImage(DPImageProvider)

+ (UIImage*) imageWithImageProvider:(DPImageProvider *)provider{
    return [[self class] imageWithImageProvider:provider scale:1.0 orientation:provider.imageOrientation];
}

+ (UIImage*) imageWithImageProvider:(DPImageProvider *)provider scale:(CGFloat)scale orientation:(UIImageOrientation)orientation{
    NSUInteger   width          = [provider.texture width];
    NSUInteger   height         = [provider.texture height];
    
    NSUInteger  bytesPerRow     = width * 4;
    size_t      imageByteCount  = bytesPerRow * height ;
    void       *imageBytes      = malloc(imageByteCount);
    
    MTLRegion region       = MTLRegionMake2D(0, 0, width, height);
    
    [provider.texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    
    CGDataProviderRef cgprovider = CGDataProviderCreateWithData(NULL, imageBytes, imageByteCount, DPReleaseDataCallback);
    
    int bitsPerPixel     = kDP_bitsPerComponent * 4;
    
    CGColorSpaceRef         colorSpaceRef  = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        kDP_bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpaceRef,
                                        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big,
                                        cgprovider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:scale orientation:orientation];
    
    CFRelease(cgprovider);
    CFRelease(colorSpaceRef);
    CFRelease(imageRef);
    
    return image;
}

-(UIImage*) drawText:(NSString*) text
             atPoint:(CGPoint)   point
{
    
    NSMutableAttributedString *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",text]];
    
    // text color
    [textStyle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.7 green:0.5 blue:0.0 alpha:1.0] range:NSMakeRange(0, textStyle.length)];
    
    // text font
    [textStyle addAttribute:NSFontAttributeName  value:[UIFont systemFontOfSize:50.0] range:NSMakeRange(0, textStyle.length)];
    
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0,0,self.size.width,self.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, self.size.width, self.size.height);
    [[UIColor whiteColor] set];
    
    // add text onto the image
    [textStyle drawInRect:CGRectIntegral(rect)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
