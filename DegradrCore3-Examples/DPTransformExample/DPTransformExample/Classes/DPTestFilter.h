//
//  DPTestFilter.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"
#import "DPCameraManager.h"
#import "DPFilter.h"
#import "DPView.h"
#import "DPUIImageProvider.h"
#import "DPHistogramAnalizer.h"


@interface DPTestFilter : DPFilter

//
// reduce anilize computation
//
@property (nonatomic, assign) NSUInteger           frameSkipNumber;
@property (nonatomic, assign) NSUInteger           frameSkipCounter;

@end
