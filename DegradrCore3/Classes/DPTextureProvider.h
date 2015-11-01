//
//  DPTextureProvider.h
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPTexture.h"

@protocol MTLTexture;

/**
 *  Base texture provider protocol.
 */
@protocol DPTextureProvider <NSObject,DPContextProvider>

/**
 *  Reference to texutre object.
 */
@property (readwrite, strong, nonatomic) DPTextureRef texture;

/**
 *  Create new provider object.
 *
 *  @param aContext context processing.
 *
 *  @return provider instance object.
 */
- (instancetype) initWithContext:(DPContext*)aContext;
@end
