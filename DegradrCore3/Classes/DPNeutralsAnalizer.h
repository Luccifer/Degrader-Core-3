//
//  DPGrayAnalizer.h
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramAnalizer.h"


typedef struct{
    float saturation;
    float black;
    float white;
} DPNeutralClipping;

typedef struct {
    CGFloat reds;
    CGFloat yellows;
    CGFloat greens;
    CGFloat cyans;
    CGFloat blues;
    CGFloat magentas;
}DPNeutraCircle;

typedef struct {
    CGFloat colored;
    CGFloat blacks;
    CGFloat whites;
    CGFloat neutrals;
    DPNeutraCircle circle;
}DPNeutralWeights;

@interface DPNeutralsSolver : NSObject<DPHistogramSolverProtocol>
@property(nonatomic,readonly) DPNeutralWeights  weights;
@end

@interface DPNeutralsAnalizer : DPHistogramAnalizer
@property(nonatomic,readonly) DPNeutralsSolver*   solver;
@property(nonatomic,assign)   DPNeutralClipping  clipping;
@end
