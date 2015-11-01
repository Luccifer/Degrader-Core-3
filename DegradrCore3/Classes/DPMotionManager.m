//
//  DPMotionManager.m
//  DPCamera
//
//  Created by iBo on 30/07/14.
//  Copyright (c) 2014 PSSD - Daniele Bogo. All rights reserved.
//

#import "DPMotionManager.h"

#import <CoreMotion/CoreMotion.h>

@interface DPMotionManager () {
	CMAccelerometerHandler _motionHandler;
}

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) UIDeviceOrientation lastOrientation;
@property (nonatomic, readwrite) UIDeviceOrientation currentOrientation;

@property (nonatomic, assign) CGFloat lastX;
@property (nonatomic, assign) CGFloat lastY;
@property (nonatomic, assign) CGFloat lastZ;
@property (nonatomic, assign) CGFloat lastDistance;
@property (nonatomic, assign) BOOL    skipMotionData;

@end

@implementation DPMotionManager

- (CMMotionManager *) motionManager
{
    if ( !_motionManager ) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    
    return _motionManager;
}

+ (instancetype) sharedManager
{
    static DPMotionManager *sharedManager = nil;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        sharedManager = [[DPMotionManager alloc] init];
    });
    
    return sharedManager;
}

- (id) init
{
    self = [super init];
    
    if ( self ) {
        
        _currentOrientation = UIDeviceOrientationPortrait;
        _skipMotionData = NO;
        
        if ( [self.motionManager isAccelerometerAvailable] ) {
            [self.motionManager setAccelerometerUpdateInterval:.2f];
        } else {
            [self deviceOrientationDidChangeTo:UIDeviceOrientationFaceDown];
        }
    }
    
    return self;
}

- (void) startMotionHandler
{
    __weak typeof(self) weakSelf = self;
	_motionHandler = ^ (CMAccelerometerData *accelerometerData, NSError *error) {

        if (weakSelf.skipMotionData) {
            return;
        }
        
        typeof(self) selfBlock = weakSelf;
        
		CGFloat xx = accelerometerData.acceleration.x;
		CGFloat yy = -accelerometerData.acceleration.y;
		CGFloat zz = accelerometerData.acceleration.z;
        
        //CGFloat distance = sqrt(pow((weakSelf.lastX - xx), 2) + pow(weakSelf.lastY + yy, 2) + pow(weakSelf.lastZ - zz, 2));
        CGFloat distance = sqrt(pow((weakSelf.lastX - xx), 2) + pow(weakSelf.lastY + yy, 2));
        
        //NSLog(@" *** motion [%f,%f,%f] d = %f", xx,yy,zz, distance);
        
        if (ABS(weakSelf.lastDistance - distance) > 0.1f) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMotionManagerPositionDidChangeNotification
                                                                object:weakSelf
                                                              userInfo:@{@"distance": @(ABS(weakSelf.lastDistance - distance))}];
            
            weakSelf.lastX = accelerometerData.acceleration.x;
            weakSelf.lastY = accelerometerData.acceleration.y;
            weakSelf.lastZ = accelerometerData.acceleration.z;
            weakSelf.lastDistance = distance;
        }
        
		CGFloat device_angle = M_PI / 2.0f - atan2(yy, xx);
		UIDeviceOrientation orientation = UIDeviceOrientationUnknown;
        
		if (device_angle > M_PI)
            device_angle -= 2 * M_PI;
        
		if ((zz < -.60f) || (zz > .60f)) {
			if ( UIDeviceOrientationIsLandscape(selfBlock.lastOrientation) )
				orientation = selfBlock.lastOrientation;
			else
				orientation = UIDeviceOrientationUnknown;
		} else {
			if ( (device_angle > -M_PI_4) && (device_angle < M_PI_4) )
				orientation = UIDeviceOrientationPortrait;
			else if ((device_angle < -M_PI_4) && (device_angle > -3 * M_PI_4))
				orientation = UIDeviceOrientationLandscapeLeft;
			else if ((device_angle > M_PI_4) && (device_angle < 3 * M_PI_4))
				orientation = UIDeviceOrientationLandscapeRight;
			else
				orientation = UIDeviceOrientationPortraitUpsideDown;
		}
        
		if (orientation != selfBlock.lastOrientation) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[selfBlock deviceOrientationDidChangeTo:orientation];
			});
        }
	};
    
	[self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:_motionHandler];
}

- (void)pause {
    _skipMotionData = YES;
}

- (void)resume {
    _skipMotionData = NO;
}

- (void) deviceOrientationDidChangeTo:(UIDeviceOrientation)orientation
{
    [self setLastOrientation:orientation];
    
    if (_currentOrientation == orientation) {
        return;
    } else {
        if ((orientation == UIDeviceOrientationPortrait) ||
            (orientation == UIDeviceOrientationPortraitUpsideDown) ||
            (orientation == UIDeviceOrientationLandscapeLeft) ||
            (orientation == UIDeviceOrientationLandscapeRight)) {
            
            _currentOrientation = orientation;
        }
    }

    if (self.motionRotationHandler) {
        self.motionRotationHandler(self.lastOrientation);
    } else {
        if ([[[UIDevice currentDevice] name] isEqualToString:@"iPhone Simulator"] == NO) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMotionManagerRotationDidChangeNotification
                                                                object:self
                                                              userInfo:@{@"orientation": @(self.lastOrientation)}];
        } else {
            _currentOrientation = UIDeviceOrientationPortrait;
            _lastOrientation = UIDeviceOrientationPortrait;

            [[NSNotificationCenter defaultCenter] postNotificationName:kMotionManagerRotationDidChangeNotification
                                                                object:self
                                                              userInfo:@{@"orientation": @(self.lastOrientation)}];
        }
    }
}

@end
