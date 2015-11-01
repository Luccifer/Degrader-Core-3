//
//  DPFunction.h
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPMath.h"

#import "DPTypes.h"
#import "DPContext.h"

/**
 * The base image proccesing unit.
 * DPFunction manage processing context and apply rules from Metal Shading Language (MShL) file.
 */
@interface DPFunction : NSObject<DPContextProvider>

/**
 *  Kernel function object.
 */
@property (nonatomic, readonly) id<MTLFunction>             kernel;

/**
 *  Kernel library object contains MShL.
 */
@property (nonatomic, readonly) id<MTLLibrary>              library;
/**
 *  Compute pipeline.
 */
@property (nonatomic, readonly) id<MTLComputePipelineState> pipeline;
/**
 *  Function name defines in MShL.
 */
@property (nonatomic, readonly) NSString                    *name;

/**
 *  Create new Kernel processing function from default library, in defined processing context.
 *
 *  @param functionName function name string
 *  @param context      processing context.

 */
+ (instancetype) newFunction:(NSString *)functionName context:(DPContext *)context;

/**
 *  Create new Kernel processing function from source, in defined processing context.
 *
 *  @param functionName function name 
 *  @param source       MShL string
 *  @param context      processing context
 */
+ (instancetype) newFunction:(NSString *)functionName withLibrarySource:(NSString*)source context:(DPContext *)context;
- (instancetype) initWithFunctionName:(NSString *)functionName context:(DPContext *)context;
- (instancetype) initWithFunctionName:(NSString *)functionName withLibrarySource:(NSString*)source context:(DPContext *)context;

@property (nonatomic,assign) DPVector2 resampleFactor;

@end
