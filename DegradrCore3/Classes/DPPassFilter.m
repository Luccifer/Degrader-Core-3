//
//  DPPassFilter.m
//  DegradrCore3
//
//  Created by denn on 13.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPPassFilter.h"
#import "DPConstants.h"

@implementation DPPassFilter
- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithVertex:DP_VERTEX_DEF_FUNCTION withFragment:DP_FRAGMENT_DEF_FUNCTION context:aContext];
    return self;
}
@end
