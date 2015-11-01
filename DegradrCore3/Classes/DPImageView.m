//
//  DPImageView.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPImageView.h"

@implementation DPImageView
{
    BOOL inProgress;
}

- (void) setIsFilterDisabled:(BOOL)isFilterDisabled{
    [super setIsFilterDisabled:isFilterDisabled];
    [self redraw];
}

- (void) setFilter:(DPFilter *)filter{    
    [super setFilter:filter];    
    [self redraw];
}

- (void) setSource:(DPImageProvider*)provider{
    [super setSource:provider];
    if (provider)
        [self redraw];
}


- (void) setFilterTransform:(DPTransform *)transform{
    [self redraw];
    [super setFilterTransform:transform];
}

- (void) stopRefreshing:(id)sender{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isPaused = YES;
        inProgress = NO;
    });
}

- (void) redraw{

    dispatch_async(dispatch_get_main_queue(), ^{
        self.frameInterval = 1;
        
        if (inProgress) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopRefreshing:) object:nil];
        }
        
        [super redraw];

        inProgress = YES;
        self.isPaused = NO;
        
        [self performSelector:@selector(stopRefreshing:) withObject:nil afterDelay:.5f];
    });    
}

@end
