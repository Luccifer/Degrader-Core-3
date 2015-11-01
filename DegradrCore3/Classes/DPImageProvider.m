//
//  DPBaseImageProvider.m
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPImageProvider.h"
#import "DPConstants.h"
#import "DPTransform.h"

#import <UIKit/UIKit.h>

#include <jconfig.h>
#include <jerror.h>
#include <jpeglib.h>
#include <errno.h>

@interface DPImageProvider()

@property (nonatomic, strong)   DPTransform                 *transform;

@property (nonatomic, strong)   id <MTLRenderPipelineState>  renderPipeline;
@property (nonatomic, strong)   id <MTLBuffer>               vertexBuffer;
@property (nonatomic, strong)   id <MTLBuffer>               ortoMatrixBuffer;
@property (nonatomic, strong)   id <MTLBuffer>               transformBuffer;

@property (nonatomic, strong)   NSString *vertexFunction;
@property (nonatomic, strong)   NSString *fragmentFunction;


@end

@implementation DPImageProvider
{
    DPContext      *_context;
    MTLRenderPassDescriptor *renderPassDescriptor;
    MTLPixelFormat          currentPixelFormat;
    GLKMatrix4 orthoMatrix;
}

@synthesize texture=_texture;

- (DPContext*) context{
    return _context;
}

+ (instancetype) newWithContext:(DPContext *)aContext{
    return [[[self class] alloc] initWithContext:aContext];
}

+ (instancetype) newWithTexture:(id<MTLTexture>)texture context:(DPContext *)aContext{
    return [[[self class] alloc] initWithTexture:texture context:aContext];
}

+ (instancetype) newWithProvider:(DPImageProvider *)provider{
    return [[[self class] alloc] initWithProvider:provider];
}

+ (instancetype) newWithTexture:(DPTextureRef)texture context:(DPContext *)aContext orientation:(UIImageOrientation)orientation{
    return [[[self class] alloc] initWithTexture:texture context:aContext orientation:orientation];
}

- (instancetype) initWithProvider:(DPImageProvider *)provider{
    self = [self initWithTexture:provider.texture context:provider.context];
    if (self) {
        self.imageOrientation = provider.imageOrientation;
    }
    return self;
}

- (instancetype) initWithTexture:(DPTextureRef)texture context:(DPContext *)aContext{
    return [self initWithTexture:texture context:aContext orientation:UIImageOrientationUp];
}

- (instancetype) initWithTexture:(DPTextureRef)texture context:(DPContext *)aContext orientation:(UIImageOrientation)orientation{
    self  = [super init];
    
    if (self) {
        if (texture) {
            currentPixelFormat = [texture pixelFormat];
        }
        else
            currentPixelFormat = MTLPixelFormatRGBA8Unorm;
        
        orthoMatrix = GLKMatrix4Identity;
        _imageOrientation = orientation;
        _context = aContext;
        _texture = texture;
    }
    
    return self;    
}

- (instancetype) initWithContext:(DPContext *)aContext{
    return [self initWithTexture:nil context:aContext];
}

+ (void) writeJpegWithProvider:(DPImageProvider*)provider
          writeInitBlock:(writeInitBlock)writeInitBlock
        writeFinishBlock:(writeFinishBlock)writeFinishBlock
                 quality:(CGFloat)qualityIn error:(NSError *__autoreleasing *)error{
    int quality = round(qualityIn*100.0f); quality=quality<=0?10:quality>100?100:quality;
    int q = (int)round(quality * 100.0f); q=(q<=0?10:q>=100?100:q);
    
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    
    JSAMPROW row_pointer[1];      /* pointer to JSAMPLE row[s] */
    int row_stride;               /* physical row width in image buffer */
    
    /* Step 1: allocate and initialize JPEG compression object */
    
    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    

    void *userData;
    if (!writeInitBlock(&cinfo,&userData)) {
        return;
    }
    
    /* Step 3: set parameters for compression */
    
    cinfo.image_width  = (int)[provider.texture width];      /* image width and height, in pixels */
    cinfo.image_height = (int)[provider.texture height];
    cinfo.input_components = 4;           /* # of color components per pixel */
    if (
        [provider.texture pixelFormat] == MTLPixelFormatBGRA8Unorm
        ||
        [provider.texture pixelFormat] == MTLPixelFormatBGRA8Unorm_sRGB
        ) {
        cinfo.in_color_space = JCS_EXT_BGRA;  /* colorspace of input image */        
    }
    else if (
             [provider.texture pixelFormat] == MTLPixelFormatRGBA8Unorm
             ||
             [provider.texture pixelFormat] == MTLPixelFormatRGBA8Unorm_sRGB
             ) {
        cinfo.in_color_space = JCS_EXT_RGBA;  /* colorspace of input image */        
    }
    
    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, quality, TRUE /* limit to baseline-JPEG values */);
    
    
    /* Step 4: Start compressor */
    
    jpeg_start_compress(&cinfo, TRUE);
        
    /* Step 5: while (scan lines remain to be written) */
    /*           jpeg_write_scanlines(...); */
    
    row_stride = (int)cinfo.image_width  * cinfo.input_components; /* JSAMPLEs per row in image_buffer */
    
    void       *image_buffer  = malloc(row_stride);
    
    while (cinfo.next_scanline < cinfo.image_height) {
        
        MTLRegion region = MTLRegionMake2D(0, cinfo.next_scanline, cinfo.image_width, 1);
        
        [provider.texture getBytes:image_buffer
                   bytesPerRow:row_stride
                    fromRegion:region
                   mipmapLevel:0];
        
        row_pointer[0] = image_buffer;
        (void) jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    
    free(image_buffer);
    
    
    /* Step 6: Finish compression */
    jpeg_finish_compress(&cinfo);
    
    /* After finish_compress, we can clear user data. */
    writeFinishBlock(&cinfo,userData);
    
    /* Step 7: release JPEG compression object */
    jpeg_destroy_compress(&cinfo);

}


- (void) writeJpegToFile:(NSString *)filePath quality:(CGFloat)qualityIn error:(NSError *__autoreleasing *)error{
    __block const char *filename = [filePath cStringUsingEncoding:NSUTF8StringEncoding];

    [[self class] writeJpegWithProvider:self
                         writeInitBlock:^BOOL(void *in_cinfo, void **userData) {
                             
                             struct jpeg_compress_struct *cinfo = in_cinfo;

                             FILE * outfile;               /* target file */
                             /* Step 2: specify data destination (eg, a file) */
                             if ((outfile = fopen(filename, "wb")) == NULL) {
                                 if (error) {
                                     *error = [[NSError alloc ] initWithDomain:@""DP_QUEUE_PREFIX"jpeg.write"
                                                                          code: ENOENT
                                                                      userInfo: @{
                                                                                  NSLocalizedDescriptionKey:  [NSString stringWithFormat:NSLocalizedString(@"Image file %@ can't be created", nil),filename],
                                                                                  NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"File can't be created", nil),
                                                                                  }];
                                 }
                                 return NO;
                             }
                             jpeg_stdio_dest(cinfo, outfile);
                             
                             *userData = outfile;
                             
                             return YES;
                             
                         } writeFinishBlock:^(void *cinfo, void *userData) {
                             /* After finish_compress, we can close the output file. */
                             fclose(userData);
                         } quality:qualityIn error:error
     ];
}

- (DPTransform*) transform{
    if (!_transform) {
        _transform = [DPTransform new];
    }
    return _transform;
}


- (id<MTLBuffer>) vertexBuffer{
    static float data[16] = {
        //x     y                     cordx                 coordy
        -1.0,  -1.0, /*left bottom*/  0.0, /*left offset*/  1.0, /* bottom offset*/
        +1.0,  -1.0, /*right bottom*/ 1.0, /*right offset*/ 1.0, /* bottom offset*/
        -1.0,  +1.0, /*left top*/     0.0, /*left offset*/  0.0, /* top offset*/
        +1.0,  +1.0, /*right top*/    1.0, /*right offset*/ 0.0, /* top offset*/
    };
    
    if (!_vertexBuffer) {
        _vertexBuffer = [self.context.device newBufferWithLength:sizeof(data) options:MTLResourceOptionCPUCacheModeDefault];
        _vertexBuffer.label = @"Vertices";
    }
    
    memcpy([_vertexBuffer contents], data, sizeof(data));
    return _vertexBuffer;
}

- (id<MTLBuffer>) transformBuffer {
    if (!_transformBuffer) {
        DPTransformEncoder *mtrx = self.transform.encoder;
        _transformBuffer = [self.context.device newBufferWithLength:[mtrx size] options:MTLResourceOptionCPUCacheModeDefault];
        _transformBuffer.label = @"Transform";
        memcpy([_transformBuffer contents], [mtrx raw], [mtrx size]);
    }
    return _transformBuffer;
}

- (id<MTLBuffer>) ortoMatrixBuffer{
    if (!_ortoMatrixBuffer) {
        _ortoMatrixBuffer = [self.context.device newBufferWithLength:sizeof(orthoMatrix) options:MTLResourceOptionCPUCacheModeDefault];
        _ortoMatrixBuffer.label = @"OrthoMatrix";
        memcpy([_ortoMatrixBuffer contents], &orthoMatrix, sizeof(orthoMatrix));
    }
    return _ortoMatrixBuffer;
}

-(id<MTLRenderPipelineState>) renderPipeline{
    if (!_renderPipeline) {
        
        MTLRenderPipelineDescriptor *renderPipeline = [MTLRenderPipelineDescriptor new];
        
        renderPipeline.colorAttachments[0].pixelFormat = currentPixelFormat;
        
        renderPipeline.vertexFunction   = [self.context.defaultLibrary newFunctionWithName:DP_VERTEX_DEF_FUNCTION];
        renderPipeline.fragmentFunction = [self.context.defaultLibrary newFunctionWithName:DP_FRAGMENT_DEF_FUNCTION];
        
        _renderPipeline = [self.context.device newRenderPipelineStateWithDescriptor:renderPipeline error: nil];
    }
    
    return _renderPipeline;
}

- (void) transformOrientation:(UIImageOrientation)orientation{
    
    id<MTLCommandBuffer> renderCommandBuffer = [self.context.commandQueue commandBuffer];
    
    if (!renderPassDescriptor) {
        renderPassDescriptor = [MTLRenderPassDescriptor new];
    }
    
    DPTextureRef inputTexture = self.texture;
    
    NSUInteger width  = [inputTexture width];
    NSUInteger height = [inputTexture height];
    
    NSUInteger destWidth  = (NSUInteger)floor((CGFloat)width  * self.transform.resampleFactor);
    NSUInteger destHeight = (NSUInteger)floor((CGFloat)height * self.transform.resampleFactor);
    
    DPTransform *transform = [DPTransform new];
    BOOL         changeAspectRatio = NO;
    
    //
    // Normalize
    //
    switch (self.imageOrientation) {
            
        case UIImageOrientationLeftMirrored:
            [transform flipVertical];
        case UIImageOrientationLeft:
            [transform rotateLeft];
            changeAspectRatio = YES;
            break;
            
        case UIImageOrientationRightMirrored:
            [transform flipVertical];
        case UIImageOrientationRight:
            [transform rotateRight];
            changeAspectRatio = YES;
            break;
            
        case UIImageOrientationDownMirrored:
            [transform flipHorizontal];
        case UIImageOrientationDown:
            [transform rotate180];
            break;
            
        case UIImageOrientationUpMirrored:
            [transform flipHorizontal];
            break;

        default:
            break;
    }
    
    //
    // change orientation
    //
    switch (orientation) {
        
        case UIImageOrientationLeftMirrored:
            [transform flipVertical];
        case UIImageOrientationLeft:
            changeAspectRatio = !changeAspectRatio;
            [transform rotateLeft];
            break;

        case UIImageOrientationRightMirrored:
            [transform flipVertical];
        case UIImageOrientationRight:
            [transform rotateRight];
            changeAspectRatio = !changeAspectRatio;
            break;
        
        case UIImageOrientationDownMirrored:
            [transform flipHorizontal];
        case UIImageOrientationDown:
            [transform rotate180];
            break;
            
        case UIImageOrientationUpMirrored:
            [transform flipHorizontal];
            break;
            
        default:
            break;
    }
    
    if (changeAspectRatio) {
        NSUInteger h = destHeight;
        destHeight = destWidth;
        destWidth = h;
    }
    
    self.transform = transform;
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: [inputTexture pixelFormat]
                                                                                                 width:destWidth
                                                                                                height:destHeight
                                                                                             mipmapped:NO];
    self.texture = [self.context.device newTextureWithDescriptor:textureDescriptor];
    
    renderPassDescriptor.colorAttachments[0].texture     = self.texture;
    renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor =  MTLClearColorMake(1.0, 1.0, 1.0, 0.0);
    
    
    id<MTLRenderCommandEncoder> renderCommand = [renderCommandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    //
    // render current texture
    //
    
    if (currentPixelFormat != [inputTexture pixelFormat]) {
        currentPixelFormat = [inputTexture pixelFormat];
        _renderPipeline = nil;
    }
    
    [renderCommand setRenderPipelineState: self.renderPipeline];
    
    [renderCommand setVertexBuffer:        self.vertexBuffer     offset:0 atIndex:0];
    [renderCommand setVertexBuffer:        self.transformBuffer  offset:0 atIndex:1];
    [renderCommand setVertexBuffer:        self.ortoMatrixBuffer offset:0 atIndex:2];
    [renderCommand setFragmentTexture:     inputTexture                   atIndex:0];
    
    [renderCommand setViewport:(MTLViewport){0,0,[self.texture width],[self.texture height], 0, 1}];
    
    [renderCommand drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
    
    [renderCommand endEncoding];
    
    [renderCommandBuffer commit];
    [renderCommandBuffer waitUntilCompleted];
        
    self.imageOrientation = orientation;
    
    self.texture = inputTexture;    
}

- (void) setTexture:(DPTextureRef)texture{
    _texture=texture;
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageProvider:didUpdateAtTime:)]) {
        [self.delegate imageProvider:self didUpdateAtTime:CMTimeMakeWithSeconds([NSDate timeIntervalSinceReferenceDate], 1)];
    }
}

@end

