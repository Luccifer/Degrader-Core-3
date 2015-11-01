//
//  DPRenderPass.h
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPImageProvider.h"
#import "DPFunction.h"
#import "DPTransform.h"

/**
 *  Geometry pass renderer applies crop,tranformations and image object translations.
 */
@interface DPRender : NSObject<DPTextureProvider, DPContextProvider>

/**
 *  New renderer.
 *
 *  @param aContext processing context.
 */
+ (instancetype) newWithContext:(DPContext *)aContext;
- (instancetype) initWithContext:(DPContext *)aContext;

/**
 *  Initialize renderer with vertex and fragment function defined in default library.
 *
 *  @param vertexFunction   vertex function string name
 *  @param fragmentFunction fragment function string name
 *  @param aContext         processing context
 */
- (instancetype) initWithVertex:(NSString*)vertexFunction withFragment:(NSString*)fragmentFunction context:(DPContext *)aContext;

/**
 *  Input image texture.
 */
@property (nonatomic,strong)   DPImageProvider       *source;

/**
 *  Transformation commands.
 */
@property (nonatomic, strong)  DPTransform           *transform;

/**
 *  Flush renderer data. After flushing any operation is undefined.
 */
- (void) flush;

@end
