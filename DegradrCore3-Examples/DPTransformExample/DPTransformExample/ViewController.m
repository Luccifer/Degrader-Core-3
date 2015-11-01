//
//  ViewController.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 10/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "ViewController.h"
#import "DPTestFilter.h"
#import "DPUIImageProvider.h"
#import "DPImageFileProvider.h"
#import <DPMotionManager.h>

#import <DPImageView.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define ScreenRect                          [[UIScreen mainScreen] bounds]
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height
#define heightOffset 20.0f

// pinch
#define MAX_PINCH_SCALE_NUM   100.f
#define MIN_PINCH_SCALE_NUM   1.0f

/**
 * Uniq string generator.
 */
@interface NSString(DegradrTest)
+ (NSString*) uniqueString;
@end

@implementation NSString(DegradrTest)
+ (NSString*) uniqueString
{
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);
    NSString	*uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return uuidString;
}
@end


/**
 *
 * DegradrCore3 example viewController.
 *
 */
@interface ViewController ()

//
// Views
//

/** 
 *  Camera Live-View container.
 */
@property (nonatomic, strong)  UIView            *liveView;

/**
 * View result image container.
 */
@property (nonatomic, strong)  DPImageView       *resultImageView;

/**
 * Camera manager.
 */
@property (nonatomic, strong)  DPCameraManager   *cameraManager;

//
// Filters
//

/**
 * Livew-View filter instance.
 */
@property (nonatomic, strong)  DPFilter          *liveViewFilter;

/**
 * Result-View filter instance.
 */
@property (nonatomic, strong)  DPFilter          *resultViewFilter;

/**
 * Image tranformation.
 */
@property (nonatomic, strong)  DPTransform       *transform;

/**
 * Keep here current image scale.
 */
@property (nonatomic, assign) CGFloat             currentScale;

/**
 * Keep here current image crop.
 */
@property (nonatomic, assign) DPCropRegion        currentCrop;

/**
 * Keep here current image relative position.
 */
@property (nonatomic, assign) CGPoint             currentPosition;

/**
 * Keep here current image rotation.
 */
@property (nonatomic, assign) CGFloat             currentAngle;

/**
 *  Temp scaler.
 */
@property (nonatomic, assign) CGFloat             preScaleNum;

/**
 * Keep here current image size.
 */
@property (nonatomic, assign) CGSize              currentImageSize;


@property (nonatomic,strong) NSString *documentsDirectory;
@property (nonatomic,strong) NSString *defaultImagesFolder;
@property (nonatomic,strong) NSString *lastPhotoFilePath;
@property (nonatomic,strong) NSString *developedImagesFolder;

@end

@implementation ViewController
{
    CGPoint rotationStartPoint;
    CGPoint positionStartPoint;
}

- (CGSize) cropSize:(CGFloat)ratio {
    
    CGFloat imageWidth  = ScreenWidth;
    CGFloat imageHeight = imageWidth / ratio;
    
    return CGSizeMake(imageWidth, imageHeight);
}

-(DPFilter *) liveViewFilter{
    if (!_liveViewFilter) {        
        _liveViewFilter         = [DPTestFilter newWithContext:[DPContext newContext]];
        
        //
        // apply default tranformation
        //
        _liveViewFilter.transform = [self.transform copy];
    }
    
    return _liveViewFilter;
}

- (DPFilter*) resultViewFilter{
    if (!_resultViewFilter) {        
        _resultViewFilter       = [DPTestFilter newWithContext:[DPContext newContext]];  
                
        //
        // apply default image transformations
        //
        _resultViewFilter.transform = self.transform;

    }    
    return _resultViewFilter;
}

- (DPTransform *) transform{
    if (!_transform) {
        
        //
        // make default transform 
        //
        
        _transform = [DPTransform new]; 
        
        // we can downscale here downscale input image, but this is less effective then makes provider texture smaller
        // transform.resampleFactor = 0.5;
        
        //
        // normalize image after camera orientation
        //
        //[_transform.encoder rotateRight];
        
        //
        // set crop region
        // crop transformation cuts an image and change frame size
        // offten cropping tranformation decreases common processing performanc
        // 
        // crop operation sets new image aspect ratio, so you need to set properly new view.bounds with new aspect ratio
        // 
        [_transform setCropRegion:(DPCropRegion){
            0.1,0.1,
            0.1,0.1
        }];
        
        _transform.keepAspectRatio = YES;
        
    }
    return _transform;
}


- (UIView*) liveView{
    
    if (!_liveView) {
        
        CGSize  size = [self cropSize:3./4.];
        
        _liveView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        
        _liveView.userInteractionEnabled = YES;
        _liveView.autoresizingMask = UIViewAutoresizingNone;
        
        _liveView.center = CGPointMake(ScreenWidth / 2, size.height / 2 + heightOffset);
        
        _liveView.backgroundColor = [UIColor yellowColor];
        [self.view insertSubview:_liveView atIndex:0];
        
    }
    return _liveView;
}

- (DPImageView*) resultImageView{
    if (!_resultImageView) {
        _resultImageView = [[DPImageView alloc] initWithFrame:self.liveView.frame];
        _resultImageView.autoresizingMask = ~UIViewAutoresizingNone;
        _resultImageView.contentMode = UIViewContentModeScaleAspectFit;
        _resultImageView.alpha = 1.0;
        _resultImageView.backgroundColor = [UIColor clearColor];
        _resultImageView.filter = self.resultViewFilter;
        
        //
        // scale
        //
        UIPinchGestureRecognizer *_pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];    
        [_pinch setDelaysTouchesEnded:NO];        
        [_resultImageView addGestureRecognizer:_pinch];

        
        //
        // rotate and move
        //
        UIPanGestureRecognizer *_pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector( handlePanGestureRecognizer: )];
        
        [_pan setDelaysTouchesEnded:NO];
        [_pan setMinimumNumberOfTouches:1];
        [_pan setMaximumNumberOfTouches:1];
        
        [_resultImageView addGestureRecognizer:_pan];

    }
    return _resultImageView;
}

- (DPCameraManager*)cameraManager {
    if (!_cameraManager) {
        _cameraManager = [[DPCameraManager alloc] initWithOutputContainerPreview:self.liveView];
        _cameraManager.liveViewFilter = self.liveViewFilter;
        _cameraManager.filterEnabled = YES;
    }
    return _cameraManager;
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.resultImageView.orientation = [DPMotionManager sharedManager].currentOrientation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentScale = 1.0f;
    self.currentAngle = 0.0f;
    
    self.defaultImagesFolder = @"images";
    self.developedImagesFolder = @"developed";
    
    //
    // make two view layers: live view and result view
    //
    [self.view insertSubview:self.resultImageView aboveSubview:self.liveView];
                
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [self.view addGestureRecognizer:longPressGesture];    
    
    //
    // handel focus
    //
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:    self action:@selector(cameraViewFocus:)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
    
    
    //
    // handle exposure
    //
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:   self action:@selector(cameraViewExposure:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    

    self.cameraManager.focusDidChange = ^(DPCameraManager *camera){
        NSLog(@" *** did change defocus lens position   = %f ", camera.focusLensPosition);
    };
    
    self.cameraManager.focusWillChange = ^(DPCameraManager *camera){
        NSLog(@" *** will change defocus lens position  = %f ", camera.focusLensPosition);
    };
    
    self.cameraManager.liveViewDidReadyBlock = ^{
        NSLog(@" *** camera did ready .... ");
    };
     
    __weak typeof(self) this = self;
    
    dispatch_queue_t developQueue = dispatch_queue_create("com.degradr.developing", DISPATCH_QUEUE_SERIAL);

    self.cameraManager.capturingCompleteBlock = ^(BOOL finished, NSString *filePath, NSDictionary *metadata){
        dispatch_async(developQueue, ^{
            @synchronized(developQueue){
                @autoreleasepool {
                    NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];

                    NSError *error;
                
                    DPImageFileProvider *imageProvider = [DPImageFileProvider newWithImageFile:filePath 
                                                                                       context:this.resultImageView.context
                                                          //
                                                          // if filter/view tranform property is not set the resampleFactor 
                                                          // downscale  input image here once.
                                                          //
                                                                                         maxSize:1000.0f 
                                                          ];
                                        
                    this.currentImageSize = CGSizeMake([imageProvider.texture width], [imageProvider.texture height]);

                    //
                    // set to default
                    //
                    this.currentScale = 1.0;
                    this.currentAngle = 0.0;
                    this.currentPosition = CGPointZero;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                    
                        //
                        // avoid live-view processing
                        //
                        [this.cameraManager pause];

                        //
                        // bind with new image provider
                        //
                        this.resultImageView.source = imageProvider;

                        //
                        // restore default tranformation
                        // view.tranform is a alias of view.filter.tranform
                        //
                        this.resultImageView.filterTransform = this.transform;
                        
                        //
                        // show result
                        //
                        this.resultImageView.hidden = NO;
                        [UIView animateWithDuration:0.3 animations:^{
                            this.resultImageView.alpha = 1.0;                            
                        }];                        
                    });
                                        
                    if (error) {
                        NSLog(@" *** %@", error);
                    }
                                        
                    NSLog(@" *** captured to: %@, time = %2.2f  finshed = %i", filePath, [NSDate timeIntervalSinceReferenceDate]-t1, finished);
                }
            }
        });
    };
    
    self.cameraManager.filterEnabled = YES;
    
    [self.cameraManager start];
    
    self.cameraManager.hardwareCompression = YES;
    self.cameraManager.compressionQuality  = 1.0;
    
    [[DPMotionManager sharedManager] startMotionHandler];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationDidChange:)
                                                 name:kMotionManagerRotationDidChangeNotification
                                               object:nil];
    
}

- (void)onOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = (UIDeviceOrientation)[notification.userInfo[@"orientation"] integerValue];
    self.resultImageView.orientation = orientation;
}


#pragma mark - 
#pragma mark - Handle image transformation

//
// Compute image scale
//
- (void)handlePinch:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [pinchGestureRecognizer numberOfTouches], i;
    
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [pinchGestureRecognizer locationOfTouch:i inView:self.resultImageView];
        CGPoint convertedLocation = [self.resultImageView.layer convertPoint:location fromLayer:self.resultImageView.layer.superlayer];
        
        if ( ! [self.resultImageView.layer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        _currentScale = _preScaleNum * pinchGestureRecognizer.scale;
        
        if ( _currentScale < MIN_PINCH_SCALE_NUM ) {
            _currentScale = MIN_PINCH_SCALE_NUM;
        } else if ( _currentScale > MAX_PINCH_SCALE_NUM ) {
            _currentScale = MAX_PINCH_SCALE_NUM;
        }
        
        [self doPinch];
    }
    
    if ( [pinchGestureRecognizer state] == UIGestureRecognizerStateEnded ||
        [pinchGestureRecognizer state] == UIGestureRecognizerStateCancelled ||
        [pinchGestureRecognizer state] == UIGestureRecognizerStateFailed ||
        [pinchGestureRecognizer state] == UIGestureRecognizerStateBegan) {
        
        _preScaleNum = _currentScale;
    }
}

- (void)doPinch {
    
    CGFloat maxScale = [self.cameraManager maximumZoomFactor];
    
    if ( self.currentScale > maxScale ) {
        self.currentScale = maxScale;
    }

    //
    // reset tranformation to default
    //
    DPTransform *transform = [self.transform copy];
    
    //
    // encode current scale
    //
    transform.scale=self.currentScale;
    
    //
    // encode current rotation
    //
    transform.rotationDegrees = -self.currentAngle;
    
    //
    // encode current position
    //
    transform.translation = self.currentPosition;

    //
    //   example how to can to do scaling by changing cropRegion
    //
    //    CGFloat w      = self.view.bounds.size.width * self.currentScale;   
    //    CGFloat offsetw = (w - self.view.bounds.size.width)/w/2.0;
    //    CGFloat h      = self.view.bounds.size.height * self.currentScale;   
    //    CGFloat offseth = (h - self.view.bounds.size.height)/w/2.0;
    //
    //    self.currentCrop = (DPCropRegion){
    //        offsetw,offsetw,
    //        offseth,offseth
    //    };
    //    
    //    transform.cropRegion = self.currentCrop;    

    self.resultImageView.filterTransform = transform;
}


//
// compute rotation and position
//
- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    UIGestureRecognizerState state = panGestureRecognizer.state;
    CGPoint touchPoint = [panGestureRecognizer locationInView:self.resultImageView];
    CGPoint velocity = [panGestureRecognizer velocityInView:self.resultImageView];
    
    switch (state) {
        case UIGestureRecognizerStateBegan:
            rotationStartPoint = touchPoint;
            positionStartPoint = touchPoint;
            break;
        case UIGestureRecognizerStateChanged:
        {
            
            //
            // reset transformation to default
            //
            DPTransform *transform = [self.transform copy];
            
            CGFloat positionDistanceX;
            CGFloat positionDistanceY;
            
            CGFloat xofset = ABS(positionStartPoint.x - touchPoint.x)/(self.view.bounds.size.width*self.view.contentScaleFactor);
            CGFloat yofset = ABS(positionStartPoint.y - touchPoint.y)/(self.view.bounds.size.height*self.view.contentScaleFactor);
            
            if (velocity.x<0.0)
                positionDistanceX= self.currentPosition.x - xofset;
            else
                positionDistanceX= self.currentPosition.x + xofset;
            
            if (velocity.y>0.0)
                positionDistanceY = self.currentPosition.y - yofset;
            else
                positionDistanceY = self.currentPosition.y + yofset;
            
            self.currentPosition = CGPointMake(positionDistanceX, positionDistanceY);
            
            
            //
            // encode scale
            //
            transform.scale=self.currentScale;
            
            //
            // encode rotaion
            //
            transform.rotationDegrees = - self.currentAngle;
            
            //
            // encode new position
            //
            transform.translation = self.currentPosition;
            
            //
            // applay tranformation and redraw image to view
            //
            self.resultImageView.filterTransform = transform;
            
            positionStartPoint = touchPoint;
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        default:
            rotationStartPoint = CGPointZero;
            positionStartPoint = CGPointZero;
            break;
    }
}


#pragma mark - 
#pragma mark - Camera management

- (void) longPressGesture:(UILongPressGestureRecognizer*)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.cameraManager.filterEnabled = NO;
    }
    else if (
             gesture.state == UIGestureRecognizerStateEnded
             ||
             gesture.state == UIGestureRecognizerStateCancelled
             ){
        self.cameraManager.filterEnabled = YES;
    }
}

- (void)cameraViewFocus:(UITapGestureRecognizer *)tgr
{
    
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        
        CGPoint location = [tgr locationInView:self.view];
        
        if (location.y<80.0) return;
        if (location.y>600.0) return;        
    }
}

- (void)cameraViewExposure:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.view];
        
        if (location.y<80.0) return;
        if (location.y>600.0) return;
        
        [self.cameraManager exposureAtPoint:location];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)capturePhoto:(UIButton *)sender {
    NSString *file = [self filePathForKey:nil];
    [self.cameraManager capturePhotoToFile: file];
}

- (IBAction)backToCamera:(UIButton *)sender {
    self.resultImageView.source = nil;    
    self.resultImageView.alpha = 0.0;
    self.resultImageView.hidden = YES;
    [self.cameraManager resume];
}

- (IBAction)rotate:(UISlider *)sender {
    
    DPTransform *transform = [self.transform copy];

    self.currentAngle = - (sender.value-0.5f) * 180.0f;
    
    if (self.currentAngle>=360.0f) self.currentAngle -= 360.0f;
    if (self.currentAngle<=-360.0) self.currentAngle += 360.0f;
    
    //
    // encode scale
    //
    transform.scale=self.currentScale;
    
    //
    // encode rotaion
    //
    transform.rotationDegrees = -self.currentAngle;
    
    //
    // encode new position
    //
    transform.translation = self.currentPosition;
    
    //
    // applay tranformation and redraw image to view
    //
    self.resultImageView.filterTransform = transform;
}


- (NSString *)documentsDirectory {
    
    if (!_documentsDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _documentsDirectory = paths [0];
    }
    return _documentsDirectory;
}

- (void)setDefaultImagesFolder:(NSString *)defaultImagesFolder{
    _defaultImagesFolder = defaultImagesFolder;
    [self createDefaultFolder: defaultImagesFolder];
}

- (void)setDevelopedImagesFolder:(NSString *)developedImagesFolder{
    _developedImagesFolder = developedImagesFolder;
    [self createDefaultFolder:developedImagesFolder];
}

- (void)createDefaultFolder: (NSString *)defaultFolder {
    
    NSString *documentsDirectory = self.documentsDirectory;
    NSString *cacheDirectory = [documentsDirectory stringByAppendingPathComponent:defaultFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (NSString *)filePathForKey:(NSString *)fileKey {
    
    if (fileKey.length == 0) {
        fileKey = [NSString uniqueString];
    }
    
    return [NSString stringWithFormat:@"%@/%@/%@.jpeg",
            [self documentsDirectory],
            self.defaultImagesFolder, fileKey];
}

- (NSString *)developedPathForKey:(NSString *)fileKey {
    
    if (fileKey.length == 0) {
        fileKey = [NSString uniqueString];
    }
    
    return [NSString stringWithFormat:@"%@/%@/%@.jpeg",
            [self documentsDirectory],
            self.developedImagesFolder, fileKey];
}


@end
