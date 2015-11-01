//
//  DPContext.m
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DPConstants.h"
#import "DPContext.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

static NSUInteger __shared_maximum_texture_size = 0;

@interface DPContext()
@property (nonatomic, assign) NSInteger              commandBufferRefs;
@property (nonatomic, strong) dispatch_queue_t       contextQueue;
@property (atomic,assign,getter=isDeferred)     BOOL deferred;
@property (nonatomic,readonly) id<MTLCommandBuffer>  commandBuffer;
@property (atomic,strong) NSMutableArray *bufferQueue;
@end

@implementation DPContext

@synthesize commandBuffer=_commandBuffer;

- (void) dealloc{
    for (id<MTLCommandBuffer> buffer in self.bufferQueue) {
        [buffer commit];
        [buffer waitUntilCompleted];
    }
    [self.bufferQueue removeAllObjects];
}

- (id<MTLCommandBuffer>) beginCommand{
    
    id<MTLCommandBuffer> buffer = [self.commandQueue commandBuffer];
    [self.bufferQueue addObject:buffer];
    return buffer;
    
}

- (void) commitCommand{
    
    id<MTLCommandBuffer> buffer = self.bufferQueue.lastObject;
    if (buffer){
        [self.bufferQueue removeLastObject];
        [buffer commit];
        
        if (!self.isDeferred)
            [buffer waitUntilCompleted];
    }
}

+ (instancetype)newLazyContext{
    DPContext *context = [self newContext];
    context.deferred = YES;
    return context;
}

+ (instancetype)newContext
{
    return [[self alloc] initWithDevice:nil];
}

+ (instancetype) new{
    return [self newContext];
}

- (instancetype) init {
    return [self initWithDevice:nil];
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        _device       = device ?: MTLCreateSystemDefaultDevice();
        
        _bufferQueue  = [NSMutableArray new];
        
        if (!_device)
            return nil;
        
        _deferred = NO;
        _commandQueue = [_device newCommandQueue];
        _defaultLibrary = [_device newDefaultLibrary];
        
        //_commandBufferRefs = 0;
    }
    return self;
}


+ (void) setMaximumTextureSize:(NSUInteger)size{
    __shared_maximum_texture_size = size;
}

+ (NSUInteger)maximumTextureSize
{
    if (__shared_maximum_texture_size>0) {
        return __shared_maximum_texture_size;
    }
    
    static dispatch_once_t pred;
    static GLint maxTextureSize = 0;
    
    dispatch_once(&pred, ^{
        EAGLContext *glContext =  [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        [EAGLContext setCurrentContext:glContext];
        
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        
        glContext = nil;
    });
    
    return (NSUInteger)maxTextureSize;
}

+ (CGSize)sizeTextureFitForSize:(CGSize)inputSize
{
    return [DPContext sizeTextureFitForSize:inputSize withMaxSize:(CGFloat)[self maximumTextureSize]];
}

+ (CGSize)sizeTextureFitForSize:(CGSize)inputSize withMaxSize:(CGFloat)maxSize
{
    CGFloat maxTextureSize = maxSize;
    if ( (inputSize.width < maxTextureSize) && (inputSize.height < maxTextureSize) )
    {
        return inputSize;
    }
    
    CGSize adjustedSize;
    if (inputSize.width > inputSize.height)
    {
        adjustedSize.width = (CGFloat)maxTextureSize;
        adjustedSize.height = ((CGFloat)maxTextureSize / inputSize.width) * inputSize.height;
    }
    else
    {
        adjustedSize.height = (CGFloat)maxTextureSize;
        adjustedSize.width = ((CGFloat)maxTextureSize / inputSize.height) * inputSize.width;
    }
    
    return adjustedSize;
}

- (dispatch_queue_t) contextQueue{
    if (!_contextQueue) {
        _contextQueue = dispatch_queue_create(DP_QUEUE_PREFIX"context.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _contextQueue;
}


@end
