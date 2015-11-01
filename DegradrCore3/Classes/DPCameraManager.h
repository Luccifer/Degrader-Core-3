//
//  DPCameraManager.h
//  DegraderCoreNew
//
//  Created by denn on 07.02.15.
//  Copyright (c) 2015 degrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>
#import <Accelerate/Accelerate.h>

#import "DPConstants.h"
#import "DPFilter.h"
#import "DPLiveView.h"

static const NSUInteger kDPCameraFrameRateDefault = kDP_LiveViewFrameRate;

@class DPCameraManager;

typedef void (^capturingCompleteBlock)(BOOL finished, NSString *filePath, NSDictionary *metadata);
typedef void (^exposureCompleteBlock)(DPCameraManager *cameraManager);
typedef void (^focusCompleteBlock)(DPCameraManager *cameraManager);
typedef void (^cameraReadyBlock)(void);

/**
 *  DPCameraManager is a ...
 */
@interface DPCameraManager : NSObject<DPContextProvider>

/**
 * Create an instance of manager with base UIView container.
 */
- (id)   initWithOutputContainerPreview:(UIView*)containerPreview;

/**
 * Create an instance of manager with base UIView container and down scale every frame with scale factor.
 */
- (id)   initWithOutputContainerPreview:(UIView*)containerPreview withDownscaleFactor:(CGFloat)scale;

@property (nonatomic,copy)   capturingCompleteBlock  capturingCompleteBlock;

@property (nonatomic,readonly) DPLiveView   *liveView;
@property (nonatomic,strong) DPFilter       *liveViewFilter;
@property (nonatomic,assign) CGFloat        downScaleFactor;
@property (nonatomic,assign) CGFloat        compressionQuality;
@property (nonatomic,assign) BOOL           hardwareCompression;

@property (nonatomic,copy)   focusCompleteBlock     focusWillChange;
@property (nonatomic,copy)   focusCompleteBlock     focusDidChange;

@property (nonatomic,copy)   exposureCompleteBlock  exposureWillChange;
@property (nonatomic,copy)   exposureCompleteBlock  exposureDidChange;

@property (nonatomic,copy)   cameraReadyBlock cameraWillReadyBlock;
@property (nonatomic,copy)   cameraReadyBlock cameraDidReadyBlock;
@property (nonatomic,copy)   cameraReadyBlock cameraDidStopBlock;

@property (nonatomic,copy)   cameraReadyBlock liveViewDidReadyBlock;

@property (nonatomic,copy)   cameraReadyBlock cameraWillCapturePhotoBlock;
@property (nonatomic,copy)   cameraReadyBlock cameraDidCapturePhotoBlock;

@property (nonatomic,assign,getter=isFilterEnabled)   BOOL  filterEnabled;

@property (nonatomic,readonly)   AVCaptureDevice *currentCamera;

/**
 * Camera video input is rinning.
 */
@property (atomic,readonly) BOOL       isRunning;
/**
 *  Image processing is running, video frames capturing is paused.
 */
@property (atomic,readonly) BOOL       isProcessing;
/**
 *  Video frames is captuting or is paused.
 */
@property (atomic,readonly) BOOL       isVideoCapturing;

/**
 * A value that controls the cropping and enlargement of images captured by the device.
 */
@property(nonatomic,readonly) CGFloat maximumZoomFactor;
@property(nonatomic, assign)  CGFloat zoomFactor;
- (void) setZoomFactor:(CGFloat)zoomFactor animate:(BOOL)animate;
- (void) cancelZoom;

/**
 *  The current camera position
 */
@property (nonatomic,readonly) AVCaptureDevicePosition cameraPosition;

/**
 *  Focus mode.
 */
@property (nonatomic,assign)   AVCaptureFocusMode    focusMode;

/**
 *  Lens position.
 *  Value -1 defocuses camera.
 */
@property (nonatomic,assign) CGFloat                 focusLensPosition;

/**
 *  Exposure mode.
 */
@property (nonatomic,assign)   AVCaptureExposureMode exposureMode;

/**
 *  The current exposure duration.
 */
@property (nonatomic,readonly) CMTime                currentExposure;

@property (nonatomic,assign)   CGFloat               exposureCompensation;

/**
 *  The current exposure duration in seconds.
 */
@property (nonatomic,readonly) CGFloat               exposureInSeconds;

/**
 *  The current exposure in percent of full exposure range
 */
@property (nonatomic,readonly) CGFloat               exposureInPercent;

/**
 *  One step value for the one stop exposure adjustment. By default is 1/4.
 */
@property (nonatomic,assign) CGFloat exposureEVDefaultStep;

/**
 *  Current exposure conpensation.
 */
@property (atomic,readonly)  CGFloat exposureEVCompensation;

/**
 *  The camera has focus correction or not.
 */
@property (nonatomic,readonly) BOOL hasFocus;

/**
 *  The camera has flash or not.
 */
@property (nonatomic,readonly) BOOL hasFlash;

/**
 *  The current flash mode.
 */
@property (nonatomic,assign) AVCaptureFlashMode flashMode;

/**
 *  Start camera preview session.
 */
- (void) start;

/**
 *  Stop preview session.
 */
- (void) stop;

/**
 *  Pause preview session.
 */
- (void) pause;
/**
*  Resume paused preview session.
*/
- (void) resume;

/**
 *  Triger the capturing process.
 */
- (void) capturePhotoToFile:(NSString*)filePath;

/**
 *  Toggle from back camera to front and vice versa
 *
 *  @return YES if camera toggled
 */
- (BOOL) toggleCameraPosition;

/**
 *  Focus at point of interest.
 *
 *  @param point view point location
 */
- (void) focusAtPoint:(CGPoint)point;

/**
 *  Exposure at point of interest.
 *
 *  @param point point location
 */
- (void) exposureAtPoint:(CGPoint)point;

/**
 * Adjust exposure in half EV stop. -1 means exposure duration decreasing by one half stop, +1 means increasing by on half stop.
 * +/-2 means one stop, etc
 *
 * @parameter value - EV half stop value
 * @return YES in case exposure has been changed, NO if changing has not been allowed
 */
- (BOOL) adjustExposeWithStopValue:(CGFloat)value;

/**
 *  Set aproximation frame rate for curetn input device.
 *
 *  @param frameRate ~ frame rate
 *
 *  @return frame rate applied
 *
 */
- (BOOL) setFrameRate:(NSUInteger)frameRate;

@end
