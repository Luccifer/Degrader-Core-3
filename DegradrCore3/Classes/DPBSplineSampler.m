//
//  DPBSplineSampler.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 20/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPBSplineSampler.h"

@implementation DPBSplineSampler

- (CGFloat) convolution: (CGFloat)t{
    float f = t;
    if( f < 0.0 )
    {
        f = -f;
    }
    
    if( f >= 0.0 && f <= 1.0 )
    {
        return ( 2.0 / 3.0 ) + ( 0.5 ) * ( f* f * f ) - (f*f);
    }
    else if( f > 1.0 && f <= 2.0 )
    {
        return 1.0 / 6.0 * pow( ( 2.0 - f  ), 3.0 );
    }
    return 1.0;
}

- (CGFloat) kernelWidth{ return 2.0f;}

@end
