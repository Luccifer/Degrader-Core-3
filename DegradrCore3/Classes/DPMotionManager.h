//
//  DPMotionManager.h
//  DPCamera
//
//  Created by iBo on 30/07/14.
//  Copyright (c) 2014 PSSD - Daniele Bogo. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  DPMotionManagerRotationHandler handles the current orientation
 */
typedef void (^DPMotionManagerRotationHandler)(UIDeviceOrientation);

static NSString *kMotionManagerRotationDidChangeNotification = @"kMotionManagerRotationDidChangeNotification";
static NSString *kMotionManagerPositionDidChangeNotification = @"kMotionManagerPositionDidChangeNotification";

/**
 *  DPMotionManager detect the orientation using CoreMotion
 */
@interface DPMotionManager : NSObject
/**
 *  The DPMotionManagerRotationHandler property
 */
@property (nonatomic, copy) DPMotionManagerRotationHandler motionRotationHandler;

/**
 *  The constructor method of
 *
 *  @return the DPMotionManager instancetype
 */
+ (instancetype) sharedManager;

/**
 *  Start to detect the rotation
 */
- (void) startMotionHandler;

- (void)pause;
- (void)resume;

@property (nonatomic, readonly) UIDeviceOrientation currentOrientation;

@end
