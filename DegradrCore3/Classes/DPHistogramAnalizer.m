//
//  DPHistogramAnalizer.m
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPHistogramAnalizer.h"
#import "DPConstants.h"
#import "UIImage+DPImageProvider.h"
#import <Accelerate/Accelerate.h>


//#define DP_USE_DSP_HISTOGRAM 1

@interface DPHistogramAnalizer()
@property (assign,atomic) BOOL inProgress;
@property (nonatomic,strong) NSMutableArray *priivateSolverList;
@end

typedef struct {
    uint reds[256];
    uint greens[256];
    uint blues[256];
    uint lumas[256];
    uint count;
}DPHistogramBuffer;

@implementation DPHistogramAnalizer
{
    id<MTLBuffer>    regionUniform;

    float            *outputHistogram[4];
    float            outputHistogramX[256];
    float            outputHistogramY[256];
    float            outputHistogramZ[256];
    float            outputHistogramW[256];

#ifdef DP_USE_DSP_HISTOGRAM
    NSUInteger       imageByteCount;
    void*            imageBytes;
    
    vImagePixelCount *histogram[4];
    vImagePixelCount histogramX[256];
    vImagePixelCount histogramY[256];
    vImagePixelCount histogramZ[256];
    vImagePixelCount histogramW[256];

#else
    uint            *histogram[4];
#endif
    id<MTLBuffer>      histogramBufferUniform;
    DPHistogramBuffer  histogramBuffer;    
    DPFunction         *kernel_function;
}

- (NSMutableArray*) priivateSolverList{
    if (!_priivateSolverList) {
        _priivateSolverList = [NSMutableArray new];
    }
    return _priivateSolverList;
}

- (void) addSolver:(id<DPHistogramSolverProtocol>)solver{
    if (solver) {
        [self.priivateSolverList addObject:solver];
    }
}

- (void) removeSolver:(id<DPHistogramSolverProtocol>)solver{
    if (solver) {
        [self.priivateSolverList removeObject:solver];
    }
}

- (void) removeAllSolvers{
    [self.priivateSolverList removeAllObjects];
}

- (NSArray*) solverList{
    return self.priivateSolverList;
}

- (void) __init__{
    
    [self setCenterRegionInPercent:1.0];
    
    outputHistogram[0] = outputHistogramX;
    outputHistogram[1] = outputHistogramY;
    outputHistogram[2] = outputHistogramZ;
    outputHistogram[3] = outputHistogramW;
    
#if DP_USE_DSP_HISTOGRAM
    histogram[0] = histogramX;
    histogram[1] = histogramY;
    histogram[2] = histogramZ;
    histogram[3] = histogramW;
#else
    histogram[0] = histogramBuffer.reds;
    histogram[1] = histogramBuffer.greens;
    histogram[2] = histogramBuffer.blues;
    histogram[3] = histogramBuffer.lumas;
#endif

}

- (void) setCenterRegionInPercent:(CGFloat)region{
    _region.left   = 0.5-region/2.0f;
    _region.top    = 0.5-region/2.0f;
    _region.right  = 1.0-(0.5+region/2.0f);
    _region.bottom = 1.0-(0.5+region/2.0f);
}

- (instancetype) initWithContext:(DPContext *)aContext{
#ifdef DP_USE_DSP_HISTOGRAM
    self = [super initWithVertex:DP_VERTEX_DEF_FUNCTION withFragment:DP_FRAGMENT_DEF_FUNCTION context:aContext];
    if (self) {
        [self __init__];
    }
#else
    self = [self initWithHistogram: kernel_function = [DPFunction newFunction:@"kernel_histogram" context:aContext] context:aContext];
    if (self) {
        self.functionThreads = 8;
    }
#endif
    return self;
}

- (void) configureFunction:(DPFunction *)function uniform:(id<MTLComputeCommandEncoder>)commandEncoder{
    
    @synchronized(self){
        
        if (self.functionList.count>0) {
            if (!histogramBufferUniform) {
                histogramBufferUniform = [self.context.device newBufferWithLength: sizeof(histogramBuffer) options:MTLResourceOptionCPUCacheModeDefault];
                memset([histogramBufferUniform contents], 0, [histogramBufferUniform length]);
            }
            [commandEncoder setBuffer:histogramBufferUniform offset:0 atIndex:0];

            if (!regionUniform) {
                regionUniform = [self.context.device newBufferWithLength:sizeof(_region) options:MTLResourceOptionCPUCacheModeDefault];
            }            
            memcpy([regionUniform contents], &_region, sizeof(_region));
            [commandEncoder setBuffer:regionUniform offset:0 atIndex:1];
        }
        
    }
}

- (instancetype) initWithHistogram:(DPFunction*)histogramFunction context:(DPContext *)aContext{
    
    self = [super initWithContext:aContext];
    
    if (self) {
        [self addFunction:histogramFunction];
        [self __init__];
    }
    return self;
}

- (void) setSource:(DPImageProvider*)source{
    [super setSource:source];
    if (source && source.texture) {
        [self processTexture: self.texture];
    }
}

- (void) processTexture:(DPTextureRef)texture{
    
    @synchronized(self){
        
        CGSize     imageSize      = CGSizeMake([texture width], [texture height]);
        
        if (histogramBufferUniform) {
            memcpy(&histogramBuffer, [histogramBufferUniform contents], sizeof(histogramBuffer));
        }
        
#ifdef DP_USE_DSP_HISTOGRAM

        size_t     currentImageByteCount = imageSize.width * imageSize.height * 4;

        if (imageByteCount != currentImageByteCount) {
            imageByteCount = currentImageByteCount;
            if (imageBytes != nil) {
                free(imageBytes);
            }
            imageBytes     = malloc(imageByteCount);
        }
        
        NSUInteger bytesPerRow    = imageSize.width * 4;
        
        MTLRegion region = MTLRegionMake2D(5, 5, imageSize.width-10, imageSize.height-10);
        [texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
        
        
        vImage_Buffer  buffer;
        buffer.data     = imageBytes;
        buffer.width    = [texture width];
        buffer.height   = [texture height];
        buffer.rowBytes = bytesPerRow;
        
        vImage_Error error = vImageHistogramCalculation_ARGB8888(&buffer,  self->histogram, 0);
        
        if (error) {
            NSLog(@" *** ### Histrogram error :%li  bytest per row %lu", error, (unsigned long)buffer.rowBytes);
        }
        //
        // accelerated convertion
        //
        int dim = sizeof(vImagePixelCount)/sizeof(unsigned int);
        dim = dim<1?1:dim;
        for (int i=0; i<4; i++) vDSP_vfltu32((const unsigned int *)self->histogram[i], dim, self->outputHistogram[i], 1, 256);        

        NSUInteger binsCount = currentImageByteCount;
#else
        
        //
        // accelerated convertion
        //
        int dim = sizeof(uint)/sizeof(unsigned int);
        dim = dim<1?1:dim;
        vDSP_vfltu32((const unsigned int *)histogramBuffer.reds,   dim, outputHistogram[0], 1, 256);        
        vDSP_vfltu32((const unsigned int *)histogramBuffer.greens, dim, outputHistogram[1], 1, 256);        
        vDSP_vfltu32((const unsigned int *)histogramBuffer.blues,  dim, outputHistogram[2], 1, 256);        
        vDSP_vfltu32((const unsigned int *)histogramBuffer.lumas,  dim, outputHistogram[3], 1, 256);

        NSUInteger binsCount = histogramBuffer.count;

#endif
        [self evalSolversWithHistogram:outputHistogram withImageSize:imageSize withTotalBins:binsCount];
        
        if (histogramBufferUniform && _histogramSolversFinishedBlock) {
            _histogramSolversFinishedBlock();
        }
        
#ifdef DP_USE_DSP_HISTOGRAM
#else
        memset([histogramBufferUniform contents], 0, [histogramBufferUniform length]);
#endif
    }
}

- (void) evalSolversWithHistogram:(float **)histogramIn withImageSize:(CGSize)imageSize withTotalBins:(NSUInteger)count{
    for (id<DPHistogramSolverProtocol> solver in self.solverList) {
        solver.histogramAnalizer = self;
        [solver updateSolverWithHistogram:histogramIn withImageSize:imageSize withTotalBins:count];
    }
}


- (void) dealloc{
#ifdef DP_USE_DSP_HISTOGRAM
    if (imageBytes)
        free(imageBytes);
#endif
}

@end
