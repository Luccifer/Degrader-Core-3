//
//  DPHistogramLayer.h
//  DegradrCore3
//
//  Created by denn on 03.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPHistogramAnalizer.h"

typedef struct {
    DPVector4 reds;
    DPVector4 greens;
    DPVector4 blues;
    DPVector4 lumas;
} DPHistogramLayerColors;

typedef struct {
    DPHistogramLayerColors colors;
    DPVector4 opacity;
    CGPoint    position;
    CGSize     size;
}DPHistogramLayerSettings;

@interface DPHistogramLayer : DPFilter<DPHistogramSolverProtocol>
@property (nonatomic, assign) DPHistogramLayerSettings settings;
- (void) updateReds:(const float *)reds greens:(const float *)greens blues:(const float *)blues lumas:(const float *)lumas;
@end
