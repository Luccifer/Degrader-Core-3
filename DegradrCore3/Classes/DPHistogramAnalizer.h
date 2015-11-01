//
//  DPHistogramAnalizer.h
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"

@class DPHistogramAnalizer;

@protocol DPHistogramSolverProtocol <NSObject>
@property(nonatomic,weak) DPHistogramAnalizer *histogramAnalizer;
@required
- (void) updateSolverWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count;
@end

@interface DPHistogramAnalizer : DPFilter
/**
 * Create specific histogram analizer.
 */
- (instancetype) initWithHistogram:(DPFunction*)histogramFunction context:(DPContext *)aContext;

/**
 *  Region to analize.
 */
@property(nonatomic,assign)  DPCropRegion  region;

/**
 * Histogram analizer finish process block.
 */
@property(nonatomic, copy) void(^histogramSolverUpdatedBlock)(id<DPHistogramSolverProtocol> solver, float *histogram[4], CGSize imageSize, NSUInteger binsCount);
/**
 * It's invoked when all added solvers finished.
 */
@property(nonatomic, copy) void(^histogramSolversFinishedBlock)();

/**
 * Histogram analizer solvers.
 */
@property(nonatomic,readonly) NSArray *solverList;

/**
 *  Region to analize in percent of square.
 */
- (void) setCenterRegionInPercent:(CGFloat)region;

/**
 * Add solver.
 */
- (void) addSolver:(id<DPHistogramSolverProtocol>)solver;

/**
 * Remove solver.
 */
- (void) removeSolver:(id<DPHistogramSolverProtocol>)solver;

/**
 * Remove all solvers.
 */
- (void) removeAllSolvers;

/**
 * Evaluate solvers.
 */
- (void) evalSolversWithHistogram:(float **)histogram withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count;

@end
