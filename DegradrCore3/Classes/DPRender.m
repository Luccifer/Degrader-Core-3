////
//  DPRenderPass.m
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPRender.h"
#import "DPTransformEncoder.h"
#import "DPConstants.h"


@interface DPRender()
@property (nonatomic, strong)   DPContext                    *context;
@property (nonatomic, strong)   id <MTLRenderPipelineState>  renderPipeline;
@property (nonatomic, strong)   id <MTLBuffer>               vertexBuffer;
@property (nonatomic, strong)   id <MTLBuffer>               transformBuffer;
@property (nonatomic, strong)   id <MTLBuffer>               ortoMatrixBuffer;

@property (nonatomic, strong)   NSString *vertexFunction;
@property (nonatomic, strong)   NSString *fragmentFunction;

@end

@implementation DPRender
{
    MTLRenderPassDescriptor *renderPassDescriptor;
    DPTextureRef             sourceTexture;
    GLKMatrix4               orthoMatrix;
    CGFloat                  aspectRatio;
}


@synthesize texture=_texture;

#pragma mark - 
#pragma mark - Construtors

+ (instancetype) newWithContext:(DPContext *)aContext{
    return [[self alloc] initWithContext:aContext];
}

- (instancetype) initWithContext:(DPContext *)aContext{
    return [self initWithVertex:DP_VERTEX_DEF_FUNCTION withFragment:DP_FRAGMENT_DEF_FUNCTION context:aContext];
}

- (instancetype) initWithVertex:(NSString *)vertexFunction withFragment:(NSString *)fragmentFunction context:(DPContext *)aContext{
    self = [super init];
    
    if (self) {
        _context = aContext;
        _vertexFunction   = vertexFunction;
        _fragmentFunction = fragmentFunction;
    }
    
    return self;
}

#pragma mark - 
#pragma mark - Getters/Setters

- (id<MTLBuffer>) vertexBuffer{
    DPCropRegion region = self.transform.cropRegion;
        
    float data[16] = {
        //x     y                         cordx                              coordy
        -1.0,  -1.0*aspectRatio, /*left bottom*/     +region.left, /*left offset*/  1.0-region.bottom, /* bottom offset*/
        +1.0,  -1.0*aspectRatio, /*right bottom*/ 1.0-region.right,/*right offset*/ 1.0-region.bottom, /* bottom offset*/
        -1.0,  +1.0*aspectRatio, /*left top*/        +region.left, /*left offset*/     +region.top,    /* top offset*/
        +1.0,  +1.0*aspectRatio, /*right top*/    1.0-region.right,/*right offset*/    +region.top,    /* top offset*/
    };

    if (!_vertexBuffer) {
        _vertexBuffer = [self.context.device newBufferWithLength:sizeof(data) options:MTLResourceOptionCPUCacheModeDefault];
        _vertexBuffer.label = @"Vertices";
    }
    
    memcpy([_vertexBuffer contents], data, sizeof(data));
    return _vertexBuffer;
}


- (DPTransform*) transform{
    @synchronized(self){
        if (!_transform) {
            _transform = [DPTransform new];
        }
        return _transform;
    }
}


- (GLKMatrix4) makeOrthoMatrixAspectRatio:(CGFloat)aspectRatioIn;
{
    aspectRatio = aspectRatioIn<=0.0?1.0:aspectRatioIn;
    CGFloat bottom = -1.0;
    CGFloat top    = 1.0;
    CGFloat left   = (-1.0 * aspectRatio);
    CGFloat right  = (1.0 * aspectRatio);
    
    CGFloat near   = -1.0;
    CGFloat far = 1.0;
    GLfloat r_l = right - left;
    GLfloat t_b = top - bottom;
    GLfloat f_n = far - near;
    GLfloat tx = - (right + left) / (right - left);
    GLfloat ty = - (top + bottom) / (top - bottom);
    GLfloat tz = - (far + near) / (far - near);
    
    float scale = 2.0f;
    
    GLKMatrix4 matrix;
    
    matrix.m[0] = scale / t_b;
    matrix.m[1] = 0.0f;
    matrix.m[2] = 0.0f;
    matrix.m[3] = tx;
    
    matrix.m[4] = 0.0f;
    matrix.m[5] = scale / r_l;
    matrix.m[6] = 0.0f;
    matrix.m[7] = ty;
    
    matrix.m[8] = 0.0f;
    matrix.m[9] = 0.0f;
    matrix.m[10] = scale / f_n;
    matrix.m[11] = tz;
    
    matrix.m[12] = 0.0f;
    matrix.m[13] = 0.0f;
    matrix.m[14] = 0.0f;
    matrix.m[15] = 1.0f;
    
    
//    NSString *s1= [NSString stringWithFormat:@"%+2.2f,%+2.2f,%+2.2f,%+2.2f", matrix.m00,matrix.m01,matrix.m02,matrix.m03];
//    NSString *s2= [NSString stringWithFormat:@"%+2.2f,%+2.2f,%+2.2f,%+2.2f", matrix.m10,matrix.m11,matrix.m12,matrix.m13];
//    NSString *s3= [NSString stringWithFormat:@"%+2.2f,%+2.2f,%+2.2f,%+2.2f", matrix.m20,matrix.m21,matrix.m22,matrix.m23];
//    NSString *s4= [NSString stringWithFormat:@"%+2.2f,%+2.2f,%+2.2f,%+2.2f", matrix.m30,matrix.m31,matrix.m32,matrix.m33];
//    
//    NSLog(@" *** ORTHO[%@] ratio = %2.3f [%li,%li] matrix = \n [%@]\n [%@]\n [%@]\n [%@]", self, aspectRatio, [_internalTexture width], [_internalTexture height], s1, s2, s3, s4);

    return matrix;
}

- (id<MTLBuffer>) transformBuffer {
    DPTransformEncoder *mtrx = self.transform.encoder;
    
    if (!_transformBuffer) {        
        _transformBuffer = [self.context.device newBufferWithLength:[mtrx size] options:MTLResourceOptionCPUCacheModeDefault];
        _transformBuffer.label = @"Transform";
    }
        
    memcpy([_transformBuffer contents], [mtrx raw], [mtrx size]);

    
    return _transformBuffer;
}

- (id<MTLBuffer>) ortoMatrixBuffer{
    if (!_ortoMatrixBuffer) {
        _ortoMatrixBuffer = [self.context.device newBufferWithLength:sizeof(orthoMatrix) options:MTLResourceOptionCPUCacheModeDefault];
        _ortoMatrixBuffer.label = @"OrthoMatrix";
    }
    
    memcpy([_ortoMatrixBuffer contents], &orthoMatrix, sizeof(orthoMatrix));
    
    return _ortoMatrixBuffer;
}

-(id<MTLRenderPipelineState>) renderPipeline{
    @synchronized(self){
        if (!_renderPipeline) {
            
            MTLRenderPipelineDescriptor *renderPipeline = [MTLRenderPipelineDescriptor new];
            
            renderPipeline.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
            
            renderPipeline.vertexFunction   = [self.context.defaultLibrary newFunctionWithName:self.vertexFunction];
            renderPipeline.fragmentFunction = [self.context.defaultLibrary newFunctionWithName:self.fragmentFunction];
            
            _renderPipeline = [self.context.device newRenderPipelineStateWithDescriptor:renderPipeline error: nil];
        }
        
        return _renderPipeline;
    }
}

#pragma mark -
#pragma mark - executors

- (void) setSource:(DPImageProvider *)source{
    @synchronized(self){
        sourceTexture = nil;
        _source = source;
    }
}

- (void)applyRender
{
    sourceTexture = _source.texture;
    
    if (sourceTexture == nil) 
        return;    
    
    
    if (!renderPassDescriptor) {
        renderPassDescriptor = [MTLRenderPassDescriptor new];
    }
    
    NSUInteger width  = [sourceTexture width];
    NSUInteger height = [sourceTexture height];
        
    NSUInteger destWidth  = (NSUInteger)floor((CGFloat)width  * self.transform.resampleFactor);
    NSUInteger destHeight = (NSUInteger)floor((CGFloat)height * self.transform.resampleFactor);
    
    DPCropRegion region = self.transform.cropRegion;
    destWidth  -= destWidth * (region.left   + region.right);
    destHeight -= destHeight* (region.bottom + region.top);

    if ( !_texture ||
        [_texture width]  != destWidth ||
        [_texture height] != destHeight)
    {
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatRGBA8Unorm
                                                                                                     width:destWidth
                                                                                                    height:destHeight
                                                                                                 mipmapped:NO];
        _texture = [self.context.device newTextureWithDescriptor:textureDescriptor];
        
        renderPassDescriptor.colorAttachments[0].texture     = _texture;
        renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].clearColor =  MTLClearColorMake(1.0, 1.0, 1.0, 0.0);
        
        orthoMatrix = [self makeOrthoMatrixAspectRatio: self.transform.keepAspectRatio?((CGFloat)destHeight / (CGFloat)destWidth):1.0f];
    }
    
    id<MTLCommandBuffer> renderCommandBuffer = [self.context beginCommand];

    id<MTLRenderCommandEncoder> renderCommand = [renderCommandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    //
    // render current texture
    //
    
    [renderCommand setRenderPipelineState: self.renderPipeline];

    [renderCommand setVertexBuffer:        self.vertexBuffer     offset:0 atIndex:0];
    [renderCommand setVertexBuffer:        self.transformBuffer  offset:0 atIndex:1];
    [renderCommand setVertexBuffer:        self.ortoMatrixBuffer offset:0 atIndex:2];
    [renderCommand setFragmentTexture:     sourceTexture                   atIndex:0];
            
    [renderCommand drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
    
    [renderCommand endEncoding];
    
    [self.context commitCommand];
}

- (DPTextureRef)texture
{
    @synchronized(self){
        [self applyRender];
        return  _texture;
    }
}

- (void) flush{
    @synchronized(self){
        sourceTexture = nil;
        _texture = nil;
    }
}

- (void) dealloc{
    @synchronized(self){
        [self flush];
        _context = nil;
        _source = nil;
    }
}

@end
