//
//  DPCore3.h
//  DegradrCore3
//
//  Created by denn on 10.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPMath.h"

#import "DPConstants.h"
#import "DPContext.h"
#import "DPColors.h"
#import "DPHistogramMath.h"
#import "DPTransform.h"

#import "DPArchiver.h"

#import "DPTextureProvider.h"
#import "DPImageProvider.h"
#import "DPUIImageProvider.h"
#import "DPImageFileProvider.h"
#import "DPNSDataProvider.h"
#import "DPImageURLProvider.h"
#import "DPPixelBufferProvider.h"

#import "DPFilter.h"
#import "DPPassFilter.h"
#import "DPAWBFilter.h"
#import "DPExposureFilter.h"
#import "DPBrightnessFilter.h"
#import "DPLevelsFilter.h"
#import "DPContrastFilter.h"
#import "DPCurveFilter.h"
#import "DPHSVFilter.h"

#import "DPGaussianBlur.h"

#import "DPSampleFilter.h"
#import "DPKernelSampler.h"
#import "DPBiLinearSampler.h"
#import "DPBiLinear3Sampler.h"
#import "DPTriangularSampler.h"
#import "DPBSplineSampler.h"
#import "DPFancySampler.h"
#import "DPCMRomSampler.h"
#import "DPLanczosSampler.h"
#import "DPPassSampler.h"

#import "DPUnsharpMaskFilter.h"
#import "DPResizeFilter.h"
#import "DPSmartResizeFilter.h"

#import "DPInvertFilter.h"
#import "DPThumbFilter.h"

#import "DPHistogramAnalizer.h"
#import "DPNeutralsAnalizer.h"
#import "DPHistogramAvarageSolver.h"
#import "DPHistogramEqualizationSolver.h"
#import "DPHistogramRangeSolver.h"
#import "DPHistogramZonesSolver.h"

#import "DPHistogramLayer.h"

#import "DPView.h"
#import "DPLiveView.h"
#import "DPImageView.h"
#import "DPCameraManager.h"
#import "DPMotionManager.h"

#import "NSData+DPImageProvider.h"
#import "UIImage+DPImageProvider.h"