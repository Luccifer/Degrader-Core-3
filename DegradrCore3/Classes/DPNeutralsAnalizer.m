//
//  DPGrayAnalizer.m
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPNeutralsAnalizer.h"

@interface DPNeutralsSolver()
@property(nonatomic,assign)   DPNeutralClipping  clipping;
@end

@implementation DPNeutralsSolver

@synthesize histogramAnalizer=_histogramAnalizer;

- (void) updateSolverWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{
    float *outputHistogramGray = histogram[3];
    
    CGFloat          fcount = (CGFloat)count ;
    
    DPNeutraCircle  circle = (DPNeutraCircle){
        outputHistogramGray[0]/fcount/255.0f,
        outputHistogramGray[1]/fcount/255.0f,
        outputHistogramGray[2]/fcount/255.0f,
        outputHistogramGray[3]/fcount/255.0f,
        outputHistogramGray[4]/fcount/255.0f,
        outputHistogramGray[5]/fcount/255.0f
    };
    
    _weights = (DPNeutralWeights){
        outputHistogramGray[252]/fcount,
        outputHistogramGray[253]/fcount,
        outputHistogramGray[254]/fcount,
        outputHistogramGray[255]/fcount,
        circle
    };
    
    if (self.histogramAnalizer && self.histogramAnalizer.histogramSolverUpdatedBlock) {
        self.histogramAnalizer.histogramSolverUpdatedBlock(self, histogram, imageSize, count);
    }
}

@end

@interface DPNeutralsAnalizer()
@property (nonatomic, strong)   id<MTLBuffer>    clippingUniform;
@end

@implementation DPNeutralsAnalizer
{
    DPFunction *kernel_function;
}

@synthesize solver = _solver;

- (void) addSolver:(id<DPHistogramSolverProtocol>)solver{
    if (solver!=self.solver) {
        [super addSolver:solver];
    }
}

- (void) removeSolver:(id<DPHistogramSolverProtocol>)solver{
    if (solver!=self.solver) {
        [super removeSolver:solver];
    }
}

- (void) removeAllFilters{
    [super removeAllFilters];
    [super addSolver:self.solver];
}

- (DPNeutralsSolver*) solver{
    if (!_solver) {
        _solver = [DPNeutralsSolver new];
    }
    return _solver;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    
    self = [super initWithHistogram: kernel_function=[DPFunction newFunction:@"kernel_neutralWeights" context:aContext ] context:aContext];
    
    if (self) {        
        [self setClipping: (DPNeutralClipping){
            0.1f,
            0.1f,
            0.1f
        }];
        [super addSolver:self.solver];
    }
    
    
    return self;
}

- (void) evalSolversWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{
    [super evalSolversWithHistogram:histogram withImageSize:imageSize withTotalBins:count];
}

- (void) setClipping:(DPNeutralClipping)clipping{
    _clipping = clipping;
    if (!_clippingUniform) {
        _clippingUniform  = [self.context.device newBufferWithLength:sizeof(clipping) options:MTLResourceOptionCPUCacheModeDefault];
    }
    memcpy([_clippingUniform contents], &clipping, sizeof(clipping));
}

- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    if (function == kernel_function) {
        [super configureFunction:nil uniform:commandEncoder];
        [commandEncoder setBuffer:_clippingUniform offset:0 atIndex:2];
    }
}
@end
