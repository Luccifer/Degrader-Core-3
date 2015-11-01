//
//  DPContext.h
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>


typedef void (^DPCommandBufferBlock)(id<MTLCommandBuffer>);

/**
 * DPContext is the base processing context keeper. 
 * The all image processing objects should be bound with an instance of the context.
 */
@interface DPContext : NSObject

/**
 *  The GPU device.
 */
@property (atomic,readonly)    id<MTLDevice>        device;

/**
 *  Queue of commands device proccess'.
 */
@property (nonatomic,readonly) id<MTLCommandQueue>   commandQueue;

@property (nonatomic,readonly) dispatch_queue_t     contextQueue;

@property (atomic,readonly)   id<MTLLibrary>        defaultLibrary;

/**
 *  Create new context.
 *
 *  @return new context instance.
 */
+ (instancetype) newContext;
+ (instancetype) newLazyContext;
- (instancetype) initWithDevice:(id<MTLDevice>)device;

/**
 *  Maximum texture size that GPU device can proccess by one pass.
 *
 *  @return pixels count 
 */
+ (NSUInteger)   maximumTextureSize;

/**
 *  Limit by self maximum texture size.
 *
 *  @param size pixels count
 */
+ (void)         setMaximumTextureSize:(NSUInteger)size;

/**
 *  Adjust GCSize to maximum allowed texture size.
 *
 *  @param inputSize CGSize of input texture.
 *
 *  @return adjusted size.
 */
+ (CGSize)       sizeTextureFitForSize:(CGSize)inputSize;
+ (CGSize)       sizeTextureFitForSize:(CGSize)inputSize withMaxSize:(CGFloat)maxSize;

- (id<MTLCommandBuffer>) beginCommand;
- (void) commitCommand;

@end


@protocol DPContextProvider <NSObject>
@property (nonatomic,readonly) DPContext *context;
@end