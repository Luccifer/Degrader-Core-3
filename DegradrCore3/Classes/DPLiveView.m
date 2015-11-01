//
//  DPLiveView.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 17/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPLiveView.h"


@interface DPLiveView()
@property (nonatomic,strong) id<DPTextureProvider> pixelBufferProvider;
@end

@implementation DPLiveView

- (DPImageProvider*) source{
    if (!_pixelBufferProvider) {
        _pixelBufferProvider = [DPPixelBufferProvider newWithContext:[DPContext newContext]];
    }
    return _pixelBufferProvider;
}

- (void) setSource:(DPImageProvider*)provider{
    _pixelBufferProvider = provider;
}

@end
