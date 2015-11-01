//
//  DPThumbFilter.m
//  DegradrCore3
//
//  Created by denn on 11.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPThumbFilter.h"
#import "DPLanczosSampler.h"
#import "DPSmartResizeFilter.h"
#import "DPConstants.h"

@interface DPThumbFilter()
@property (nonatomic,strong)     DPSmartResizeFilter *resizeFilter;
@end

@implementation DPThumbFilter
{
    DPFunction *kernel_function;
}

- (CGFloat) imageSize{
    return  self.resizeFilter.imageSize;
}

- (void) setImageSize:(CGFloat)maxSize{
    self.resizeFilter.imageSize = maxSize;
}

- (DPSmartResizeFilter*) resizeFilter{
    if (!_resizeFilter) {
        _resizeFilter = [DPSmartResizeFilter newWithContext:self.context];
        _resizeFilter.imageSize = 500.0f;
    }
    
    return _resizeFilter;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithVertex:DP_VERTEX_DEF_FUNCTION withFragment:DP_FRAGMENT_DEF_FUNCTION context:aContext];
    if (_isSquared) {
        _isSquared = YES;
    }
    return self;
}

- (void) setSource:(DPImageProvider *)input{             
    DPImageProvider *thumb = [DPImageProvider newWithProvider:input];
    [thumb transformOrientation:UIImageOrientationUp];
    self.resizeFilter.source = thumb;
    [super setSource:self.resizeFilter.destination];        
}

- (void) setIsInverted:(BOOL)isInverted{
    if (isInverted) {
        if (!kernel_function)  kernel_function = [DPFunction newFunction:@"kernel_invert" context:self.context];        
        [self removeFunction:kernel_function];
        [self addFunction:kernel_function];
    }
    else if(kernel_function) [self removeFunction:kernel_function];

    _isInverted = isInverted;
    
    self.dirty = YES;
}

- (void) setIsSquared:(BOOL)isSquared{
    _isSquared=isSquared;
    self.dirty = YES;
}

- (void) apply{
    
    CGSize  size = CGSizeMake([self.source.texture width], [self.source.texture height]);
    
    GLfloat mL   = (GLfloat)fabsf((float)size.height-(float)size.width)/2.0f;
    
    if (mL!=0.0) {
        GLfloat mB   = (GLfloat)(size.width>size.height?size.width:size.width<size.height?size.height:1.0f);
        
        GLfloat minX = self.isSquared==NO?0.0f:size.width>size.height?mL/mB:0.0f;
        GLfloat minY = self.isSquared==NO?0.0f:size.width<size.height?mL/mB:0.0f;
        GLfloat maxX = self.isSquared==NO?0.0f:minX;
        GLfloat maxY = self.isSquared==NO?0.0f:minY;
        
        DPTransform *transform = [self.transform copy];
        
        transform.cropRegion = (DPCropRegion){
            minY,maxX,  // top, right
            minX,maxY,  // left, bottom
        };
        
        self.transform = transform;        
    }
    
    [super apply];
}

@end
