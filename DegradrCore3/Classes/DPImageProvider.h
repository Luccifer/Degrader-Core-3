//
//  DPBaseImageProvider.h
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DPTextureProvider.h"

typedef BOOL (^writeInitBlock)(void *cinfo, void **userData);
typedef void (^writeFinishBlock)(void *cinfo, void *userData);

@class DPImageProvider;

@protocol DPImageProviderDelegate <NSObject>

- (void) imageProvider:(DPImageProvider*)provider didUpdateAtTime:(CMTime)time;

@end

typedef void (^updateAtTimeBlock)(CMTime);

/**
 *  Base image povider.
 */
@interface DPImageProvider : NSObject<DPTextureProvider>

/**
 * Original image orientation
 */
@property (nonatomic, assign) UIImageOrientation imageOrientation;

@property (nonatomic,strong) id<DPImageProviderDelegate> delegate;

/**
 * Transform image orientation from origin imageOrientation to target orientation and set origin to UIImageOrientationUp
 * It uses to fix image orientation to normal portrate or landscape.
 */
- (void) transformOrientation:(UIImageOrientation)orientation;

/**
 *  Create new empty provider.
 *
 *  @param aContext processing context
 */
+ (instancetype) newWithContext:(DPContext*)aContext;

/**
 *  Create new provider with existed texture.
 *
 *  @param texture  texture
 *  @param aContext processing context
 */
+ (instancetype) newWithTexture:(DPTextureRef)texture context:(DPContext*)aContext;
+ (instancetype) newWithTexture:(DPTextureRef)texture context:(DPContext*)aContext orientation:(UIImageOrientation)orientation;

/**
 *  Create new provider with existed texture.
 *
 *  @param provider provider
 */
+ (instancetype) newWithProvider:(DPImageProvider*)provider;

/**
 *  Initialize provider with existed texture.
 *
 *  @param texture  texture
 *  @param aContext processing context
 *
 *  @return instance
 */
- (instancetype) initWithTexture:(DPTextureRef)texture context:(DPContext *)aContext;
- (instancetype) initWithTexture:(DPTextureRef)texture context:(DPContext *)aContext orientation:(UIImageOrientation)orientation;

/**
 *  Initialize provider with existed provider.
 *
 *  @param provider 
 *  @param aContext processing context
 *
 *  @return instance
 */
- (instancetype) initWithProvider:(DPImageProvider*)provider;


/**
 *  Write texture to jpeg file.
 *
 *  @param filePath file path
 *  @param quality  jpeg quality: 0-1
 *  @param error    error description if handled or nill
 */
- (void) writeJpegToFile:(NSString*)filePath quality:(CGFloat)quality error:(NSError**)error;
+ (void) writeJpegWithProvider:(DPImageProvider*)provider
                writeInitBlock:(writeInitBlock)writeInitBlock
              writeFinishBlock:(writeFinishBlock)writeFinishBlock
                       quality:(CGFloat)qualityIn error:(NSError *__autoreleasing *)error;

@end
