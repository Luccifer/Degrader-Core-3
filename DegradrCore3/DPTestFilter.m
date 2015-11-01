//
//  DPTestFilter.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPTestFilter.h"
#import "DPCore3.h"

@implementation DPTestAdjustments

- (instancetype) init{
    self = [super init];
    if (self) {
    }
    return self;
}

@end

@interface DPTestFilter()//<DPFilterDelegate>

@property (nonatomic, strong) DPCurveFilter          *curveFilter;
@property (nonatomic, strong) DPHSVFilter            *hsvFilter;
@property (nonatomic, strong) DPHistogramAnalizer    *histogramAnalizer;
@property (nonatomic, strong) DPNeutralsAnalizer     *neutralsAnalizer;

@property (nonatomic, strong) DPHistogramLayer       *histogramLayer;
@property (nonatomic, strong) DPHistogramRangeSolver *imageRangeSolver;
@property (nonatomic, strong) DPHistogramZonesSolver *imageZonesSolver;

@end

@implementation DPTestFilter

#pragma mark -
#pragma mark - Constructors

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithVertex:@"vertex_passthrough" withFragment:@"fragment_passthrough" context:aContext];
    
    if (self) {
        
        //[self addFilter:self.hsvFilter];
        [self addFilter:self.curveFilter];
        [self addFilter:self.histogramLayer];
        //[self addFilter:self.histogramAnalizer];
        
        __weak typeof(self) this = self;
        
        self.willStartProcessing = ^(DPImageProvider *source){
            this.histogramAnalizer.source = source;
            //this.neutralsAnalizer.source = source;
        };
    }
    return self;
}

#pragma mark -
#pragma mark - Adjustments


#pragma mark -
#pragma mark - Filters

- (DPHSVFilter*) hsvFilter{
    if (!_hsvFilter) {
        _hsvFilter = [DPHSVFilter newWithContext:self.context];
        _hsvFilter.adjustment = (DPHSVAdjustment){
            (DPVector4){0.0f, 0.0f, -0.5f,   1.0f}, // reds
            (DPVector4){0.0f, 0.0f, -0.5f,   1.0f}, // yellows
            (DPVector4){0.0f, 0.0f,  0.0f,   1.0f}, // greens
            (DPVector4){0.0f, 0.0f, -0.2f,   1.0f}, // cyans
            (DPVector4){0.2f, 0.0f, -0.2f,   1.0f}, // blues
            (DPVector4){0.0f, 0.0f,  0.0f,   1.0f}, // magentas
            (DPBlending){DP_BLENDING_NORMAL, 1.0f}
        };

    }
    return _hsvFilter;
}

- (DPHistogramLayer*) histogramLayer{
    if (!_histogramLayer) {
        _histogramLayer = [DPHistogramLayer newWithContext:self.context];
    }
    
    return _histogramLayer;
}

- (DPCurveFilter*)curveFilter{
    if (!_curveFilter) {
        _curveFilter = [DPCurveFilter newWithContext:self.context];
        _curveFilter.splines.rgbs = @[
                                      [NSValue valueWithCGPoint:CGPointMake(0.0,       0.0)],
                                      [NSValue valueWithCGPoint:CGPointMake(40./255.,  16./255.)],
                                      [NSValue valueWithCGPoint:CGPointMake(170./255., 160./255.)],
                                      [NSValue valueWithCGPoint:CGPointMake(1.0,       1.0)],
                                      ];
    }
    return _curveFilter;
}

#pragma mark -
#pragma mark - Analizers

- (DPNeutralsAnalizer*) neutralsAnalizer{
    if (!_neutralsAnalizer) {
        _neutralsAnalizer = [DPNeutralsAnalizer newWithContext:self.context];
        _neutralsAnalizer.transform.resampleFactor = 0.5;
        //__weak typeof(self) this = self;

        _neutralsAnalizer.histogramSolversFinishedBlock = ^(){
            //NSLog(@" #### NEUTRAL SOLVER DID FINISH PROCESSING: neutrals = %f", this.neutralsAnalizer.solver.weights.neutrals);
        };
    }
    return  _neutralsAnalizer;
}

- (DPHistogramAnalizer*) histogramAnalizer{
    if (!_histogramAnalizer) {
        
        _histogramAnalizer = [DPHistogramAnalizer newWithContext:self.context];
        _histogramAnalizer.transform.resampleFactor = 0.5;
        
        [_histogramAnalizer addSolver:self.histogramLayer];
        [_histogramAnalizer addSolver:self.imageRangeSolver];
        [_histogramAnalizer addSolver:self.imageZonesSolver];
        
        __weak typeof(self) this = self;

        _histogramAnalizer.histogramSolversFinishedBlock = ^(){
            
           // NSLog(@" *** Analizer finished.... \n");
//            NSLog(@" #### NEUTRAL SOLVER DID FINISH PROCESSING: min = [%2.3f,%2.3f,%2.3f,%2.3f]  min = [%2.3f,%2.3f,%2.3f,%2.3f]",
//                  this.imageRangeSolver.min.r,
//                  this.imageRangeSolver.min.g,
//                  this.imageRangeSolver.min.b,
//                  this.imageRangeSolver.min.a,
//                  this.imageRangeSolver.max.r,
//                  this.imageRangeSolver.max.g,
//                  this.imageRangeSolver.max.b,
//                  this.imageRangeSolver.max.a
//                  );
            
            if (/* DISABLES CODE */ (1)){
                CGFloat    *zone   = this.imageZonesSolver.interest.zones;
                DPVector3 spots   = this.imageZonesSolver.interest.spots;
                DPVector3 dr      = this.imageZonesSolver.interest.range;
                DPVector3 balance = this.imageZonesSolver.interest.balance;
                
                NSMutableString *s=[NSMutableString new];
                
                [s
                 appendFormat:    @"\n *** Zones                = [0,     I,     II,    III,   IV,    V,     VI,    VII,   VIII,  IX,    X,     XI   ]        Shad  Avrg  HighL      Low   Mid   High\n" ];
                [s
                 appendFormat:    @" *** Zones                = [%2.3f, %2.3f, %2.3f, %2.3f, %2.3f, %2.3f, %2.3f, %2.3f, %2.3f, %2.3f, %2.3f, %2.3f] spots=[%2.3f,%2.3f,%2.3f] dr=[%2.3f,%2.3f,%2.3f]\n", zone[0], zone[1], zone[2], zone[3], zone[4], zone[5], zone[6], zone[7], zone[8], zone[9], zone[10], zone[11], spots.x, spots.y, spots.z, dr.x, dr.y, dr.z];
                
                [s
                 appendFormat:    @" *** Avg.Zones            = [%2.3f]  balance = [%2.3f, %2.3f, %2.3f] \n", sqrt(pow(dr.y, 2.0)+ pow(dr.z,2.0)), balance.x,balance.y, balance.z];
                
                //NSLog(@"  ### %@", s);
            }

        };
    }
    return _histogramAnalizer;
}

#pragma mark -
#pragma mark - Solvers

- (DPHistogramRangeSolver*) imageRangeSolver{
    if (!_imageRangeSolver) {
        _imageRangeSolver = [DPHistogramRangeSolver new];
        _imageRangeSolver.clippingShadows    = 0.1f/100.0f;
        _imageRangeSolver.clippingHighlights = 0.1f/100.0f;
    }
    return _imageRangeSolver;
}

- (DPHistogramZonesSolver*) imageZonesSolver{
    if (!_imageZonesSolver) {
        _imageZonesSolver = [DPHistogramZonesSolver new];
    }
    return _imageZonesSolver;
}

#pragma mark -
#pragma mark - Getters/Setters

- (void) setHistogramRegion:(CGFloat)histogramRegion{
    _histogramRegion = histogramRegion;
    [self.histogramAnalizer setCenterRegionInPercent:histogramRegion];
}

@end
