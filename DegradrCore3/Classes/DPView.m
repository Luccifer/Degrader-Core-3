//
//  DPView.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 10/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPView.h"
#import "DPConstants.h"
#import "DPContext.h"
#import "DPTransformEncoder.h"
#import "DPImageProvider.h"
#import "DPPassFilter.h"

#import <GLKit/GLKMath.h>

#define DP_UIImageIntrafaceLandscape(orientation) (UIImageOrientationLeft == (orientation) || UIImageOrientationLeftMirrored == (orientation) || UIImageOrientationRight == (orientation) || UIImageOrientationRightMirrored == (orientation))


static float viewVertexData[16] =
{
    -1.0,  -1.0,  0.0,  1.0,
    1.0,  -1.0,  1.0,  1.0,
    -1.0,   1.0,  0.0,  0.0,
    1.0,   1.0,  1.0,  0.0,
};

@interface DPView()

@property (nonatomic, strong)   DPContext                    *context;
@property (nonatomic, strong)   id <MTLRenderPipelineState>  renderPipeline;
@property (nonatomic, strong)   id <MTLBuffer>               vertexBuffer;

@property (nonatomic, assign)   BOOL isFirstFrame;
@end

@implementation DPView
{
@private
    __weak CAMetalLayer   *_metalLayer;
    
    BOOL                    isThisFirstFrame;
    
    id<CAMetalDrawable>          drawable;
    MTLRenderPassDescriptor     *renderPassDescriptor;
    id<MTLRenderCommandEncoder>  commandEncoder;
    
    // rendering
    CADisplayLink        *timer;
    dispatch_semaphore_t  inflightSemaphore;
    BOOL                  isLoopPaused;
    BOOL                  layerSizeDidUpdate;
    
    CGFloat screenScale;
    CGSize  originalSize;
    
    DPTextureRef         currentTexture;
    
    BOOL                 isInputChanged;
}

#pragma mark -
#pragma mark - Getters/Setters

@synthesize context  = _context;
@synthesize isPaused = _isPaused;

- (void) setIsFilterDisabled:(BOOL)isFilterDisabled{
    self.filter.disabled = isFilterDisabled;
}

- (DPContext*) context{
    if (_filter) {
        return _filter.context;
    }
    if (!_context) {
        _context = [DPContext new];
    }
    return _context;
} 

- (BOOL) isFilterDisabled{
    return self.filter.disabled;
}

- (void) setFilter:(DPFilter *)filter{
    
    BOOL isPaused = self.isPaused;
    
    _orientation=UIDeviceOrientationUnknown;

    self.isPaused = YES;
    
    _context = filter.context;
    
    _isFirstFrame = YES;
    _filter = filter;
    _filter.source = self.source;
    
    _vertexBuffer = nil;
    _renderPipeline = nil;
    
    _metalLayer.device          = self.context.device;
    _metalLayer.presentsWithTransaction = NO;
    
    self.isPaused = isPaused;
}

- (void) setSource:(DPImageProvider*)textureProvider{
    
    isInputChanged = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(view:willChangeWithInput:)]) {
        [self.delegate view:self willChangeWithInput:textureProvider];
    }
    
    _source = textureProvider;
    if (_filter) {
        _filter.source = _source;        
    }
    
    if (self.orientation==UIDeviceOrientationUnknown)
        [self redraw];
    else{
        self.orientation = _orientation;
    }
}

- (void) setFilterTransform:(DPTransform *)transform{
    self.filter.transform = transform;
}

- (DPTransform*) filterTransform{
    return self.filter.transform;
}

- (id<MTLBuffer>) vertexBuffer{
    if (!_vertexBuffer) {
        _vertexBuffer = [self.context.device newBufferWithBytes:viewVertexData length:sizeof(viewVertexData) options:MTLResourceOptionCPUCacheModeDefault];
        _vertexBuffer.label = @"Vertices";
    }
    return _vertexBuffer;
}

-(id<MTLRenderPipelineState>) renderPipeline{
    if (!_renderPipeline) {
        
        MTLRenderPipelineDescriptor *renderPipeline = [MTLRenderPipelineDescriptor new];
        renderPipeline.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

        renderPipeline.vertexFunction = [self.context.defaultLibrary newFunctionWithName:DP_VERTEX_VIEW_FUNCTION];
        renderPipeline.fragmentFunction = [self.context.defaultLibrary newFunctionWithName:DP_FRAGMENT_DEF_FUNCTION];
        
        _renderPipeline = [self.context.device newRenderPipelineStateWithDescriptor:renderPipeline error: nil];
    }
    return _renderPipeline;
}

- (void) setIsPaused:(BOOL)isPaused{
    _isPaused = isPaused;
    if (timer) {
        timer.paused = _isPaused;
    }
}

#pragma mark -
#pragma mark - Initilizers

+ (Class)layerClass
{
    return [CAMetalLayer class];
}

- (void)initCommon
{
    
    originalSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
    
    _orientation = UIDeviceOrientationUnknown;
    
    inflightSemaphore = dispatch_semaphore_create(kDP_LiveViewFramePrecounting);
    
    screenScale = [UIScreen mainScreen].scale;
    
    self.opaque          = YES;
    self.backgroundColor = [UIColor clearColor];
    
    _metalLayer = (CAMetalLayer *)self.layer;
    
    _metalLayer.device          = self.context.device;
    _metalLayer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
    
    // this is the default but if we wanted to perform compute on the final rendering layer we could set this to no
    _metalLayer.framebufferOnly = YES;
    
    _isPaused = YES;
        
    timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh)];
    _frameInterval = timer.frameInterval = kDP_LiveViewRefreshInterval;
    timer.paused = self.isPaused;
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void) setFrameInterval:(NSUInteger)frameInterval{
    _frameInterval = frameInterval;
    timer.frameInterval = _frameInterval;
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = self.window.screen.nativeScale;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        [self initCommon];
        originalSize = frame.size;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    return self;
}

- (instancetype) init{
    self = [super init];
    if (self) {
        [self initCommon];
    }
    return self;
}


#pragma mark -
#pragma mark - Rendering to GC

- (void) didCompletePresent{
}


- (DPTextureRef) texture{
    if (_filter) {
        return _filter.texture;
    }
    return self.source.texture;
}

- (void) redraw{
    dispatch_async(dispatch_get_main_queue(), ^{
        layerSizeDidUpdate = YES;
        self.filter.dirty = YES;
        if (self.isPaused) {
            [self refresh];
        }
    });
}

- (void)refresh
{
    //@autoreleasepool {
        
        if (!_metalLayer.device || self.context.device != _metalLayer.device) {
            _metalLayer.device = self.context.device;
        }
        
        //
        // wait next frame
        //
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER);

        if (self.source == nil || self.source.texture == nil){
            dispatch_semaphore_signal(inflightSemaphore);
            return;
        }

        id<MTLCommandBuffer> commandBuffer = [self.context beginCommand];

        // Call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
        __block typeof(self) this = self;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            
            dispatch_semaphore_signal(this->inflightSemaphore);
            
            if (!self.isFirstFrame)
                [self didCompletePresent];
        }];

        currentTexture = [self texture];
        
        CGSize  texture_size = CGSizeMake([currentTexture width],[currentTexture height]);
        
        
        //
        // check view size
        //
        
        if (layerSizeDidUpdate)
        {
            //
            // Normalize drable size
            //
            _metalLayer.drawableSize  = CGSizeMake(_metalLayer.bounds.size.width*self.contentScaleFactor,
                                                   _metalLayer.bounds.size.height*self.contentScaleFactor);
            
            //
            // check input aspect ratio
            //
            
            CGSize adjustedSize;

            if (UIDeviceOrientationIsLandscape(self.orientation)) {
                //
                // Landscape
                //
                adjustedSize = [DPContext sizeTextureFitForSize:texture_size withMaxSize:originalSize.height];
                
                switch (self.source.imageOrientation) {
                    case UIImageOrientationLeft:
                    case UIImageOrientationLeftMirrored:
                    {
                        if (texture_size.height<texture_size.width)
                            adjustedSize = [DPContext sizeTextureFitForSize:texture_size withMaxSize:originalSize.width];
                        else
                            adjustedSize = [DPContext sizeTextureFitForSize:CGSizeMake(texture_size.height, texture_size.width) withMaxSize:originalSize.height];
                        break;
                    }
                    case UIImageOrientationRight:
                    case UIImageOrientationRightMirrored:
                    {
                        if (texture_size.height>texture_size.width)
                            adjustedSize = [DPContext sizeTextureFitForSize:CGSizeMake(texture_size.height, texture_size.width) withMaxSize:originalSize.width];
                        break;
                    }
                    case UIImageOrientationDown:
                    case UIImageOrientationDownMirrored:
                    {
                        if (texture_size.height>texture_size.width)
                            adjustedSize = [DPContext sizeTextureFitForSize:texture_size withMaxSize:originalSize.width];
                        break;
                    }
                    default:
                        if (texture_size.height>texture_size.width)
                            adjustedSize = [DPContext sizeTextureFitForSize:texture_size withMaxSize:originalSize.width];
                        break;
                }
            }
            else {
                //
                // Portrait
                //
                
                adjustedSize = [DPContext sizeTextureFitForSize:texture_size withMaxSize:originalSize.width];

                switch (self.source.imageOrientation) {
                    case UIImageOrientationLeft:
                    case UIImageOrientationLeftMirrored:
                    {
                        if (texture_size.height<texture_size.width)
                            adjustedSize = [DPContext sizeTextureFitForSize:texture_size withMaxSize:originalSize.height];
                        else
                            adjustedSize = [DPContext sizeTextureFitForSize:CGSizeMake(texture_size.height, texture_size.width) withMaxSize:originalSize.height];
                        break;
                    }
                    case UIImageOrientationRight:
                    case UIImageOrientationRightMirrored:
                    {
                        if (texture_size.height>texture_size.width)
                            adjustedSize = [DPContext sizeTextureFitForSize:CGSizeMake(texture_size.height, texture_size.width) withMaxSize:originalSize.height];
                        break;
                    }                    
                    case UIImageOrientationDown:
                    case UIImageOrientationDownMirrored:
                    default:
                        if (texture_size.height>texture_size.width)
                            adjustedSize = [DPContext sizeTextureFitForSize:texture_size withMaxSize:originalSize.height];
                        break;
                }
            }
            
            if (!CGSizeEqualToSize(adjustedSize,CGSizeZero)) {
                NSTimeInterval duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration/2.0;
                [UIView animateWithDuration:duration ? 0.5 : 0.0 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     _metalLayer.bounds = (CGRect){(CGPoint){0.0, 0.0}, adjustedSize};
                                 }
                                 completion:nil
                 ];
            }
            
            if (_orientation==UIDeviceOrientationUnknown){
                _metalLayer.transform = [self correctImageOrientation:CATransform3DIdentity];
            }

            layerSizeDidUpdate = NO;
        }

        //
        // next drawble
        //
        drawable = [_metalLayer nextDrawable];
        if (!drawable){
            dispatch_semaphore_signal(inflightSemaphore);
            return;
        }
        
        //
        // rendering
        //
        if (!renderPassDescriptor) {
            renderPassDescriptor = [MTLRenderPassDescriptor new];
        }

        renderPassDescriptor.colorAttachments[0].texture     = drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].clearColor =  MTLClearColorMake(1.0, 1.0, 1.0, 0.0);
        
        commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        //
        // render current texture
        //
        
        [commandEncoder setRenderPipelineState: self.renderPipeline];
        
        [commandEncoder setVertexBuffer:        self.vertexBuffer            offset:0 atIndex:0];
        
        [commandEncoder setFragmentTexture: currentTexture atIndex:0];
                
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
        
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
                
        [self.context commitCommand];

        if (self.isFirstFrame && self.firstFrameDidReceive) {
                        
            self.firstFrameDidReceive();
            self.isFirstFrame = NO;
        }
        else{
            if (self.isFirstFrame){
                self.isFirstFrame = NO;
                [self didCompletePresent];
            }
        }
        
        if (isInputChanged) {
            isInputChanged = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(view:didChangeWithInput:)]) {
                [self.delegate view:self didChangeWithInput:self.source];
            }
        }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(view:didDestinationRedraw:)]) {
        [self.delegate view:self didDestinationRedraw:[DPImageProvider newWithTexture:currentTexture context:self.context orientation:UIImageOrientationUp]];
    }
    
   // }
}

- (void) layoutSubviews{    
    dispatch_async(dispatch_get_main_queue(), ^{
        [super layoutSubviews];
        layerSizeDidUpdate = YES;
    });
}


- (void) setNeedsDisplay{
    dispatch_async(dispatch_get_main_queue(), ^{
        [super setNeedsDisplay];
        if (self.isPaused) {
            [self refresh];
        }
    });
}

- (void) setOrientation:(UIDeviceOrientation)orientation{
    [self setOrientation:orientation animate:YES];
}

- (CATransform3D) correctImageOrientation:(CATransform3D)inTransform{
    CATransform3D transform = inTransform;
    
    switch (self.source.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        {
            transform = CATransform3DRotate(transform,[DPTransform degreesToRadians:-90.0f], 0.0f, 0.0f, -1.0f);
            break;
        }
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
        {
            transform = CATransform3DRotate(transform,[DPTransform degreesToRadians:-90.0f], 0.0f, 0.0f, -1.0f);
            break;
        }
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
        {
            transform = CATransform3DRotate(transform,[DPTransform degreesToRadians:180.0f], 0.0f, 0.0f, -1.0f);
            break;
        }
        default:
            break;
    }
    
    return transform;
}

- (void) setOrientation:(UIDeviceOrientation)orientation animate:(BOOL)animate{
    
    _orientation = orientation;
    
    NSTimeInterval duration = animate?[UIApplication sharedApplication].statusBarOrientationAnimationDuration:0.0;
    
    [UIView animateWithDuration:duration ? 0.5 : 0.0 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseIn
     
                     animations:^{
                         
                         CATransform3D transform = CATransform3DIdentity;
                         transform = CATransform3DScale(transform, 1.0f, 1.0f, 1.0f);
                         
                         transform = [self correctImageOrientation:transform];

                         switch (orientation) {
                             case UIDeviceOrientationLandscapeLeft:
                             {
                                 transform = CATransform3DRotate(transform,[DPTransform degreesToRadians:-90.0f], 0.0f, 0.0f, -1.0f);
                                 break;
                             }
                             case UIDeviceOrientationLandscapeRight:
                             {
                                 transform = CATransform3DRotate(transform,[DPTransform degreesToRadians:90.0f], 0.0f, 0.0f, -1.0f);
                                 break;
                             }
                                 
                             case UIDeviceOrientationPortraitUpsideDown:
                             {

                                 transform = CATransform3DRotate(transform,[DPTransform degreesToRadians:180.0f], 0.0f, 0.0f, -1.0f);
                                 break;
                             }
                             default:
                                break;
                         }
                         
                         _metalLayer.transform = transform;

                         [self redraw];
                     }
                     completion: nil
     ];
}

#pragma mark -
#pragma mark - Clean up

- (void) dealloc{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    if (drawable) {
        drawable = nil;
    }
    
    if (renderPassDescriptor) {
        renderPassDescriptor = nil;
    }
}


@end
