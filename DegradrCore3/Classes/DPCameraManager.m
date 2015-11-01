//
//  DPCameraManager.m
//  DegraderCoreNew
//
//  Created by denn on 07.02.15.
//  Copyright (c) 2015 degrader. All rights reserved.
//

#import "DPCameraManager.h"
#import "DPLiveView.h"
#import "DPMotionManager.h"


#import <Metal/Metal.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>
#import <Accelerate/Accelerate.h>
#import <jpeglib.h>


typedef void (^competeSavingBlock)(BOOL finished);

@interface DPCameraManager()  <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic,strong)   AVCaptureDeviceInput       *videoInput;

@property (nonatomic,strong)   AVCaptureVideoDataOutput   *previewOutput;
@property (nonatomic,strong)   AVCaptureConnection        *previewConnection;

@property (nonatomic,strong)   AVCaptureStillImageOutput  *photoOutput;
@property (nonatomic,readonly) AVCaptureConnection        *photoConnection;
@property (nonatomic,strong)   AVCaptureSession           *captureSession;
@property (nonatomic,readonly) UIView                     *containerView;

@property (nonatomic,strong)   dispatch_queue_t           previewOutputQueue;
@property (nonatomic,strong)   dispatch_queue_t           capturingOutputQueue;
@property (nonatomic,strong)   dispatch_queue_t           savingImageQueue;

@property (nonatomic,strong)    DPLiveView            *liveView;
@property (nonatomic,readwrite) CMVideoDimensions      videoDimensions;

@property (nonatomic,readonly) AVCaptureDevice *frontCamera;
@property (nonatomic,readonly) AVCaptureDevice *backCamera;
@property (nonatomic,strong)   AVCaptureDevice *currentCamera;

@property (nonatomic, assign) UIDeviceOrientation currentOrientation;

@property (nonatomic,strong)  CIContext       *ciContext;
@property (atomic,assign)     CMTime           lockedExposure;
@property (atomic,assign)     CGFloat          exposureEVCompensation;
@property (atomic,assign)     CMBufferQueueRef previewBufferQueue;
@property (nonatomic,assign)  CMBufferQueueRef photoBufferQueue;

@property (atomic,assign) BOOL preventExposureLock;
@property (atomic,assign) BOOL hasDownScale;
@property (atomic,assign) BOOL isCameraReady;
@property (atomic,assign) BOOL isProcessing;
@property (atomic,assign) BOOL isVideoCapturing;

@property (nonatomic,assign) BOOL clearPreviewLayerIsReady;

@property (nonatomic,assign) NSUInteger  frameSkipCounter;
@property (nonatomic,assign) NSUInteger  frameSkipNumber;

@property (atomic,assign) BOOL applicationIsActive;

@property (nonatomic,assign) CGFloat               exposureInSeconds;

@property (nonatomic,assign) BOOL isFlipped;

//
// defocusing...
//
@property (atomic,assign) NSUInteger defocusingStage;

#if TARGET_IPHONE_SIMULATOR
@property (atomic,assign)     BOOL          isRunning;
@property (nonatomic,strong)  UIImageView   *cameraOriginalImageView;
@property (nonatomic,strong)  UIImageView   *cameraFilteredImageView;
#endif

@end

@implementation DPCameraManager
{
    CMBufferCallbacks *callbacks;
    NSUInteger         currentFrameRate;
}

@synthesize frontCamera=_frontCamera;
@synthesize backCamera=_backCamera;
@synthesize currentCamera=_currentCamera;
@synthesize photoBufferQueue = _photoBufferQueue;
@synthesize exposureInSeconds = _exposureInSeconds;
@synthesize liveViewFilter = _liveViewFilter;

#if TARGET_IPHONE_SIMULATOR
@synthesize isRunning = _isRunning;
@synthesize exposureMode = _exposureMode;
@synthesize focusMode = _focusMode;
#endif

- (CMBufferQueueRef) photoBufferQueue{
    if (!_photoBufferQueue) {
        
        OSStatus error = CMBufferQueueCreate(kCFAllocatorDefault,
                                             1,
                                             CMBufferQueueGetCallbacksForSampleBuffersSortedByOutputPTS(),
                                             &_photoBufferQueue);
        if (error) {
            NSLog(@"  *** DPCameraManager error: %i in %s:%i", (int)error, __FILE__,__LINE__);
        }
        
    }
    return _photoBufferQueue;
}

- (void) setDownScaleFactor:(CGFloat)downScaleFactor{
    _downScaleFactor = downScaleFactor;
    
    if (_downScaleFactor==1.0) {
        _hasDownScale = NO;
    }
    else{
        _hasDownScale = YES;
    }
}

- (void) dealloc{
    [self removeObservers];
    
    if (_previewBufferQueue) CFRelease(_previewBufferQueue);
    
    if (_photoBufferQueue)  CFRelease(_photoBufferQueue);
    
    if (callbacks)  free(callbacks);
}

- (void) __init__:(UIView *)containerView{
    
    currentFrameRate = kDPCameraFrameRateDefault;
    
    _exposureCompensation  = 0.0;
    _frameSkipNumber = kDP_LiveViewFrameNumberSkip;
    _compressionQuality = 1.0;
    _hardwareCompression = NO;
    _currentOrientation = UIDeviceOrientationPortrait;
    _ciContext = [CIContext contextWithOptions: nil];
    _containerView = containerView;
    
    _exposureEVDefaultStep = 1.0f/4.0f;
    
#if TARGET_IPHONE_SIMULATOR
    _focusMode = AVCaptureFocusModeContinuousAutoFocus;
    _exposureMode = AVCaptureExposureModeContinuousAutoExposure;
#endif
    
    [containerView insertSubview:self.liveView atIndex:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationBecomeInactive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationBecomeInactive:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationDidChange:)
                                                 name:kMotionManagerRotationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPositionDidChange:)
                                                 name:kMotionManagerPositionDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraIsReady:)
                                                 name:AVCaptureSessionDidStartRunningNotification object:nil];
    
    _applicationIsActive = YES;
}

- (void) onApplicationBecomeActive:(NSNotification*)event{
    self.applicationIsActive = YES;
}

- (void) onApplicationBecomeInactive:(NSNotification*)event{
    self.applicationIsActive = NO;
}

- (void)cameraIsReady:(NSNotification *)notification
{
    self.isCameraReady = YES;
}

- (instancetype) initWithOutputContainerPreview:(UIView *)containerView{
    self = [super init];
    if (self) {
        [self __init__:containerView];
    }
    return self;
}

- (instancetype) initWithOutputContainerPreview:(UIView *)containerView withDownscaleFactor:(CGFloat)scale{
    self = [super init];
    if (self) {
        self.downScaleFactor = scale;
        [self __init__:containerView];
    }
    return self;
}

#if TARGET_IPHONE_SIMULATOR
- (UIImageView*) cameraFilteredImageView{
    if (!_cameraFilteredImageView) {
        _cameraFilteredImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera-image-filtered.jpg"]];
        _cameraFilteredImageView.autoresizingMask = ~UIViewAutoresizingNone;
        _cameraFilteredImageView.clipsToBounds = YES;
        _cameraFilteredImageView.contentMode = UIViewContentModeScaleToFill;
    }
    return _cameraFilteredImageView;
}

- (UIImageView*) cameraOriginalImageView{
    if (!_cameraOriginalImageView) {
        _cameraOriginalImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera-image-original.jpg"]];
        _cameraOriginalImageView.autoresizingMask = ~UIViewAutoresizingNone;
        _cameraOriginalImageView.clipsToBounds = YES;
        _cameraOriginalImageView.contentMode = UIViewContentModeScaleToFill;
    }
    return _cameraOriginalImageView;
}

#endif

- (DPContext*) context{
    return self.liveView.context;
}

- (DPLiveView*) liveView{
    if (!_liveView) {
        _liveView = [[DPLiveView alloc] initWithFrame:self.containerView.bounds];
        _liveView.autoresizingMask = ~ UIViewAutoresizingNone;
        _liveView.backgroundColor = [UIColor blackColor];
                
#if TARGET_IPHONE_SIMULATOR
        //
        // simulate captured image view only
        //
        
        self.cameraOriginalImageView.alpha = 0.0;
        self.cameraOriginalImageView.frame = self.cameraFilteredImageView.frame = _previewView.bounds;
        [_previewView addSubview:self.cameraOriginalImageView];
        [_previewView addSubview:self.cameraFilteredImageView];
        
#endif
    }
    return _liveView;
}

- (void) setLiveViewFilter:(DPFilter*)filterLiveView{
    _liveViewFilter = filterLiveView;
    self.liveView.filter = _liveViewFilter;
}

- (DPFilter*) liveViewFilter{
    return _liveViewFilter;
}

- (dispatch_queue_t) previewOutputQueue{
    if (_previewOutputQueue == NULL) {
        _previewOutputQueue = dispatch_queue_create(DP_QUEUE_PREFIX"preview.video", DISPATCH_QUEUE_SERIAL);
    }
    return _previewOutputQueue;
}

- (dispatch_queue_t) capturingOutputQueue{
    if (!_capturingOutputQueue) {
        _capturingOutputQueue = dispatch_queue_create(DP_QUEUE_PREFIX"capturing.photo", DISPATCH_QUEUE_SERIAL);
    }
    return _capturingOutputQueue;
}

- (dispatch_queue_t) savingImageQueue{
    if (!_savingImageQueue) {
        _savingImageQueue = dispatch_queue_create(DP_QUEUE_PREFIX"saving.photo", NULL);
    }
    return _savingImageQueue;
}

- (AVCaptureConnection*) photoConnection{
    return [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
}

#pragma mark -
#pragma mark - Camera management

#if TARGET_IPHONE_SIMULATOR
- (void) setIsRunning:(BOOL)isRunning{
    _isRunning = isRunning;
}
#endif

- (BOOL) isRunning {
#if TARGET_IPHONE_SIMULATOR
    return _isRunning;
#else
    if (self.currentCamera == nil)  return NO;
    return self.captureSession.isRunning;
#endif
}

- (void) start{
#if TARGET_IPHONE_SIMULATOR
    
    if (!self.isRunning) {
        
        self.clearPreviewLayerIsReady = NO;
        
        if (self.cameraWillReadyBlock)   self.cameraWillReadyBlock();
        if (self.liveViewDidReadyBlock)  self.liveViewDidReadyBlock();
        
        if (!self.clearPreviewLayerIsReady && self.cameraDidReadyBlock) {
            self.cameraDidReadyBlock();
            self.clearPreviewLayerIsReady = YES;
        }
        
        self.isRunning = YES;
        
    }
    
#else
    if (!self.captureSession.isRunning) {
        
        __weak typeof(self) this = self;
        
        self.clearPreviewLayerIsReady = NO;
        
        if (!self.clearPreviewLayerIsReady && self.cameraWillReadyBlock) {
            dispatch_async(this.previewOutputQueue, ^{
                self.cameraWillReadyBlock();
            });
        }
        
        self.liveView.filter = self.liveViewFilter;        
        
        self.liveView.firstFrameDidReceive = ^(){
            if (this.liveViewDidReadyBlock) {
                dispatch_async(this.previewOutputQueue, ^{
                    this.liveViewDidReadyBlock();
                });
            }
        };
        
        CMBufferQueueCreate(
                            kCFAllocatorDefault,
                            1,
                            CMBufferQueueGetCallbacksForSampleBuffersSortedByOutputPTS(),
                            &_previewBufferQueue);
        
        [self.captureSession startRunning];
        
        [self setFrameRate:currentFrameRate];
    }
    
#endif
    self.isVideoCapturing = YES;
    self.defocusingStage = 0;
    
    self.liveView.isPaused = NO;
}

- (void) stop{
#if TARGET_IPHONE_SIMULATOR
    if (self.isRunning) {
        if (self.cameraDidStopBlock) self.cameraDidStopBlock();
        self.isRunning = NO;
    }
#else
    self.liveView.isPaused = YES;

    __weak typeof(self) this = self;
    
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
        if (_previewBufferQueue)
        {
            CFRelease(_previewBufferQueue);
            _previewBufferQueue = NULL;
        }
        
        if (self.cameraDidStopBlock) {
            dispatch_async(this.previewOutputQueue, ^{
                self.cameraDidStopBlock();
            });
        }
    }
#endif
    self.isVideoCapturing = NO;
    self.defocusingStage = 0;
    self.clearPreviewLayerIsReady = NO;
}

- (void) pause{
#if TARGET_IPHONE_SIMULATOR
    if ( self.isVideoCapturing && self.cameraDidStopBlock) self.cameraDidStopBlock();
#else
    self.liveView.isPaused = YES;

    __weak typeof(self) this = self;
    if (self.isVideoCapturing && self.cameraDidStopBlock) {
        dispatch_async(this.previewOutputQueue, ^{
            self.cameraDidStopBlock();
        });
    }
#endif
    self.defocusingStage = 0;
    self.isVideoCapturing = NO;
    self.clearPreviewLayerIsReady = NO;
}

- (void) resume{
#if TARGET_IPHONE_SIMULATOR
    if (!self.isVideoCapturing && self.cameraDidReadyBlock) self.cameraDidReadyBlock();
#else

    self.liveView.isPaused = NO;

    if (!self.isRunning)
        [self start];
    else{
        [self setFrameRate:currentFrameRate];
    }
#endif
    self.isVideoCapturing = YES;
    self.defocusingStage = 0;
}

- (BOOL) toggleCameraPosition{
    
    AVCaptureDevicePosition p = self.cameraPosition;
    
    [self rotateCamera];
    
    return p==self.cameraPosition;
}

- (void)rotateCamera
{
    self.defocusingStage = 0;
    
    if ([self frontFacingCameraPresent] == NO)
        return;
    
    [self.captureSession beginConfiguration];
    
    [self.captureSession removeInput:self.videoInput];
    
    _videoInput = nil;
    
    if (self.currentCamera == self.backCamera) {
        self.currentCamera = self.frontCamera;
        if (!self.isFlipped) {
            [self.liveViewFilter.transform flipVertical];
            self.isFlipped = YES;
        }
    }
    else{
        self.currentCamera = self.backCamera;
        if (self.isFlipped)
            [self.liveViewFilter.transform flipVertical];
    }
    
    if ( [self.captureSession canAddInput:self.videoInput] )
        [self.captureSession addInput:self.videoInput];
    
    _previewConnection = [self.previewOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [self.captureSession commitConfiguration];
}


#pragma mark -
#pragma mark - Camera properties

- (CGFloat) maximumZoomFactor{
    return kDP_maximumZoomFactor;
}

- (void) setZoomFactor:(CGFloat)zoomFactor{
    
    self.defocusingStage = 0;
    
    if (zoomFactor>=1.0 && zoomFactor<=self.currentCamera.activeFormat.videoMaxZoomFactor) {
        NSError *error;
        if ([self.currentCamera lockForConfiguration: &error]) {
            self.currentCamera.videoZoomFactor = zoomFactor;
            [self.currentCamera unlockForConfiguration];
        }
        else {
            NSLog(@"  *** DPCameraManager error: %@, %s:%i", error, __FILE__, __LINE__);
        }
    }
    else{
        NSLog(@"  *** DPCameraManager error: zoomFactor should be between: [1.0, %f], %s:%i", self.currentCamera.activeFormat.videoMaxZoomFactor, __FILE__, __LINE__);
    }
}

- (CGFloat) zoomFactor{
    return self.currentCamera.videoZoomFactor;
}

- (void) cancelZoom{
    NSError *error;
    
    self.defocusingStage = 0;
    
    if ([self.currentCamera lockForConfiguration: &error]) {
        
        [self.currentCamera cancelVideoZoomRamp];
        
        [self.currentCamera unlockForConfiguration];
    }
    else {
        NSLog(@"  *** DPCameraManager error: %@, %s:%i", error, __FILE__, __LINE__);
    }
}

- (void) setZoomFactor:(CGFloat)zoomFactor animate:(BOOL)animate{
    
    self.defocusingStage = 0;
    
    if (zoomFactor>=1.0 && zoomFactor<=self.currentCamera.activeFormat.videoMaxZoomFactor) {
        NSError *error;
        if ([self.currentCamera lockForConfiguration: &error]) {
            
            if (animate)
                [self.currentCamera rampToVideoZoomFactor:zoomFactor withRate:kDPCameraFrameRateDefault];
            else
                self.currentCamera.videoZoomFactor = zoomFactor;
            
            [self.currentCamera unlockForConfiguration];
        }
        else {
            NSLog(@"  *** DPCameraManager error: %@, %s:%i", error, __FILE__, __LINE__);
        }
    }
    else{
        NSLog(@"  *** DPCameraManager error: zoomFactor should be between: [1.0, %f], %s:%i", self.currentCamera.activeFormat.videoMaxZoomFactor, __FILE__, __LINE__);
    }
}

- (void) setFocusMode:(AVCaptureFocusMode)focusMode{
    
#if TARGET_IPHONE_SIMULATOR
    _focusMode = focusMode;
#else
    if (self.currentCamera == nil)
        return;
    
    self.defocusingStage = 0;
    
    if ([self.currentCamera isFocusModeSupported:focusMode]) {
        NSError *error;
        
        if ([self.currentCamera lockForConfiguration:&error]) {
            
            [self.currentCamera setFocusMode:focusMode];
            
            if (focusMode == AVCaptureFocusModeContinuousAutoFocus) {
                [self.currentCamera setFocusPointOfInterest:CGPointMake(0.5f, 0.5f)];
                if (self.focusDidChange) {
                    dispatch_async(self.previewOutputQueue, ^{
                        self.focusDidChange(self);
                    });
                }
            }
            
            [self.currentCamera unlockForConfiguration];
        }
        else
            NSLog(@" *** DPCameraManafer focus error: %@", error);
    }
#endif
}

- (AVCaptureFocusMode) focusMode{
#if TARGET_IPHONE_SIMULATOR
    return _focusMode;
#else
    if (self.currentCamera == nil)
        return AVCaptureFocusModeLocked;
    
    return self.currentCamera.focusMode;
#endif
}

- (CGFloat) focusLensPosition{
    if ([self.currentCamera respondsToSelector:@selector(lensPosition)]) {
        return  self.currentCamera.lensPosition;
    }
    return 0.0f;
}

- (void) setFocusLensPosition:(CGFloat)focusLensPosition{
    
    dispatch_async(self.previewOutputQueue, ^{
        
        if (focusLensPosition>1. || focusLensPosition<0.) {
            //
            // do defocus
            //
            
            if (self.defocusingStage > 0) return;
            
            if (![self.currentCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]
                ||
                ![self.currentCamera isFocusPointOfInterestSupported]
                ||
                ![self.currentCamera respondsToSelector:@selector(setFocusModeLockedWithLensPosition:completionHandler:)]
                ) {
                return;
            }
            
            if ([self.currentCamera lockForConfiguration:nil]) {
                if (self.focusWillChange) {
                    dispatch_async(self.previewOutputQueue, ^{
                        self.focusWillChange(self);
                    });
                }
                
                self.defocusingStage = 1;
                
                [self.currentCamera setFocusPointOfInterest:CGPointMake(0.5f, 0.5f)];
                [self.currentCamera setFocusMode:AVCaptureFocusModeAutoFocus];
                [self.currentCamera unlockForConfiguration];
            }
            return;
        }
        
        if ([self.currentCamera isFocusModeSupported:AVCaptureFocusModeLocked] && [self.currentCamera respondsToSelector:@selector(setFocusModeLockedWithLensPosition:completionHandler:)]) {
            if ([self.currentCamera lockForConfiguration:nil]) {
                [self.currentCamera setFocusModeLockedWithLensPosition:(float)focusLensPosition completionHandler:nil];
                [self.currentCamera unlockForConfiguration];
            }
            
        }
    });
}

- (void) focusAtPoint:(CGPoint)point{
    
    dispatch_async(self.previewOutputQueue, ^{
        
        if (self.currentCamera == nil)
            return;
        
        self.defocusingStage = 0;
        
        CGPoint pointOfInterest = [self pointOfInterestForLocation:point];
        
        if ([self.currentCamera isFocusPointOfInterestSupported] && [self.currentCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([self.currentCamera lockForConfiguration:&error]) {
                
                if (self.focusWillChange) {
                    dispatch_async(self.previewOutputQueue, ^{
                        self.focusWillChange(self);
                    });
                }
                
                //
                // set autofocus point
                //
                
                [self.currentCamera setFocusPointOfInterest:pointOfInterest];
                [self.currentCamera setFocusMode:AVCaptureFocusModeAutoFocus];
                [self.currentCamera unlockForConfiguration];
            }
            else
                NSLog(@" *** DPCameraManafer focus error: %@", error);
        }
    });
}

- (BOOL) setFrameRate:(NSUInteger)frameRate{
    
    currentFrameRate = frameRate;
    
    AVCaptureDeviceFormat *activeCaptureFormat = self.currentCamera.activeFormat;
    
    for (AVFrameRateRange *rate in activeCaptureFormat.videoSupportedFrameRateRanges){
        if(frameRate>=rate.minFrameRate && frameRate<=rate.maxFrameRate){
            @try {
                NSError *error;
                if ([self.currentCamera lockForConfiguration:&error]) {
                    [self.currentCamera setActiveVideoMinFrameDuration:CMTimeMake(1, (int)frameRate)];
                    [self.currentCamera setActiveVideoMaxFrameDuration:CMTimeMake(1, (int)frameRate)];
                    [self.currentCamera unlockForConfiguration];
                }
                else
                    return NO;
            }
            @catch (NSException *exception) {
                return NO;
            }
            return YES;
        }
    }
    
    return NO;
}

- (void) setExposureMode:(AVCaptureExposureMode)exposureMode{
    dispatch_async(self.previewOutputQueue, ^{
        
#if TARGET_IPHONE_SIMULATOR
        _exposureMode = exposureMode;
#else
        if (self.currentCamera == nil)
            return;
        
        self.preventExposureLock = NO;
        
        if ([self.currentCamera isExposureModeSupported:exposureMode]) {
            NSError *error;
            
            if ([self.currentCamera lockForConfiguration:&error]) {
                
                if (exposureMode == AVCaptureExposureModeContinuousAutoExposure) {
                    CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
                    [self.currentCamera setExposurePointOfInterest:exposurePoint];
                    
                    self.lockedExposure = self.currentCamera.exposureDuration;
                    self.exposureEVCompensation = 0.0;
                    
                    [self updateExposureCompensation:self.exposureCompensation];
                    
                    if (self.exposureDidChange) {
                        dispatch_async(self.previewOutputQueue, ^{
                            self.exposureDidChange(self);
                        });
                    }
                }
                else if (exposureMode == AVCaptureExposureModeCustom
                         ||
                         exposureMode == AVCaptureExposureModeLocked){
                    [self updateExposureCompensation:0.0];
                }
                
                [self.currentCamera setExposureMode:exposureMode];
                
                [self setFrameRate:self->currentFrameRate];
                
                [self.currentCamera unlockForConfiguration];
            }
            else
                NSLog(@" *** DPCameraManafer exposure error: %@", error);
        }
#endif
    });
}

- (AVCaptureExposureMode) exposureMode{
#if TARGET_IPHONE_SIMULATOR
    return _exposureMode;
#else
    return self.currentCamera.exposureMode;
#endif
}


- (CGPoint) pointOfInterestForLocation:(CGPoint)location{
    
    CGSize  frameSize = [self.liveView frame].size;
    
    if (self.cameraPosition == AVCaptureDevicePositionFront) {
        location.x = frameSize.width - location.x;
    }
    
    return CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
}

- (void) exposureAtPoint:(CGPoint)point{
    dispatch_async(self.previewOutputQueue, ^{
        
        if (self.currentCamera == nil)
            return;
        
        if([self.currentCamera isExposurePointOfInterestSupported] && [self.currentCamera isExposureModeSupported:AVCaptureExposureModeAutoExpose])
        {
            CGPoint pointOfInterest = [self pointOfInterestForLocation:point];
            
            NSError *error1;
            
            if (self.exposureWillChange) {
                dispatch_async(self.previewOutputQueue, ^{
                    self.exposureWillChange(self);
                });
            }
            
            self.preventExposureLock = NO;
            
            if ([self.currentCamera lockForConfiguration:&error1]) {
                
                [self.currentCamera setExposurePointOfInterest:pointOfInterest];
                
                [self.currentCamera setExposureMode:AVCaptureExposureModeAutoExpose];
                
                self.lockedExposure = self.currentCamera.exposureDuration;
                self.exposureEVCompensation = 0.0;
                
                if (self.exposureDidChange) {
                    dispatch_async(self.previewOutputQueue, ^{
                        self.exposureDidChange(self);
                    });
                }
                
                [self.currentCamera unlockForConfiguration];
            }
            else
                NSLog(@" *** DPCameraManafer exposure error: %@", error1);
        }
    });
}

- (BOOL) adjustExposeWithStopValue:(CGFloat)value{
    
    if (self.currentCamera == nil)
        return NO;
    
    __unsafe_unretained __block AVCaptureDevice *device = self.currentCamera;
    
    BOOL is_changed = YES;
    
    //
    // avoid adjusting when exposure is already adjusting
    //
    
    if (device.adjustingExposure || self.preventExposureLock){
        return NO;
    }
    
    //
    // if manual exposuring supported
    //
    if ([device isExposureModeSupported:AVCaptureExposureModeLocked] &&
        [device isExposureModeSupported:AVCaptureExposureModeCustom] &&
        [device respondsToSelector:@selector(setExposureModeCustomWithDuration:ISO:completionHandler:)]
        ) {
        
        //
        // before adjusting lock expouser
        //
        
        if ([device lockForConfiguration:nil]) {
            
            
            if (self.exposureWillChange) {
                dispatch_async(self.previewOutputQueue, ^{
                    self.exposureWillChange(self);
                });
            }
            
            if (device.exposureMode != AVCaptureExposureModeLocked)
                [device setExposureMode:AVCaptureExposureModeLocked];
            
            //
            // Compute exposure in stops
            //
            CGFloat currentExposureDuration = (CGFloat)CMTimeGetSeconds(self.lockedExposure);
            
            self.exposureEVCompensation += self.exposureEVDefaultStep * value;
            
            CGFloat nextExposureDuration = (CGFloat)(self.exposureEVCompensation==0.0f?currentExposureDuration:currentExposureDuration*pow(2.0f, self.exposureEVCompensation));
            
            //
            // recompute exposure in camera duration
            //
            CGFloat minExposure = (CGFloat)CMTimeGetSeconds(device.activeFormat.minExposureDuration);
            CGFloat maxExposure = (CGFloat)CMTimeGetSeconds(device.activeFormat.maxExposureDuration);
            
            if (nextExposureDuration<minExposure)
                nextExposureDuration = minExposure;
            
            else if (nextExposureDuration>maxExposure)
                nextExposureDuration = maxExposure;
            
            CMTime newDuration = CMTimeMakeWithSeconds(nextExposureDuration, device.activeFormat.minExposureDuration.timescale);
            
            self.preventExposureLock = YES;
            
            @try {
                [device setExposureModeCustomWithDuration:newDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
                    self.preventExposureLock = NO;
                    if (self.exposureDidChange) {
                        dispatch_async(self.previewOutputQueue, ^{
                            self.exposureDidChange(self);
                        });
                    }
                }];
            }
            @catch (NSException *exception) {
                NSLog(@" *** DPCameraManager adjust exposure error: %@", exception);
                self.preventExposureLock = NO;
                if (self.exposureDidChange) {
                    dispatch_async(self.previewOutputQueue, ^{
                        self.exposureDidChange(self);
                    });
                }
            }
            
            [device unlockForConfiguration];
        }
        else
            self.preventExposureLock = NO;
    }
    
    return is_changed;
}

- (CGFloat) exposureInSeconds{
    if (self.currentCamera == nil)
        return 0.0f;
    
    _exposureInSeconds = (CGFloat)CMTimeGetSeconds(self.currentCamera.exposureDuration);
    
    return  (CGFloat)CMTimeGetSeconds(self.currentCamera.exposureDuration);
}

- (CGFloat) exposureInPercent{
    if (self.currentCamera == nil)
        return 0.0;
    
    CGFloat minExposure = (CGFloat)CMTimeGetSeconds(self.currentCamera.activeFormat.minExposureDuration);
    CGFloat maxExposure = (CGFloat)CMTimeGetSeconds(self.currentCamera.activeFormat.maxExposureDuration);
    
    return 1.0f - (CGFloat)(maxExposure - CMTimeGetSeconds(self.currentCamera.exposureDuration))/(maxExposure-minExposure);
}


#pragma mark -
#pragma mark - Camera I/O

- (AVCaptureDeviceInput*) videoInput{
    if (!_videoInput) {
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.currentCamera error:nil];
    }
    return _videoInput;
}

- (AVCaptureVideoDataOutput*) previewOutput{
    if (!_previewOutput) {
        _previewOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_previewOutput setSampleBufferDelegate:self queue:self.previewOutputQueue];
        [_previewOutput setAlwaysDiscardsLateVideoFrames:YES];
        [_previewOutput setVideoSettings: @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    }
    return _previewOutput;
}

- (AVCaptureStillImageOutput*) photoOutput{
    if (!_photoOutput) {
        _photoOutput = [[AVCaptureStillImageOutput alloc] init];
        if (self.hardwareCompression)
            [_photoOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG, AVVideoQualityKey:@(self.compressionQuality)}];
        else
            [_photoOutput setOutputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
        
    }
    return _photoOutput;
}

- (void) setCompressionQuality:(CGFloat)compressionQuality{
    _compressionQuality = compressionQuality;
    if (self.hardwareCompression) {
        [self.photoOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG, AVVideoQualityKey:@(_compressionQuality)}];
    }
}

- (void) setHardwareCompression:(BOOL)hardwareCompression{
    _hardwareCompression = hardwareCompression;
    if (_hardwareCompression)
        [self.photoOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG, AVVideoQualityKey:@(self.compressionQuality)}];
    else
        [self.photoOutput setOutputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
}

- (AVCaptureSession*) captureSession{
    if (!_captureSession) {
        
        _captureSession = [[AVCaptureSession alloc] init];
        
        if (_captureSession) {
            [_captureSession beginConfiguration];
            
            //
            // Input
            //
            if (self.videoInput) {
                if ( [_captureSession canAddInput:self.videoInput] )
                    [_captureSession addInput:self.videoInput];
            }
            
            //
            // preview output
            //
            if (self.previewOutput) {
                if ([_captureSession canAddOutput:self.previewOutput])
                    [_captureSession addOutput:self.previewOutput];
            }
            
            //
            // photo capure output
            //
            if (self.photoOutput) {
                if ( [_captureSession canAddOutput:self.photoOutput] )
                    [_captureSession addOutput:self.photoOutput];
            }
            
            [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
            
            _previewConnection = [_previewOutput connectionWithMediaType:AVMediaTypeVideo];
            [_previewConnection setAutomaticallyAdjustsVideoMirroring:NO];
            [_captureSession commitConfiguration];
        }                
    }
    
    return _captureSession;
}

- (void) setFilterEnabled:(BOOL)filterEnabled{
    
#if TARGET_IPHONE_SIMULATOR
    _filterEnabled = filterEnabled;
    if (_filterEnabled) {
        self.cameraOriginalImageView.alpha = 0.0;
        self.cameraFilteredImageView.alpha = 1.0;
    }
    else{
        self.cameraOriginalImageView.alpha = 1.0;
        self.cameraFilteredImageView.alpha = 0.0;
    }
#else
    
    _filterEnabled = filterEnabled;

    self.liveView.isFilterDisabled = !filterEnabled;
    
#endif
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position
{
    __block AVCaptureDevice *deviceBlock = nil;
    
    [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^( AVCaptureDevice *device, NSUInteger idx, BOOL *stop ) {
        if ( [device position] == position ) {
            deviceBlock = device;
            *stop = YES;
        }
    }];
    
    return deviceBlock;
}

- (AVCaptureDevicePosition)cameraPosition
{
    return [[self.videoInput device] position];
}

- (AVCaptureDevice *) frontCamera
{
    if (!_frontCamera) {
        _frontCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        
        if (_frontCamera && [_frontCamera lockForConfiguration:nil]) {
            if ([_frontCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]){
                _frontCamera.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            }
            [_frontCamera unlockForConfiguration];
        }
        
    }
    return _frontCamera;
}

- (AVCaptureDevice *) backCamera
{
    if (!_backCamera) {
        _backCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        
        if (_backCamera && [_backCamera lockForConfiguration:nil]) {
            
            if ([_backCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                _backCamera.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            }
            
            [_backCamera unlockForConfiguration];
        }
        
    }
    return _backCamera;
}

- (void) addObservers{
    [_currentCamera addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    [_currentCamera addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:nil];
    [_currentCamera addObserver:self forKeyPath:@"ISO" options:NSKeyValueObservingOptionNew context:nil];
    [_currentCamera addObserver:self forKeyPath:@"exposureTargetBias" options:NSKeyValueObservingOptionNew context:nil];
    [_currentCamera addObserver:self forKeyPath:@"exposureMode" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void) removeObservers{
    [_currentCamera removeObserver:self forKeyPath:@"adjustingFocus" context:nil];
    [_currentCamera removeObserver:self forKeyPath:@"adjustingExposure" context:nil];
    [_currentCamera removeObserver:self forKeyPath:@"exposureTargetBias" context:nil];
    [_currentCamera removeObserver:self forKeyPath:@"exposureMode" context:nil];
}

- (CGFloat) updateExposureCompensation:(CGFloat)exposureCompensation{
    
    if (self.currentCamera == nil) {
        return 0.0f;
    }
    
    CGFloat ec  = exposureCompensation;
    
    if (
        [self.currentCamera respondsToSelector:@selector(minExposureTargetBias)]
        &&
        [self.currentCamera respondsToSelector:@selector(maxExposureTargetBias)]
        &&
        [self.currentCamera respondsToSelector:@selector(setExposureTargetBias:completionHandler:)]
        ) {
        if  (exposureCompensation<self.currentCamera.minExposureTargetBias)
            ec = self.currentCamera.minExposureTargetBias;
        
        if (exposureCompensation>self.currentCamera.maxExposureTargetBias)
            ec = self.currentCamera.maxExposureTargetBias;
        
        if  ([self.currentCamera lockForConfiguration:nil]){
            [self.currentCamera setExposureTargetBias:(float)ec completionHandler:^(CMTime syncTime) {
            }];
            [self.currentCamera unlockForConfiguration];
        }
    }
    else{
        ec = 0.0f;
    }
    
    
    return ec;
}

- (void) setExposureCompensation:(CGFloat)exposureCompensation{
    _exposureCompensation = [self updateExposureCompensation:exposureCompensation];
}

- (AVCaptureDevice*) currentCamera{
    if (!_currentCamera) {
        _currentCamera = self.backCamera;
        if (_currentCamera){
            _lockedExposure = _currentCamera.exposureDuration;
            _exposureEVCompensation = 0.0;
            
            [self setFrameRate:currentFrameRate];
            
            [self addObservers];
            
            self.exposureCompensation = _exposureCompensation;
        }
    }
    return _currentCamera;
}

- (void) setCurrentCamera:(AVCaptureDevice *)currentCamera{
    
    if (_currentCamera) {
        [self removeObservers];
    }
    
    _currentCamera = currentCamera;
    
    if (_currentCamera) {
        _lockedExposure = _currentCamera.exposureDuration;
        _exposureEVCompensation = 0.0;
        
        self.exposureCompensation = _exposureCompensation;
        
        [self addObservers];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (!self.isVideoCapturing) return;
    
    if ([keyPath isEqualToString:@"exposureTargetBias"]) {
        if (self.exposureDidChange) {
            dispatch_async(self.previewOutputQueue, ^{
                self.exposureDidChange(self);
            });
        }
    }
    
    if ([keyPath isEqualToString:@"exposureMode"]) {
        //DPDegradrFilter *degradr = (DPDegradrFilter*) self.liveViewFilter;
        if  (
             self.currentCamera.exposureMode == AVCaptureExposureModeCustom
             ||
             self.currentCamera.exposureMode == AVCaptureExposureModeLocked
             ){
            //degradr.exposureCompensationEnabled = NO;
        }
        else {
            //degradr.exposureCompensationEnabled = YES;
        }
    }
    
    if([keyPath isEqualToString:@"adjustingExposure"]) {
        
        if (self.currentCamera.isAdjustingExposure) {
            //self.liveViewFilter.frameSkipNumber = 1000;
        }
        
        if (self.exposureMode == AVCaptureExposureModeAutoExpose
            ||
            self.exposureMode == AVCaptureExposureModeCustom
            ||
            self.exposureMode == AVCaptureExposureModeLocked
            ) {
            if (self.currentCamera.isAdjustingExposure == 0) {
                
                self.preventExposureLock = NO;
                
                self.exposureMode = AVCaptureExposureModeLocked;
                
                self.lockedExposure = self.currentCamera.exposureDuration;
                self.exposureEVCompensation = 0.0;
                
                [self resetLiveViewAnalizers];
                
                if (self.exposureDidChange) {
                    dispatch_async(self.previewOutputQueue, ^{
                        self.exposureDidChange(self);
                    });
                }
                
            }
        }
    }
    
    else if ([keyPath isEqualToString:@"adjustingFocus"]){
        
        if (self.currentCamera.isAdjustingFocus) {
            //self.liveViewFilter.frameSkipNumber = 1000;
        }
        
        if (self.defocusingStage==1) {
            
            if (self.currentCamera.isAdjustingFocus == 0) {
                
                self.focusMode = AVCaptureFocusModeLocked;
                
                if (self.focusLensPosition<0.3f)
                    self.focusLensPosition=1.0;
                else
                    self.focusLensPosition=0.0f;
                
                self.defocusingStage = 2;
            }
        }
        else{
            
            if (
                self.focusMode == AVCaptureFocusModeAutoFocus
                ||
                self.focusMode == AVCaptureFocusModeLocked
                ) {
                
                if (self.currentCamera.isAdjustingFocus == 0) {
                    
                    if (self.defocusingStage==0) {
                        //self.focusMode = AVCaptureFocusModeLocked;
                    }
                    else
                        self.defocusingStage = 0;
                    
                    [self resetLiveViewAnalizers];
                    
                    if (self.focusDidChange) {
                        dispatch_async(self.previewOutputQueue, ^{
                            self.focusDidChange(self);
                        });
                    }
                    
                }
            }
            else if (
                     self.focusMode == AVCaptureFocusModeContinuousAutoFocus
                     ){
                
                if (self.currentCamera.isAdjustingFocus == 0) {
                    
                    [self resetLiveViewAnalizers];
                    
                    if (self.focusDidChange) {
                        dispatch_async(self.previewOutputQueue, ^{
                            self.focusDidChange(self);
                        });
                    }
                    
                }
            }
        }
    }
}

- (BOOL)frontFacingCameraPresent
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionFront)
            return YES;
    }
    
    return NO;
}

- (BOOL) hasFocus
{
    if (self.currentCamera == nil)
        return NO;
    
    AVCaptureDevice *device = self.currentCamera;
    
    return  [device isFocusModeSupported:AVCaptureFocusModeLocked] ||
    [device isFocusModeSupported:AVCaptureFocusModeAutoFocus] ||
    [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
}


- (BOOL) hasFlash
{
    if (self.currentCamera == nil)
        return NO;
    
    return self.currentCamera.hasFlash;
}

- (AVCaptureFlashMode) flashMode
{
    if (self.currentCamera == nil)
        return AVCaptureFlashModeOff;
    
    return self.currentCamera.flashMode;
}

- (void) setFlashMode:(AVCaptureFlashMode)flashMode
{
    AVCaptureDevice *device = self.currentCamera;
    
    if (device == nil)
        return;
    
    
    if ( [device isFlashModeSupported:flashMode] && device.flashMode != flashMode ) {
        NSError *error;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        else
            NSLog(@" *** DPCameraManager flash settings error: %@", error);
    }
}


#pragma mark -
#pragma mark - Capturing image

-(BOOL) saveJPEGImage:(CVPixelBufferRef)pixelBuffer withCompression:(CGFloat)compressionQ path:(NSString *)path complete:(competeSavingBlock)completeBlock{
    
    int quality = round(compressionQ*100.0f); quality=quality<=0?10:quality>100?100:quality;
    
    const char *filename = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    int q = (int)round(quality * 100.0f); q=(q<=0?10:q>=100?100:q);
    
    
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    
    FILE * outfile;               /* target file */
    JSAMPROW row_pointer[1];      /* pointer to JSAMPLE row[s] */
    int row_stride;               /* physical row width in image buffer */
    
    /* Step 1: allocate and initialize JPEG compression object */
    
    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    
    
    /* Step 2: specify data destination (eg, a file) */
    if ((outfile = fopen(filename, "wb")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
        return NO;
    }
    jpeg_stdio_dest(&cinfo, outfile);
    
    
    /* Step 3: set parameters for compression */
    
    cinfo.image_width  = (int)CVPixelBufferGetWidth(pixelBuffer);      /* image width and height, in pixels */
    cinfo.image_height = (int)CVPixelBufferGetHeight(pixelBuffer);
    cinfo.input_components = 4;           /* # of color components per pixel */
    cinfo.in_color_space = JCS_EXT_RGBA;  /* colorspace of input image */
    
    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, quality, TRUE /* limit to baseline-JPEG values */);
    
    
    /* Step 4: Start compressor */
    
    jpeg_start_compress(&cinfo, TRUE);
    
    
    /* Step 5: while (scan lines remain to be written) */
    /*           jpeg_write_scanlines(...); */
    
    row_stride = (int)cinfo.image_width  * cinfo.input_components; /* JSAMPLEs per row in image_buffer */
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void       *image_buffer  = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    while (cinfo.next_scanline < cinfo.image_height) {
        row_pointer[0] = & image_buffer[cinfo.next_scanline * row_stride];
        (void) jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    /* Step 6: Finish compression */
    
    jpeg_finish_compress(&cinfo);
    /* After finish_compress, we can close the output file. */
    fclose(outfile);
    
    
    /* Step 7: release JPEG compression object */
    jpeg_destroy_compress(&cinfo);
    
    if (completeBlock) {
        completeBlock(YES);
    }
    
    return YES;
}

- (void) capturePhotoToFile:(NSString*)filePath{    
    
    if (
        self.currentCamera  == nil
        ) {
        return;
    }
    
    if (!self.isRunning) {
        [self start];
    }
    
    if (self.photoOutput.capturingStillImage) return;
    
    if (!self.hardwareCompression) {
        if (self.isProcessing)
            return;
    }
    
    UIDeviceOrientation deviceOrientation = self.currentOrientation;
    __block UIImageOrientation imageOrientation   = UIImageOrientationRight; // captured photo
    
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        imageOrientation = self.cameraPosition == AVCaptureDevicePositionFront ? UIImageOrientationDown : UIImageOrientationUp;
    }
    else if (deviceOrientation == UIDeviceOrientationLandscapeRight){
        imageOrientation = self.cameraPosition == AVCaptureDevicePositionFront ? UIImageOrientationUp: UIImageOrientationDown;
    }
    else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown){
        imageOrientation = self.cameraPosition == AVCaptureDevicePositionFront ? UIImageOrientationLeft : UIImageOrientationLeft;
    }

    AVCaptureConnection   *connection = [DPCameraManager connectionWithMediaType:AVMediaTypeVideo fromConnections:self.photoOutput.connections];
    __block AVCaptureExposureMode exposureMode = self.currentCamera.exposureMode;
    
    self.isProcessing = YES;
    
    __weak typeof(self) this = self;
    
    if (self.capturingCompleteBlock) {
        
        if (self.cameraWillCapturePhotoBlock) {
            dispatch_async(self.previewOutputQueue, ^{
                self.cameraWillCapturePhotoBlock();
            });
        }
        
        [self.photoOutput
         captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
             
             if (error) {
                 NSLog(@"   *** DPCameraManager erorr: %@ in %s:%i", error, __FILE__, __LINE__);
                 if (this.cameraDidCapturePhotoBlock) {
                     dispatch_async(self.previewOutputQueue, ^{
                         this.cameraDidCapturePhotoBlock();
                     });
                 }
                 
                 this.capturingCompleteBlock(NO,filePath,nil);
                 this.isProcessing = NO;
                 return ;
             }
             
             OSStatus qerror = CMBufferQueueEnqueue(this.photoBufferQueue, sampleBuffer);
             
             if (qerror) {
                 NSLog(@"   *** DPCameraManager erorr: %i in %s:%i", (int)qerror, __FILE__, __LINE__);
                 if (this.cameraDidCapturePhotoBlock) {
                     dispatch_async(self.previewOutputQueue, ^{
                         this.cameraDidCapturePhotoBlock();
                     });
                 }
                 
                 dispatch_async(self.savingImageQueue, ^{
                     this.capturingCompleteBlock(NO,filePath,nil);
                 });
                 this.isProcessing = NO;
                 return ;
             }
             
             dispatch_sync(self.previewOutputQueue, ^{
                 
                 CMSampleBufferRef imageDataSampleBuffer = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(this.photoBufferQueue);
                 
                 if ( imageDataSampleBuffer != NULL ) {
                     
                     CFDictionaryRef attacment     = (CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate));
                     
                     __block NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary: (__bridge NSDictionary *)attacment];
                     
                     [metadata setObject:[NSNumber numberWithInt:imageOrientation] forKey:kDP_imageOrientationKey];
                     [metadata setObject:[NSNumber numberWithInt:exposureMode] forKey:kDP_imageSourceExposureMode];
                     [metadata setObject:[NSNumber numberWithInt:DP_CORE_VERSION] forKey:kDP_coreVersionKey];

                     CFRelease(attacment);
                     
                     if (this.hardwareCompression) {
                         
                         __block NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                         CFRelease(imageDataSampleBuffer);
                         
                         dispatch_async(self.savingImageQueue, ^{
                             @autoreleasepool {
                                 NSError *writeError = nil;
                                 if ([imageData writeToFile:filePath options:NSDataWritingAtomic error:&writeError]) {
                                     this.capturingCompleteBlock(YES, filePath, metadata);
                                 }
                                 else {
                                     this.capturingCompleteBlock(NO, filePath, nil);
                                 }
                                 imageData = nil;
                                 this.isProcessing = NO;
                             }
                         });
                     }
                     else{

                         dispatch_async(this.savingImageQueue, ^{
                             CVPixelBufferRef inputPixelBuffer =  CVPixelBufferRetain(CMSampleBufferGetImageBuffer(imageDataSampleBuffer)) ;
                             if (inputPixelBuffer){
                                 
                                 [this saveJPEGImage:inputPixelBuffer withCompression:self.compressionQuality path:filePath complete:^(BOOL finished) {
                                     CFRelease(imageDataSampleBuffer);
                                     this.capturingCompleteBlock(finished, filePath, metadata);
                                     this.isProcessing = NO;
                                 }];
                              
                                 CVPixelBufferRelease(inputPixelBuffer);
                             }
                             else {
                                 this.capturingCompleteBlock(NO, filePath, nil);
                             }
                         });
                     }
                 }
                 else{
                     this.isProcessing = NO;
                     dispatch_async(this.savingImageQueue, ^{
                         self.capturingCompleteBlock(NO,filePath,nil);
                     });
                 }
                 
                 if (this.cameraDidCapturePhotoBlock) {
                     dispatch_async(this.previewOutputQueue, ^{
                         this.cameraDidCapturePhotoBlock();
                     });
                 }
             });
         }];
    }
    else {
        this.isProcessing = NO;
    }
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
    AVCaptureConnection *videoConnection = nil;
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [port.mediaType isEqual:mediaType] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    return videoConnection;
}

#pragma mark -
#pragma mark - Capturing live-view

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (
        self == nil
        ||
        self.applicationIsActive == NO
        ||
        self.isVideoCapturing == NO
        ||
        self.currentCamera == nil
        ) return;
    
    
    if (!self.clearPreviewLayerIsReady && self.cameraDidReadyBlock) {
        dispatch_async(self.previewOutputQueue, ^{
            self.cameraDidReadyBlock();
            self.clearPreviewLayerIsReady = YES;
        });
    }
    
    if (
        self.isProcessing
        //||
        //!self.isFilterEnabled
        ) return;
    
    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    if ( connection == _previewConnection )
    {
        
        if (self.photoOutput.capturingStillImage) return;
        
        // This is a shallow queue, so if image
        // processing is taking too long, we'll drop this frame for preview (this
        // keeps preview latency low).
        OSStatus err = CMBufferQueueEnqueue(_previewBufferQueue, sampleBuffer);
        
        if ( !err ) {
            CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(_previewBufferQueue);
            if (sbuf)
            {
                
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sbuf);
                
                if (_hasDownScale) {
                    
                    if (self.videoDimensions.width == 0 && self.videoDimensions.height == 0)
                        self.videoDimensions = CMVideoFormatDescriptionGetDimensions( formatDescription );
                    
                    CGFloat scale = self.downScaleFactor;
                    
                    //
                    // downscale output image...
                    //
                    CIImage *inputImage  = [CIImage imageWithCVPixelBuffer:pixelBuffer];
                    CIImage *scaledImage = [inputImage imageByApplyingTransform : CGAffineTransformMakeScale ( scale , scale ) ];
                    
                    //
                    // prepare compatible pixel buffer
                    // https://developer.apple.com/library/ios/qa/qa1781/_index.html
                    //
                    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey,
                                                           nil];
                    
                    //
                    // create new frame buffer
                    //
                    CVPixelBufferCreate(kCFAllocatorSystemDefault,
                                        (size_t)(self.videoDimensions.width  * scale),
                                        (size_t)(self.videoDimensions.height * scale),
                                        kCVPixelFormatType_32BGRA,
                                        (__bridge CFDictionaryRef)pixelBufferAttributes,
                                        &pixelBuffer);
                    
                    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
                    
                    //
                    // render scaled buffer to frame buffer
                    //
                    [_ciContext render:scaledImage toCVPixelBuffer:pixelBuffer];
                    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
                }
                
                if (!self.liveView.isPaused) {
                    if ([self.liveView.source respondsToSelector:@selector(updateFromPixelBuffer:)]) {
                        DPPixelBufferProvider *provider = (DPPixelBufferProvider*)self.liveView.source;
                        [provider updateFromPixelBuffer:pixelBuffer];                                                
                    }
                }
                
                CFRelease(sbuf);
            }
            
            else {
                NSLog(@" *** queue frame dropped ");
            }            
        }
        else{
            NSLog(@" *** queue frame: %i", (int)err);
        }
    }
}

- (void) resetLiveViewAnalizers{
    //self.liveViewFilter.frameSkipNumber = kDPGL_LiveViewFrameNumberSkip;    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), self.previewOutputQueue, ^{
        //self.liveViewFilter.frameSkipNumber = kDPGL_LiveViewFrameNumberSteadySkip;
    });
}

- (void)onPositionDidChange:(NSNotification *)notification {
    [self resetLiveViewAnalizers];
}

- (void)onOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = (UIDeviceOrientation)[notification.userInfo[@"orientation"] integerValue];    
    [self rotationChanged:orientation];
}

- (void)rotationChanged:(UIDeviceOrientation)orientation {
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
}

@end
