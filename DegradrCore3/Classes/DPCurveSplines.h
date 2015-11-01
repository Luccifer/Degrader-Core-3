//
//  DPCurveSplines.h
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFilter.h"

@interface DPCurveSplines : NSObject<DPTextureProvider>
@property(nonatomic, copy) NSArray *rgbs;
@property(nonatomic, copy) NSArray *reds;
@property(nonatomic, copy) NSArray *greens;
@property(nonatomic, copy) NSArray *blues;
@end
