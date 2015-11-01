//
//  DPConstants.h
//  DegradrCore3
//
//  Created by denn on 13.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#ifndef DegradrCore3_DPConstants_h
#define DegradrCore3_DPConstants_h

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

#define DP_CORE_VERSION  3

#define DP_QUEUE_PREFIX "com.degradr."
#define DP_VERTEX_DEF_FUNCTION   @"vertex_passthrough"
#define DP_VERTEX_VIEW_FUNCTION  @"vertex_passview"
#define DP_FRAGMENT_DEF_FUNCTION @"fragment_passthrough"
#define DP_KERNEL_DEF_FUNCTION   @"kernel_passthrough"

static const NSString   *kDP_coreVersionKey           = @"DegradrCoreVersion";
static const NSString   *kDP_imageOrientationKey      = @"Orientation";
static const NSString   *kDP_imageSourceExposureMode  = @"SourceExposureMode";

/**
 *
 */
static const CGFloat kDP_maximumZoomFactor                = 16;

/**
 *  Image bits per component, one componet is R or G or B, etc.
 */
static const NSUInteger kDP_bitsPerComponent               = 8;

/**
 *  How many frames precounting before will be proccessed.
 */
static const NSUInteger kDP_LiveViewFramePrecounting       = 6;

/**
 *  Live view refresh interval. Base FPS is 60, 2 means 30 FPS
 */
static const NSUInteger kDP_LiveViewRefreshInterval        = 1;

/**
 *  Frame rate for camera input device.
 */
static const NSUInteger kDP_LiveViewFrameRate              = 60/kDP_LiveViewRefreshInterval;

/**
 * Skip frames to do live-view processing when camer is in steady mode
 */
static const NSUInteger kDP_LiveViewFrameNumberSteadySkip  = (NSUInteger)(kDP_LiveViewFrameRate/2);

/**
 * Skip frames to do live-view processing 
 */
static const NSUInteger kDP_LiveViewFrameNumberSkip        = 4;

#endif
