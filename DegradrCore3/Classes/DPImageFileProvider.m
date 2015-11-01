//
//  DPImageFileProvider.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 23/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPImageFileProvider.h"
#import "DPConstants.h"

#import <ImageIO/ImageIO.h>
#import <stdio.h>
#import <jpeglib.h>
#import <setjmp.h>


struct DPJpegErrorMgr {
    struct jpeg_error_mgr pub;    /* "public" fields */    
    jmp_buf setjmp_buffer;        /* for return to caller */
};

typedef struct DPJpegErrorMgr         *DPJpegErrorRef;
typedef struct jpeg_decompress_struct  DPJpegDecompressInfo;

/*
 * Here's the routine that will replace the standard error_exit method:
 */

static void my_error_exit (j_common_ptr cinfo)
{
    /* cinfo->err really points to a my_error_mgr struct, so coerce pointer */
    DPJpegErrorRef myerr = (DPJpegErrorRef) cinfo->err;
    
    /* Always display the message. */
    /* We could postpone this until after returning, if we chose. */
    (*cinfo->err->output_message) (cinfo);
    
    /* Return control to the setjmp point */
    longjmp(myerr->setjmp_buffer, 1);
}


@implementation DPImageFileProvider
+ (instancetype) newWithImageFile:(NSString *)filePath context:(DPContext *)aContext maxSize:(CGFloat)maxSize orientation:(UIImageOrientation)orientation{
    DPImageFileProvider *this = [super newWithContext:aContext];
    if (this) {
        NSError *error;
        [this updateFromImageFile:filePath error:&error maxSize:maxSize orientation:orientation];
        if (error) {
            NSLog(@" *** DPImageFileProvider: %@", error);
            return nil;
        }
    }
    return this;
}

+ (instancetype) newWithImageFile:(NSString *)filePath context:(DPContext *)aContext maxSize:(CGFloat)maxSize{
    return [[self class] newWithImageFile:filePath context:aContext maxSize:maxSize orientation:UIImageOrientationLeft];
}

+ (instancetype) newWithImageFile:(NSString *)filePath context:(DPContext *)aContext{
    return [[self class] newWithImageFile:filePath context:aContext maxSize:0.0f];
}


- (void) updateFromImageFile:(NSString *)filePath error:(NSError *__autoreleasing *)error maxSize:(CGFloat)maxSize{
    return [self updateFromImageFile:filePath error:error maxSize:maxSize orientation:UIImageOrientationLeft];
}

- (void) updateFromImageFile:(NSString *)filePath error:(NSError *__autoreleasing *)error maxSize:(CGFloat)maxSize orientation:(UIImageOrientation)orientation{
    
    self.imageOrientation = orientation;
    
    const char *filename = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    DPJpegDecompressInfo cinfo;
    struct DPJpegErrorMgr jerr;
    FILE         *infile;           /* source file */
    JSAMPARRAY    buffer;           /* Output row buffer */
    int           row_stride;       /* physical row width in output buffer */
    
    
    if ((infile = fopen(filename, "rb")) == NULL) {
        if (error) {
            *error = [[NSError alloc ] initWithDomain:@""DP_QUEUE_PREFIX"jpeg.read"
                                                 code: ENOENT
                                             userInfo: @{
                                                         NSLocalizedDescriptionKey:  [NSString stringWithFormat:NSLocalizedString(@"Image file %@ can't be open", nil),filePath],
                                                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"File not found", nil),
                                                         }];
        }
        return;
    }
    
    /* Step 1: allocate and initialize JPEG decompression object */
    
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        
        if (error) {
            *error = [[NSError alloc ] initWithDomain:@""DP_QUEUE_PREFIX"jpeg.read"
                                                 code: ENOENT
                                             userInfo: @{
                                                         NSLocalizedDescriptionKey: NSLocalizedString(@"Not enough memory to write jpeg file", nil),
                                                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Not enough memory", nil),
                                                         }];
        }

        return;
    }
    jpeg_create_decompress(&cinfo);
    
    
    /* Step 2: specify data source (eg, a file) */
    
    jpeg_stdio_src(&cinfo, infile);
    
    
    /* Step 3: read file parameters with jpeg_read_header() */
    
    (void) jpeg_read_header(&cinfo, TRUE);
    
    
    /* Step 4: set parameters for decompression */

    cinfo.out_color_space = JCS_EXT_RGBA;
    
    /* In this example, we don't need to change any of the defaults set by
     * jpeg_read_header(), so we do nothing here.
     */
    
    float scale = 1.0;
    
    if (maxSize>0.0 && maxSize<fmin(cinfo.image_width,cinfo.image_height) ) {
        scale = fmin(maxSize/cinfo.image_width,maxSize/cinfo.image_height) ;
    }
        
    cinfo.scale_num   = scale<1.0f?1:scale;
    cinfo.scale_denom = scale<1.0f?(unsigned int)floor(1.0f/scale):1;
    
    /* Step 5: Start decompressor */
    
    (void) jpeg_start_decompress(&cinfo);

    row_stride = cinfo.output_width * cinfo.output_components;
    buffer = (*cinfo.mem->alloc_sarray)
    ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
    
    
    /* Step 6: while (scan lines remain to be read) */
    
    NSUInteger width  = cinfo.output_width;
    NSUInteger height = cinfo.output_height;
    
    DPTextureRef texture = self.texture;
    
    if (texture == nil
        ||
        [texture width]!=width
        ||
        [texture height]!=height
        ){
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                     width:width
                                                                                                    height:height
                                                                                                 mipmapped:NO];
        texture = [self.context.device newTextureWithDescriptor:textureDescriptor];
    }
    
    while (cinfo.output_scanline < cinfo.output_height) {
        
        (void) jpeg_read_scanlines(&cinfo, buffer, 1);
        
        [texture replaceRegion:MTLRegionMake2D(0, cinfo.output_scanline-1, cinfo.output_width, 1)
                        mipmapLevel:0
                          withBytes:buffer[0]
                        bytesPerRow:row_stride];
    }
    
    
    /* Step 7: Finish decompression */
    
    (void) jpeg_finish_decompress(&cinfo);
    
    
    /* Step 8: Release JPEG decompression object */
    
    jpeg_destroy_decompress(&cinfo);
    fclose(infile);
    
    self.texture =  texture;

}

@end
