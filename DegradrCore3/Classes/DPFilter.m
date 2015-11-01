//
//  DPFilter.m
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//
#import <objc/runtime.h>
#import <objc/message.h>

#import "DPFilter.h"
#import "DPRender.h"
#import "DPImageProvider.h"

@interface DPFilter() <DPImageProviderDelegate, DPTransformDelegate>

@property (nonatomic, strong)   DPContext       *context;
@property (nonatomic, strong)   DPRender        *renderPass;

@property (nonatomic, strong)   NSMutableArray  *functionListPrivate;
@property (nonatomic, strong)   NSMutableArray  *filterListPrivate;

@property (nonatomic, strong)   DPTextureRef    destinationTexture;

@end


@implementation DPFilter
{
    NSString *vertexFunctionName;
    NSString *fragmentFunctionName;
    DPTextureRef inputTexture;
}

@synthesize texture = _texture;
@synthesize destination = _destination;
@synthesize source = _source;
@synthesize transform = _transform;
@synthesize functionThreads = _functionThreads;
@synthesize disabled = _disabled;
@synthesize dirty = _dirty;

#pragma mark -
#pragma mark - Construtors

+ (instancetype) newWithContext:(DPContext *)aContext{
    return [[self alloc] initWithContext:aContext];
}

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super init];
    
    if (self) {
        _dirty = YES;
        _context    = aContext;
        vertexFunctionName = nil;
        fragmentFunctionName = nil;
        _renderPass = nil;
    }
    
    return self;
}

- (instancetype) initWithVertex:(NSString *)vertexFunction withFragment:(NSString *)fragmentFunction context:(DPContext *)aContext{
    self = [super init];
    
    if (self) {
        _dirty = YES;
        _context    =  aContext;
        _renderPass = [[DPRender alloc] initWithVertex:vertexFunctionName=vertexFunction withFragment:fragmentFunctionName=fragmentFunction context:_context];
    }
    
    return self;
}


#pragma mark -
#pragma mark - Getters/Setters

- (NSUInteger) functionThreads{
    if (_functionThreads==0)
        _functionThreads = 16;
    else if (_functionThreads>16)
        _functionThreads = 16;
    
    return _functionThreads;
}

- (void) setFunctionThreads:(NSUInteger)functionThreads{
    _functionThreads = functionThreads;
    for (DPFilter *filter in self.filterList) {
        filter.functionThreads = _functionThreads;
    }
}

- (DPContext*) context{
    return _context;
}

- (NSMutableArray*) functionListPrivate{
    if (!_functionListPrivate) {
        _functionListPrivate = [NSMutableArray new];
    }
    
    return _functionListPrivate;
}

- (NSMutableArray*) filterListPrivate{
    if (!_filterListPrivate) {
        _filterListPrivate = [NSMutableArray new];
    }
    return _filterListPrivate;
}

- (void) setTransform:(DPTransform *)transform{
    @synchronized(self) {
        [self willChangeValueForKey:@"transform"];
        if (self.renderPass) {
            self.renderPass.transform = transform;
            self.renderPass.transform.delegate = self;
            _transform = self.renderPass.transform;
        }
        else{
            _transform = transform;
            _transform.delegate = self;
        }
        self.dirty = YES;
        [self didChangeValueForKey:@"transform"];
    }
}

- (DPTransform*) transform{
    @synchronized(self){
        if (!_transform) {
            if (self.renderPass) {
                _transform = self.renderPass.transform;
                _transform.delegate = self;
            }
            else{
                _transform = [DPTransform new];
                _transform.delegate = self;
            }
        }
        return _transform;
    }
}

#pragma mark -
#pragma mark - Iterators

- (NSArray*) functionList{
    return self.functionListPrivate;
}

- (NSArray*) filterList{
    return self.filterListPrivate;
}

- (void) addFunction:(DPFunction *)function{
    @synchronized(self) {
        if (function) {
            [self.functionListPrivate addObject:function];
        }
        self.dirty = YES;
    }
}

- (void) removeFunction:(DPFunction *)function{
    @synchronized(self) {
        if (function) {
            [self.functionListPrivate removeObject:function];
        }
        self.dirty = YES;
    }
}

- (void) addFilter:(DPFilter *)filter{
    @synchronized(self) {
        if (filter) {
            [self.filterListPrivate addObject:filter];
        }
        self.dirty = YES;
    }
}

- (void) removeFilter:(DPFilter *)filter{
    @synchronized(self) {
        if (filter) {
            [self.filterListPrivate removeObject:filter];
        }
        self.dirty = YES;
    }
}

- (void) removeAllFilters{
    @synchronized(self) {
        [self.filterListPrivate removeAllObjects];
        self.dirty = YES;
    }
}

#pragma mark -
#pragma mark - executors


- (void) applyFiltersFromList{
    UIImageOrientation orientation = self.source.imageOrientation;
    for (DPFilter *filter in self.filterList) {
        if (!filter.source) {
            filter.source = [DPImageProvider newWithTexture:_texture context:self.context orientation:orientation];
        }
        else{
            filter.source.texture = _texture;
            filter.source.imageOrientation = orientation;
        }
        _texture = filter.texture;
    }
}

- (void) setDisabled:(BOOL)disabled{
    _disabled = disabled;
    self.dirty = YES;
}

- (void)applyFilter
{
    
    if (self.source.texture == nil)
        return;
    
    CGFloat resampleFactor = 1.0;
    
    id<MTLCommandBuffer> commandBuffer;
    
    if (self.renderPass) {
        commandBuffer = [self.context beginCommand];
        
        if (self.functionList.count == 0 || self.isDisabled) {
            
            //
            // optimize rendering, ingnore kernel function
            //
            
            self.renderPass.source = self.source;
            
            _texture = self.renderPass.texture;
            
            [self.context commitCommand];
            
            if (self.isDisabled) {
                self.dirty = NO;
                return;
            }
            
            [self applyFiltersFromList];
            
            self.dirty = NO;
            
            if (_didFinishFiltering) {
                _didFinishFiltering([self currentDestination]);
            }
            
            return;
        }
        else{
            
            //
            // both rendering and filtering proccess
            //
            
            self.renderPass.source = self.source;
            inputTexture = self.renderPass.texture;
        }
    }
    else{
        
        //
        // only filtering
        //
        
        inputTexture = self.source.texture;
        resampleFactor = self.transform.resampleFactor;
    }
    
    if (self.isDisabled) {
        _texture = inputTexture;
        self.dirty = NO;
        return;
    }
    
    
    if (inputTexture == nil) {
        self.dirty = NO;
        return;
    }
    
    DPTextureRef texture = nil;
    
    for (DPFunction *function in self.functionList) {
        
        NSUInteger input_width  = [inputTexture width];
        NSUInteger input_height = [inputTexture height];
        NSUInteger width  = floor ((float)(input_width) * function.resampleFactor.x * resampleFactor);
        NSUInteger height = floor ((float)(input_height) * function.resampleFactor.y * resampleFactor);
        
        MTLSize threadgroupCounts = MTLSizeMake(self.functionThreads, self.functionThreads, 1);
        MTLSize threadgroups = MTLSizeMake(
                                           (width + threadgroupCounts.width ) / threadgroupCounts.width ,
                                           (height+ threadgroupCounts.height) / threadgroupCounts.height,
                                           1);
        
        if (!_texture ||
            [_texture width]  != width ||
            [_texture height] != height)
        {
            MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                         width:width
                                                                                                        height:height
                                                                                                     mipmapped:NO];
            texture = [self.context.device newTextureWithDescriptor:textureDescriptor];
            
        }
        else
            texture=_texture;
        
        if (commandBuffer) [self.context commitCommand];
        
        commandBuffer = [self.context beginCommand];
        
        id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
        
        [commandEncoder setComputePipelineState:function.pipeline];
        
        [commandEncoder setTexture:inputTexture atIndex:0];
        [commandEncoder setTexture:texture atIndex:1];
        
        if ([self respondsToSelector:@selector(configureFunction:uniform:)]) {
            [self configureFunction:function uniform:commandEncoder];
        }
        
        if ([self respondsToSelector:@selector(configureBlitUniform:)]) {
            id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
            [self configureBlitUniform: blitEncoder];
        }
        [commandEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupCounts];
        [commandEncoder endEncoding];
        
        inputTexture = texture;
    }
    
    [self.context commitCommand];
    
    if (!texture) {
        _texture = self.source.texture;
    }
    else
        _texture = texture;
    
    [self applyFiltersFromList];
    
    self.dirty = NO;
    
    if (_didFinishFiltering) {
        _didFinishFiltering([self currentDestination]);
    }
}

- (void) apply{
    if (self.isDirty) {
        if (!self.isDisabled && _willStartProcessing) {
            _willStartProcessing(self.source);
        }
        [self applyFilter];
    }
}

- (void) imageProvider:(DPImageProvider *)provider didUpdateAtTime:(CMTime)time{
    self.dirty = YES;
}


- (void) transform:(DPTransform *)transform didUpdateAtTime:(CMTime)time{
    self.dirty = YES;
    for (DPFilter *filter in self.filterList) {
        if (filter.transform.delegate && [filter.transform.delegate respondsToSelector:@selector(transform:didUpdateAtTime:)]) {
            [filter.transform.delegate transform:transform didUpdateAtTime:time];
        }
    }
}

- (DPTextureRef) texture
{
    [self apply];
    return  _texture;
}

- (DPImageProvider*) currentDestination{
    if (!_destination) {
        _destination = [DPImageProvider newWithTexture:_texture context:self.context orientation:self.source.imageOrientation];
    }
    else{
        _destination.texture = _texture;
        _destination.imageOrientation = self.source.imageOrientation;
    }
    return _destination;
}

- (DPImageProvider*) destination{
    if (!_destination) {
        _destination = [DPImageProvider newWithTexture:self.texture context:self.context orientation:self.source.imageOrientation];
    }
    else{
        _destination.texture = self.texture;
        _destination.imageOrientation = self.source.imageOrientation;
    }
    return _destination;
}

- (DPTextureRef) destinationTexture{
    return _texture;
}

- (void) setSource:(DPImageProvider *)source{
    if (_source!=source) {
        _source = source;
        if(!_source.delegate) _source.delegate = self;
    }
    self.dirty = YES;
}

- (void) setTexture:(DPTextureRef)texture{
    if (_source.texture!=texture) {
        if (_source){
            _source.texture  = texture;
            self.source = _source;
        }
        else{
            self.source = [DPImageProvider newWithTexture:texture context:self.context];
            self.source.delegate = self;
        }
    }
    self.dirty = YES;
}

- (BOOL) isDirty{
    return _dirty;
}

- (void)setDirty:(BOOL)dirty{
    _dirty=dirty;
    for (DPFilter *filter in self.filterList) {
        filter.dirty=_dirty;
    }
}

- (void) flush{
    @synchronized(self){
        [self __flush];
        self.dirty = YES;
    }
}

- (void) __flush{
    for (DPFilter *filter in self.filterList) {
        [filter __flush];
    }
    [_renderPass flush];
    inputTexture = nil;
    _source = nil;
}

- (void) dealloc{
    [self __flush];
    _context = nil;
    _source = nil;
    _destination = nil;
    _texture = nil;
}

@end
