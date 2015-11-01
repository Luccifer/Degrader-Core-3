//
//  DPCurveSplines.m
//  DegradrCore3
//
//  Created by denn on 19.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//
//  Acknowledgement:
//  https://github.com/BradLarson/GPUImage
//


#import "DPCurveSplines.h"
#import <UIKit/UIKit.h>
#import "DPMath.h"

@interface NSArray (DPGLExtention)
/**
 *  Hash lookup kye uses to find already prepared spline curve.
 *  Hash decreases precision floating in initial curve points to increase total perfomance...
 *  @return hash key
 */
- (NSString*) hashLookUp;
@end

@implementation NSArray(DPGLExtention)

- (NSString*) hashLookUp{
    
    NSMutableString *key = [[NSMutableString alloc] initWithString:@"Curve-"];
    
    for (NSValue *value in self) {
        CGPoint point = [value CGPointValue];
        [key appendFormat:@"%.2f-%.2f",point.x,point.y];
    }
    
    return key;
}

@end


@interface DPCurveSplines()
@property (nonatomic,strong) NSMutableDictionary  *splineCache;
@property (nonatomic,strong) DPContext *context;
@property (nonatomic, assign) GLubyte *toneCurveByteArray;

@property (nonatomic, strong) NSArray *redCurve;
@property (nonatomic, strong) NSArray *greenCurve;
@property (nonatomic, strong) NSArray *blueCurve;

@property (nonatomic,readonly) NSArray* defaultPoints;

@end

@implementation DPCurveSplines

@synthesize texture=_texture;
@synthesize defaultPoints=_defaultPoints;
@synthesize reds=_reds, greens=_greens, blues=_blues, rgbs=_rgbs;

- (void) dealloc{
    if (_toneCurveByteArray) {
        free(_toneCurveByteArray);
    }
}

- (NSArray*) defaultPoints{
    if (!_defaultPoints) {
        _defaultPoints = [NSArray arrayWithObjects:
                         [NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)],
                         [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)],
                         [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)],
                         nil];
    }
    return _defaultPoints;
}

- (instancetype) initWithContext:(DPContext *)aContext{
    self = [super init];
    
    if (self) {
        _context = aContext;
        _splineCache = [[NSMutableDictionary alloc] initWithCapacity:100];
    }
    
    return self;
}

- (DPTextureRef)texture{
    if (!_texture) {
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                     width:256
                                                                                                    height:1
                                                                                                 mipmapped:NO];
        _texture = [self.context.device newTextureWithDescriptor:textureDescriptor];
    }
    return _texture;
}


- (GLubyte) step:(NSNumber*)value{
    return (GLubyte)fmin(fmax([value floatValue], 0), 255);
}

- (GLubyte *)toneCurveByteArray{
    if (_toneCurveByteArray == NULL)
        _toneCurveByteArray = calloc(256 * 4, sizeof(GLubyte));
    return _toneCurveByteArray;
}

- (void)updateToneCurveTexture{
    
    if ( ([self.redCurve count] >= 256) && ([self.greenCurve count] >= 256) && ([self.blueCurve count] >= 256))
    {
        for (unsigned int currentCurveIndex = 0; currentCurveIndex < 256; currentCurveIndex++)
        {
            self.toneCurveByteArray[currentCurveIndex * 4]     = [self step:[self.redCurve   objectAtIndex:currentCurveIndex]];
            self.toneCurveByteArray[currentCurveIndex * 4 + 1] = [self step:[self.greenCurve objectAtIndex:currentCurveIndex]];
            self.toneCurveByteArray[currentCurveIndex * 4 + 2] = [self step:[self.blueCurve  objectAtIndex:currentCurveIndex]];
            self.toneCurveByteArray[currentCurveIndex * 4 + 3] = 255;
        }
        
        const  MTLRegion  region = MTLRegionMake2D(0, 0, 256, 1);        
        static NSUInteger bytesPerRow = 1024;
        
        [self.texture replaceRegion:region mipmapLevel:0 withBytes:self.toneCurveByteArray bytesPerRow:bytesPerRow];
    }        
}


- (NSArray*) createToneCurveForPoints:(NSArray*)pointsIn{
    NSUInteger width = 256;
    float      m = (float)(width-1);
    NSMutableArray *toneCurve = [NSMutableArray arrayWithCapacity:width];

    NSMutableArray *xPoints = [NSMutableArray new];
    
    NSMutableArray *points = [pointsIn mutableCopy];
    
    for (NSUInteger i=0; i<points.count; i++) {
        CGPoint point = [points[i] CGPointValue];
        point.x *=m;
        point.y *=m;
        points[i] = [NSValue valueWithCGPoint:point];
    }
    
    for (NSUInteger i=0; i<width; i++){
        [xPoints addObject:[NSNumber numberWithUnsignedInteger:i]];
    }
    
    NSArray *curve = [DPMathCurve make2DAdobeWithControls:points inXPoints:xPoints];
    
    for (NSUInteger i=0; i<width; i++) {
        toneCurve[i]=@([curve[i] CGPointValue].y);
    }
    
    return toneCurve;
}


#pragma mark -
#pragma mark - Composite curve
- (NSArray*) rgbs{
    if (!_rgbs) {
        _rgbs = [self.defaultPoints copy];
    }
    return _rgbs;
}

- (void) setRgbs:(NSArray *)newValue{
    _rgbs = [newValue copy];
    _redCurve = _greenCurve = _blueCurve = [self createToneCurveForPoints:_rgbs];
    [self updateToneCurveTexture];
}


#pragma mark -
#pragma mark - REDS
- (NSArray*) reds{
    if (!_reds) {
        _reds = [self.defaultPoints copy];
    }
    return _reds;
}

- (void)setReds:(NSArray *)newValue
{  
    _reds = [newValue copy];
    _redCurve = [self createToneCurveForPoints:_reds];
    [self updateToneCurveTexture];
}

- (NSArray*)redCurve{
    if (!_redCurve) {
        _redCurve = [self createToneCurveForPoints:self.reds];
    }
    return _redCurve;
}

#pragma mark -
#pragma mark - GREENS
- (NSArray*)greens{
    if (!_greens) {
        _greens = [self.defaultPoints copy];
    }
    return _greens;
}

- (void)setGreens:(NSArray *)newValue
{
    _greens = [newValue copy];
    _greenCurve = [self createToneCurveForPoints:_greens];
    [self updateToneCurveTexture];
}

- (NSArray*)greenCurve{
    if (!_greenCurve) {
        _greenCurve = [self createToneCurveForPoints:self.greens];
    }
    return _greenCurve;
}


#pragma mark - 
#pragma mark BLUES
- (NSArray*) blues{
    if (!_blues) {
        _blues=[self.defaultPoints copy];
    }
    return _blues;
}

- (void)setBlues:(NSArray *)newValue
{
    _blues = [newValue copy];
    _blueCurve = [self createToneCurveForPoints:_blues];
    [self updateToneCurveTexture];
}

- (NSArray*)blueCurve{
    if (!_blueCurve) {
        _blueCurve = [self createToneCurveForPoints:self.blues];
    }
    return _blueCurve;
}

@end
