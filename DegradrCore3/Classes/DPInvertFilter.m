//
//  DPInvertFilter.m
//  DegradrCore3
//
//  Created by denn on 11.07.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPInvertFilter.h"
#import "DPConstants.h"

@implementation DPInvertFilter
{
    DPFunction *kernel_function;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super initWithContext:aContext];
    if (self) {
        [self addFunction:[DPFunction newFunction:@"kernel_invert" context:self.context]];
    }
    return self;
}

@end
