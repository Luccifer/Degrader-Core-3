//
//  DPFancySampler.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 20/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFancySampler.h"

@implementation DPFancySampler
- (CGFloat) convolution: (CGFloat)t{
    if (t<-3.0f/2.0f) {
        return 0.0f;
    }
    else if (t>=-3.0f/2.0f && t<=-1.0f/2.0f){
        return 1.0f/2.0f * pow((t+3.0f/2.0f),2.0f);
    }
    else if (t>-1.0f/2.0f && t<1.0f/2.0f){
        return 3.0f/4.0f - pow(t, 2.0f);
    }
    else if (t>=1.0f/2.0f && t<=3.0f/2.0f){
        return 1.0f/2.0f * pow((t-3.0f/2.0f),2.0f);
    }
    return 0.0f;
}
- (CGFloat) kernelWidth{ return 2.0f;}

@end
