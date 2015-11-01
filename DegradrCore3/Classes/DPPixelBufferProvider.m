//
//  DPPixelBufferProvider.m
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPPixelBufferProvider.h"

@implementation DPPixelBufferProvider
{
    CVMetalTextureCacheRef _videoTextureCache;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithContext:aContext];
    self.imageOrientation = UIImageOrientationLeft;
    return self;
}

- (instancetype) initWithTexture:(DPTextureRef)texture context:(DPContext *)aContext{
    self = [super initWithTexture:texture context:aContext];
    self.imageOrientation = UIImageOrientationLeft;
    return self;
}

- (void) updateFromPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    if (!_videoTextureCache) {
        CVMetalTextureCacheFlush(_videoTextureCache, 0);        
        CVReturn textureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, self.context.device, NULL, &_videoTextureCache);
        
        if (textureCacheError)
        {
            NSLog(@" *** DPView: Couldn't create a texture cache...");
            assert(0);
        }
    }

    CVReturn error;
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef textureRef;
    error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    
    if (error)
    {
        NSLog(@" *** DPView: Couldnt create texture from image: %i", error);
        assert(0);
    }
    
    id <MTLTexture> texture = CVMetalTextureGetTexture(textureRef);
    if (!texture) {
        NSLog(@" *** DPView: Couldn't get texture from texture ref");
        assert(0);
    }
    else
        CVBufferRelease(textureRef);
    
    if(texture != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // always assign the textures atomic
            self.texture = texture;
        });
    }  
    else
        self.texture = nil;
}

@end
