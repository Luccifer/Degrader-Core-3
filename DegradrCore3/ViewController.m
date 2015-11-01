//
//  ViewController.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 10/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "ViewController.h"
#import "DPTestFilter.h"
#import "DPCore3.h"

#import <AssetsLibrary/AssetsLibrary.h>

#define ScreenRect                          [[UIScreen mainScreen] bounds]
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height
#define heightOffset 20.0f


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


@interface ViewController ()

@property (nonatomic, strong)  UIView            *liveView;
@property (nonatomic, strong)  DPCameraManager   *cameraManager;
@property (nonatomic, strong)  UIImageView       *resultImageView;
@property (nonatomic, strong)  DPTestFilter      *liveViewFilter;
@property (nonatomic, strong)  DPTestFilter      *previewViewFilter;

@property (nonatomic, strong) DPSoftUnsharpMaskFilter *unsharpMaskFilter;

@property (nonatomic, strong)  DPUIImageProvider  *imageProvider;


@property (nonatomic,strong) NSString *documentsDirectory;
@property (nonatomic,strong) NSString *defaultImagesFolder;
@property (nonatomic,strong) NSString *lastPhotoFilePath;

@property (nonatomic,strong) NSString *developedImagesFolder;


@end

@implementation ViewController

- (CGSize) cropSize:(CGFloat)ratio {
    
    CGFloat imageWidth  = ScreenWidth;
    CGFloat imageHeight = imageWidth / ratio;
    
    return CGSizeMake(imageWidth, imageHeight);
}

- (DPSoftUnsharpMaskFilter*) unsharpMaskFilter{
    if (!_unsharpMaskFilter) {
        _unsharpMaskFilter = [DPSoftUnsharpMaskFilter newWithContext:self.liveViewFilter.context];
    }
    return _unsharpMaskFilter;
}

-(DPTestFilter *) liveViewFilter{
    if (!_liveViewFilter) {        
        _liveViewFilter         = [DPTestFilter newWithContext:[DPContext new]];
        
        DPTransform   *transform = [DPTransform new];
        
        transform.cropRegion = (DPCropRegion){
            0.1,0.1,
            0.1,0.1,
        };
        
        //transform.cropRect= CGRectMake(0.2, 0.2, 0.2, 0.2 * 4/3 );
        
        //transform.scale = 2.0;
        
        _liveViewFilter.transform = transform;
                
        //[_liveViewFilter addFilter:self.unsharpMaskFilter];

    }
    
    return _liveViewFilter;
}

- (DPTestFilter*) previewViewFilter{
    if (!_previewViewFilter) {
        
        _previewViewFilter       = [DPTestFilter newWithContext:[DPContext newContext]];
        
        DPFunction *saturation = [DPFunction newFunction:@"kernel_adjustSaturation" context:_previewViewFilter.context];
        DPFunction *invert     = [DPFunction newFunction:@"kernel_invert" context:_previewViewFilter.context];
        
        [_previewViewFilter addFunction:saturation];
        [_previewViewFilter addFunction:invert];
    }
    
    return _previewViewFilter;
}

- (UIView*) liveView{
    
    if (!_liveView) {
        
        CGSize  size = [self cropSize:3./4.];
        
        _liveView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        
        _liveView.userInteractionEnabled = YES;
        _liveView.autoresizingMask = ~UIViewAutoresizingNone;
        
        _liveView.center = CGPointMake(ScreenWidth / 2, size.height / 2 + heightOffset);
        
        _liveView.backgroundColor = [UIColor yellowColor];
        [self.view insertSubview:_liveView atIndex:0];
        
    }
    return _liveView;
}

- (DPUIImageProvider*) imageProvider{
    if (!_imageProvider) {
        _imageProvider = [DPUIImageProvider newWithContext:[DPContext new]];
    }
    return _imageProvider;
}

- (DPCameraManager*)cameraManager {
    if (!_cameraManager) {
        _cameraManager = [[DPCameraManager alloc] initWithOutputContainerPreview:self.liveView];
        _cameraManager.liveViewFilter = self.liveViewFilter;
        _cameraManager.filterEnabled = YES;
    }
    return _cameraManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [[DPMotionManager sharedManager] startMotionHandler];
    
    self.defaultImagesFolder = @"images";
    self.developedImagesFolder = @"developed";
    
    _resultImageView = [[UIImageView alloc] initWithFrame:self.liveView.bounds];
    _resultImageView.autoresizingMask = ~UIViewAutoresizingNone;
    _resultImageView.contentMode = UIViewContentModeScaleAspectFit;
    _resultImageView.alpha = 0.0;
    _resultImageView.backgroundColor = [UIColor redColor];
    [self.liveView insertSubview:_resultImageView atIndex:0];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [self.liveView addGestureRecognizer:longPressGesture];
    
    
    //
    // focus
    //
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:    self action:@selector(cameraViewFocus:)];
    singleTap.numberOfTapsRequired = 1;
    [self.liveView addGestureRecognizer:singleTap];
    
    
    //
    // exposure
    //
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:   self action:@selector(cameraViewExposure:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.liveView addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    
    
    self.cameraManager.focusDidChange = ^(DPCameraManager *camera){
        NSLog(@" *** did change defocus lens position   = %f ", camera.focusLensPosition);
    };
    
    self.cameraManager.focusWillChange = ^(DPCameraManager *camera){
        NSLog(@" *** will change defocus lens position  = %f ", camera.focusLensPosition);
    };
    
    self.cameraManager.liveViewDidReadyBlock = ^{
        NSLog(@" *** camera live did ready .... ");
    };
    
    
    self.cameraManager.cameraDidReadyBlock = ^{
        NSLog(@" *** camera did ready .... ");
    };
    
    //__weak typeof(self) this = self;
    
    dispatch_queue_t developQueue = dispatch_queue_create("com.degradr.developing", DISPATCH_QUEUE_SERIAL);
    
    //
    // Create an instance of filter here to avoid overloading context recreations.
    //
    DPTestFilter    *degradrFilter      = [DPTestFilter newWithContext:[DPContext newContext]];
    
    self.cameraManager.capturingCompleteBlock = ^(BOOL finished, NSString *filePath, NSDictionary *metadata){
        dispatch_async(developQueue, ^{
            @synchronized(developQueue){
                @autoreleasepool {
                    NSError *error;
                    
                    ALAssetsLibrary *lib = [ALAssetsLibrary new];
                    
                    NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
                    
                    NSData *imageData = [NSData dataWithContentsOfFile:filePath];
                    
                    //degradrFilter.source = [DPImageFileProvider newWithImageFile:filePath context:degradrFilter.context maxSize:200.0f];
                    degradrFilter.source = [DPNSDataProvider newWithData:imageData context:degradrFilter.context maxSize:0.0f orientation:UIImageOrientationUp];
                                                                                                    
                    NSData *data = [NSData jpegWithImageProvider:degradrFilter.destination quality:0.7];
                    
                    [degradrFilter flush];
                    
                    [lib writeImageDataToSavedPhotosAlbum:data metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
                        NSLog(@" *** image saved to: %@    %@", assetURL, error);
                    }];
                    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationDidChange:)
                                                 name:kMotionManagerRotationDidChangeNotification
                                               object:nil];
    
    
    //
    // test 
    //
    
    //    CGFloat scale = 0.3;
    //        
    //    UIImage *testimage = [UIImage imageNamed:@"resampler_test.jpg"];
    //    
    //    DPResampleFilter *bSpline = [DPResampleFilter newWithContext:[DPContext new] type:DP_LANCZOS_SAMPLER];
    //    
    //    DPUIImageProvider *ip = [DPUIImageProvider newWithImage:testimage context:bSpline.context];
    //    
    //    [ip transformOrientation:UIImageOrientationUp];
    //    
    //    
    //    bSpline.input = ip;
    //    bSpline.transform.resampleFactor = scale;
    //    
    //    DPImageProvider *outimage = [DPImageProvider newWithTexture:bSpline.texture context:bSpline.context];
    //    
    //    UIImageWriteToSavedPhotosAlbum([UIImage imageWithImageProvider:outimage], nil, nil, nil);
    
}

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
#if 1
        CGPoint location = [tgr locationInView:self.view];
        
        if (location.y<80.0) return;
        if (location.y>600.0) return;
        
        NSLog(@" *** Focus  taplocation x = %f y = %f", location.x, location.y);
        [self.cameraManager focusAtPoint:location];
#else
        //
        // do defocus
        //
        
        self.cameraManager.focusLensPosition = -1.0;
#endif
    }
}

- (void)cameraViewExposure:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.view];
        
        if (location.y<80.0) return;
        if (location.y>600.0) return;
        
        NSLog(@" *** Exposure taplocation x = %f y = %f", location.x, location.y);
        
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

- (IBAction)valueChanged:(UISlider *)sender {
    self.liveViewFilter.histogramRegion = sender.value;
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

- (void)onOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = (UIDeviceOrientation)[notification.userInfo[@"orientation"] integerValue];
    NSLog(@" *** orientation changed to %li", (long)orientation);
}

@end
