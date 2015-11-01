//
//  NSData+DPImageProvider.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 07/07/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "NSData+DPImageProvider.h"
#import "DPImageProvider.h"

#include <jconfig.h>
#include <jerror.h>
#include <jpeglib.h>
#include <errno.h>

/**
 * Save jpeg in NSMutableData object
 */
typedef struct {
    struct jpeg_destination_mgr pub;
    void   *jpegData;
} mem_destination_mgr;

typedef mem_destination_mgr *mem_dest_ptr;

#define BLOCK_SIZE 4096

METHODDEF(void) init_destination(j_compress_ptr cinfo)
{
    mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;
    NSMutableData  *data = (__bridge NSMutableData *)(dest->jpegData);
    dest->pub.next_output_byte = (JOCTET *)data.mutableBytes;
    dest->pub.free_in_buffer   = data.length;
}

METHODDEF(boolean) empty_output_buffer(j_compress_ptr cinfo)
{
    mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;
    NSMutableData  *data = (__bridge NSMutableData *)(dest->jpegData);
    
    size_t oldsize = data.length;
    [data setLength: oldsize + BLOCK_SIZE];
    
    dest->pub.next_output_byte = &data.mutableBytes[oldsize];
    dest->pub.free_in_buffer   =  data.length - oldsize;
    
    return true;
}

METHODDEF(void) term_destination(j_compress_ptr cinfo)
{
    mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;
    NSMutableData  *data = (__bridge NSMutableData *)(dest->jpegData);
    [data setLength:data.length-dest->pub.free_in_buffer];
}

static GLOBAL(void) jpeg_mem_dest_dp(j_compress_ptr cinfo, NSData* data)
{
    mem_dest_ptr dest;
    
    if (cinfo->dest == NULL) {
        cinfo->dest = (struct jpeg_destination_mgr *)
        (*cinfo->mem->alloc_small)((j_common_ptr)cinfo, JPOOL_PERMANENT,
                                   sizeof(mem_destination_mgr));
    }
    
    dest = (mem_dest_ptr) cinfo->dest;
    
    dest->jpegData = (__bridge void *)(data);
    
    dest->pub.init_destination    = init_destination;
    dest->pub.empty_output_buffer = empty_output_buffer;
    dest->pub.term_destination    = term_destination;
}

@implementation NSData(DPImageProvider)

+ (NSData*) jpegWithImageProvider:(DPImageProvider *)provider quality:(CGFloat)qualityIn{
    
    __block NSMutableData *data = [NSMutableData dataWithCapacity:BLOCK_SIZE];
    
    [DPImageProvider writeJpegWithProvider:provider
                            writeInitBlock:^BOOL(void *in_cinfo, void **userData) {
                                struct jpeg_compress_struct *cinfo = in_cinfo;
                                [data setLength:BLOCK_SIZE];
                                jpeg_mem_dest_dp(cinfo, data);
                                return YES;
                            } writeFinishBlock:^(void *in_cinfo, void *userData) {
                            } quality:qualityIn error:nil
     ];
    
    return data;
}


@end