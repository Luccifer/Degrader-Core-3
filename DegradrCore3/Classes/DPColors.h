//
//  DPColors.h
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPMath.h"

@interface DPColors : NSObject
+ (DPVector3) rgba_2_HSL:(DPVector4) color;
+ (DPVector4) HSL_2_rgba:(DPVector3) hsl;
@end
