//
//  DPFilter.h
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//
//
//  Acknowledgement:
//  http://www.sunsetlakesoftware.com/ - the famous great work for Image Processing with GPU 
//  A lot of ideas were taken from the Brad Larson project: https://github.com/BradLarson/GPUImage
//
//
//

#import <Foundation/Foundation.h>
#import "DPImageProvider.h"
#import "DPFunction.h"
#import "DPRender.h"
#import "DPTypes.h"
#import "DPMath.h"


@class DPFilter;

/**
 *  Filter configuration protocol.
 */
@protocol DPFilterProtocol <NSObject>

@optional
/**
 *  Configure kernel function with specific options.
 *
 *  @param function       kernel function string name
 *  @param commandEncoder current command encoder
 */
- (void) configureFunction:(DPFunction*)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder;

/**
 * Configure blit encoder
 *
 */
- (void) configureBlitUniform:(id<MTLBlitCommandEncoder>)commandEncoder;

@end

/**
 *  Base image processing filter.
 */
@interface DPFilter : NSObject <DPTextureProvider,DPContextProvider,DPFilterProtocol>

+ (instancetype) newWithContext:(DPContext *)aContext;
- (instancetype) initWithContext:(DPContext *)aContext;
- (instancetype) initWithVertex:(NSString*)vertexFunction withFragment:(NSString*)fragmentFunction context:(DPContext *)aContext;

@property (nonatomic, assign, getter=isDisabled) BOOL disabled;

@property (atomic, assign, getter=isDirty)       BOOL dirty;

/**
 *  Input texture provider.
 */
@property (nonatomic, strong)   DPImageProvider       *source;

/**
 * Destination provider
 */
@property (nonatomic, readonly) DPImageProvider       *destination;

/**
 *  Current functions configured to apply filter proccess.
 */
@property (nonatomic, readonly) NSArray               *functionList;

/**
 *  Current filters configured to make some additional functions.
 */
@property (nonatomic, readonly) NSArray               *filterList;

/**
 *  The transformation of the input texture.
 */
@property (nonatomic, strong)   DPTransform           *transform;

/**
 *  Handle texture proccessing within filtering pipeline.
 */
@property (nonatomic, copy)     processImageProvider  willStartProcessing;
@property (nonatomic, copy)     processImageProvider  didFinishFiltering;

/**
 *  To manage processing perfomance you can set count of threads to parallelizes the process.
 */
@property (nonatomic, assign)   NSUInteger            functionThreads;

//
// Filter configuration
//
- (void) addFunction:(DPFunction*)function;
- (void) removeFunction:(DPFunction*)function;

- (void) addFilter:(DPFilter*)filter;
- (void) removeFilter:(DPFilter*)filter;
- (void) removeAllFilters;

- (void) apply;
- (void) flush;

@end
