//
//  DPThumbFilter.h
//  DegradrCore3
//
//  Created by denn on 11.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"

@interface DPThumbFilter : DPFilter
@property(nonatomic, assign) BOOL     isInverted;
@property(nonatomic, assign) BOOL     isSquared;
@property(nonatomic, assign) CGFloat  imageSize;
@end
