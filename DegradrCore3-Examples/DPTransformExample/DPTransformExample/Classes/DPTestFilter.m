//
//  DPTestFilter.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPTestFilter.h"
#import "DPGrayWeightAnalizer.h"
#import "DPColors.h"
#import "DPGaussianBlur.h"
#import "DPAWBFilter.h"
#import "DPContrastFilter.h"


#import "DPAWBFilter.h"
#import "DPContrastFilter.h"

typedef struct {
    CGFloat   weight;
} DPShadowsOption;

typedef struct {
    DPAWBAdjustment   adjustment;
    CGFloat           yellowsSaturation;
}DPAWBOptions;

@interface DPTestAdjustments : NSObject

@property (nonatomic, assign) DPAWBOptions          sourceAWB;
@property (nonatomic, assign) DPContrastAdjustment  sourceContrast;
@property (nonatomic, assign) DPShadowsOption       sourceShadows;

@end

@implementation DPTestAdjustments

- (instancetype) init{
    self = [super init];
    
    if (self) {
        self.sourceAWB = (DPAWBOptions){
            (DPAWBAdjustment){
                (GLKVector4){0.5f,0.5f,0.5f,1.0f},
                1.0f
            },
            0.0f
        };
    }
    
    return self;
}

@end

@interface DPTestFilter()

@property (nonatomic, strong) DPTestAdjustments     *adjustment;
@property (nonatomic, strong) DPFilter              *downsampleFilter;
@property (nonatomic, strong) DPHistogramAnalizer   *histogramAnalizer;
@property (nonatomic, strong) DPGrayWeightAnalizer  *grayAnalizer;
@property (nonatomic, strong) DPGaussianBlur        *gaussianBlurFilter;

@property (nonatomic, strong) DPAWBFilter           *awbFilter;
@property (nonatomic, strong) DPContrastFilter      *contrastFilter;

@end

@implementation DPTestFilter
{
    DPFunction *passthrough;
    DPFunction *adjust_saturation;
}


#pragma mark -
#pragma mark - Constructors

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithVertex:@"vertex_passthrough" withFragment:@"fragment_passthrough" context:aContext];
    
    if (self) {
        
        self.frameSkipNumber  = kDP_LiveViewFrameNumberSkip;
        self.frameSkipCounter = _frameSkipNumber;
        
        __weak typeof(self) this=self;
        
        self.processTexture = ^(DPTextureRef texture){
            
            if (this.frameSkipCounter >= this.frameSkipNumber) {
                
                this.downsampleFilter.source = [DPImageProvider newWithTexture:texture context:this.downsampleFilter.context];
                [this.downsampleFilter texture];
                
                this.frameSkipCounter = 0;
            }
            
            this.frameSkipCounter++;
        };
        
        [self addFilter:self.awbFilter];
        [self addFilter:self.contrastFilter];
    }
    return self;
}

#pragma mark -
#pragma mark - Adjustments


- (void) adjustAll{
    
    //
    // AWB
    //
    [self.awbFilter setAdjustment: self.adjustment.sourceAWB.adjustment];
    
    //
    // Contrast
    //
    [self.contrastFilter setAdjustmentContrast:self.adjustment.sourceContrast];
}

#pragma mark -
#pragma mark - Filters


- (DPAWBFilter*)awbFilter{
    if (!_awbFilter) {
        _awbFilter = [DPAWBFilter newWithContext:self.context];
    }
    
    return _awbFilter;
}

- (DPContrastFilter*) contrastFilter{
    if (!_contrastFilter) {
        _contrastFilter = [DPContrastFilter newWithContext:self.context];
    }
    return _contrastFilter;
}

#pragma mark -
#pragma mark - Analizers

//
// Blur and downsample source image
//

- (DPGaussianBlur*) gaussianBlurFilter{
    if (!_gaussianBlurFilter) {
        _gaussianBlurFilter = [[DPGaussianBlur alloc] initWithContext:self.downsampleFilter.context];
        
        _gaussianBlurFilter.radius = 4 ;
        _gaussianBlurFilter.scale  = 1;
        _gaussianBlurFilter.functionThreads = 8;
        
        __weak typeof(self) this=self;
        
        _gaussianBlurFilter.processTexture = ^(DPTextureRef texture){
            
            DPImageProvider *ip = [DPImageProvider newWithTexture:texture context:this.gaussianBlurFilter.context];
            
            // 1.
            this.grayAnalizer.source = ip;
            
            // 2. finishing hear
            this.histogramAnalizer.source = ip;
        };
    }
    return _gaussianBlurFilter;
}

//
// Downsample source image to analize
//

//-(void) setTransform:(DPTransform *)transform{
//    [super setTransform:transform];
//    self.downsampleFilter.transform = [transform copy];
//    self.downsampleFilter.transform.resampleFactor = 0.5;
//}

- (DPFilter*) downsampleFilter{
    if (!_downsampleFilter) {
        _downsampleFilter = [[DPFilter alloc] initWithVertex:@"vertex_passthrough" withFragment:@"fragment_passthrough" context:self.context];
        
        
        _downsampleFilter.transform = [self.transform copy];
        _downsampleFilter.transform.resampleFactor = 0.5;
        
        __weak typeof(self) this=self;
        
        _downsampleFilter.processTexture = ^(DPTextureRef texture){
            this.gaussianBlurFilter.source = [DPImageProvider newWithTexture:texture context:this.downsampleFilter.context];
            [this.gaussianBlurFilter texture];
        };
        
    }
    return _downsampleFilter;
}

- (DPGrayWeightAnalizer*) grayAnalizer{
    
    if (!_grayAnalizer) {
        _grayAnalizer = [[DPGrayWeightAnalizer alloc] initWithContext:self.downsampleFilter.context];
        
        __weak typeof(self) this=self;
        
        _grayAnalizer.processingGrayWeightFinishedBlock = ^(GLfloat imageGrayWeight){
            
            DPAWBOptions options = this.adjustment.sourceAWB;
            
            GLfloat grayWeightThreshold = 27.0f / 100.0f;
            
            if (imageGrayWeight <= grayWeightThreshold) {
                options.adjustment.opacity = (grayWeightThreshold - imageGrayWeight)/grayWeightThreshold;
            }
            else
            options.adjustment.opacity = 0.0;
            
            options.adjustment.opacity = 1.0;
            
            //NSLog(@" *** DPGrayWeightAnalizer gray weight = %2.3f opacity = %2.3f", imageGrayWeight, options.adjustment.opacity);
            
            this.adjustment.sourceAWB = options;
        };
    }
    
    return _grayAnalizer;
}

//
// Histogram analizer
//
- (DPHistogramAnalizer*) histogramAnalizer{
    if (!_histogramAnalizer) {
        
        _histogramAnalizer = [DPHistogramAnalizer newWithContext:self.downsampleFilter.context];
        
        _histogramAnalizer.clippingShadows    = 0.1/100.0f;
        _histogramAnalizer.clippingHighlights = 0.1/100.0f;
        
        __weak typeof(self) this=self;
        
        _histogramAnalizer.processingAverageFinishedBlock = ^(GLKVector4 averageColor){
            
            DPAWBOptions    options = this.adjustment.sourceAWB;
            
            //GLKVector3 hsl = [DPColors rgba_2_HSL:averageColor];
            
            options.adjustment.averageColor = averageColor;
            
            this.adjustment.sourceAWB = options;
            
            //NSLog(@" *** DPHistogramAnalizer avarage color = [%2.3f,%2.3f,%2.3f  a=%2.3f] hue = %f", averageColor.r, averageColor.g, averageColor.b, averageColor.a, hsl.x);
        };
        
        _histogramAnalizer.processingLevelsRangeFinishedBlock = ^(GLKVector4 minL, GLKVector4 maxL){
            //NSLog(@" *** DPHistogramAnalizer levels min = [%2.3f,%2.3f,%2.3f  %2.3f]  max = [%2.3f,%2.3f,%2.3f  %2.3f]", minL.r, minL.g, minL.b, minL.a, maxL.r, maxL.g, maxL.b, maxL.a);
            this.adjustment.sourceContrast = (DPContrastAdjustment){minL.a,maxL.a};
        };
        
        _histogramAnalizer.processingContrastFinishedBlock = ^(CGFloat weightShadows){
            //NSLog(@" *** DPHistogramAnalizer shadows weight: %2.3f", weightShadows);
        };
        
        _histogramAnalizer.processingAllFinished = ^(){
            //NSLog(@" *** Analizer finished.... \n");
            [this adjustAll];
        };
    }
    return _histogramAnalizer;
}

#pragma mark -
#pragma mark - Getters/Setters

- (DPTestAdjustments*) adjustment{
    if (!_adjustment) {
        _adjustment = [DPTestAdjustments new];
    }
    return _adjustment;
}

@end
