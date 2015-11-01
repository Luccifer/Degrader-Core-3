//
//  DPSampleFilter.m
//  DegradrCore3
//
//  Created by denn on 13.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPSampleFilter.h"

@interface DPSampleFilter()
@property (nonatomic, strong) DPTextureRef kernelTexture;
@end

@implementation DPSampleFilter
{
    DPFunction *kernel_function;
}

- (void) apply{
        
    if (self.imageSize>0.0 && self.imageSize<=[DPContext maximumTextureSize]) {
        CGFloat max   = MAX([self.source.texture width], [self.source.texture height]);
        CGFloat scale = self.imageSize/max;   
        if (scale!=1.0f && scale>0.0f) {  
            kernel_function.resampleFactor = (DPVector2){scale, scale};
        }
    }
    [super apply];
}

- (instancetype) initWithContext:(DPContext *)aContext{    
    self = [super initWithContext:aContext];
    if (self) {    
        self.kernel = @[@0,@1,@0];
        [self addFunction: kernel_function = [DPFunction newFunction:@"kernel_resamplerFilter" context:aContext]];
    }
    return self;
}

- (void) setKernel:(NSArray *)kernel{
    [self flush];
    _kernel = [kernel copy];
    _kernelTexture = nil;
    self.dirty = YES;

}

- (void) setImageSize:(CGFloat)imageSize{
    _imageSize = imageSize;
    self.dirty = YES;
}

- (DPTextureRef) kernelTexture{
    if (!_kernelTexture) {
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Float
                                                                                                     width:self.kernel.count
                                                                                                    height:1
                                                                                                 mipmapped:NO];
        
        _kernelTexture = [self.context.device newTextureWithDescriptor:textureDescriptor];
        
        MTLRegion region = MTLRegionMake2D(0, 0, self.kernel.count, 1);
        
        float *a = malloc(sizeof(float)*self.kernel.count);
        
        for (int i=0; i<self.kernel.count; i++) {
            a[i] = [self.kernel[i] floatValue];   
        }
        
        [self.kernelTexture replaceRegion:region mipmapLevel:0 withBytes:a bytesPerRow:sizeof(float) * self.kernel.count];
        
        free(a);
    }    
    return _kernelTexture;
}

- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    
    if (function == kernel_function/* || function == kernel_function_second*/) {
        [commandEncoder setTexture:self.kernelTexture atIndex:2];
    }
}

@end
