//
//  DPView.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 10/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

#import "DPFilter.h"
#import "DPTextureProvider.h"
#import "DPImageProvider.h"

@class DPView;

@protocol DPViewDelegate <NSObject>
@optional
- (void) view:(DPView*)view willChangeWithInput:(DPImageProvider*)source;
- (void) view:(DPView *)view didChangeWithInput:(DPImageProvider*)source;
- (void) view:(DPView *)view didDestinationRedraw:(DPImageProvider*)destination;
@end

typedef void (^viewReadyBlock)(void);

@interface DPView : UIView<DPContextProvider>

@property (nonatomic, assign)  BOOL                   isFilterDisabled;
@property (nonatomic, strong)  DPFilter              *filter;
@property (nonatomic, strong)  DPImageProvider       *source;
@property (nonatomic, strong)  DPTransform           *filterTransform;

@property (nonatomic, copy)    viewReadyBlock         firstFrameDidReceive;
@property (nonatomic, strong)  id<DPViewDelegate>     delegate;

@property (nonatomic, assign)  BOOL                   isPaused;
@property (nonatomic, assign)  NSUInteger             frameInterval;

@property (nonatomic, assign)  UIDeviceOrientation    orientation;

- (void) setOrientation:(UIDeviceOrientation)orientation animate:(BOOL) animate;

- (void) didCompletePresent;

- (void) redraw;

@end
