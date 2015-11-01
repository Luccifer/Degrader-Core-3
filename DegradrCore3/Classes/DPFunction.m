//
//  DPFunction.m
//  DegradrCore3
//
//  Created by denn on 14.06.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPFunction.h"

@interface DPFunction()
@property (nonatomic, strong) DPContext                   *context;
@property (nonatomic, strong) id<MTLFunction>             kernel;
@property (nonatomic, strong) id<MTLComputePipelineState> pipeline;

@end

@implementation DPFunction

+ (instancetype) newFunction:(NSString *)functionName context:(DPContext *)context{
    return [[self alloc] initWithFunctionName:functionName context:context];
}

+ (instancetype) newFunction:(NSString *)functionName withLibrarySource:(NSString *)source context:(DPContext *)context{
    return [[self alloc] initWithFunctionName:functionName withLibrarySource:source context:context];
}

- (instancetype) initWithFunctionName:(NSString *)functionName context:(DPContext *)context{    
    return [self initWithFunctionName:functionName withLibrarySource:nil context:context];
}

- (instancetype) initWithFunctionName:(NSString *)functionName withLibrarySource:(NSString *)source context:(DPContext *)context{
    if ((self = [super init]))
    {
        NSError *error = nil;
        
        _name = functionName;
        _context = context;
        
        _resampleFactor = (DPVector2){1.0f,1.0f};
        
        if (source) {
            _library = [_context.device newLibraryWithSource:source options:NULL error:&error];
            
            if (error) {
                NSLog(@"Error occurred when compile library from source %@, %s:%i", error, __FILE__, __LINE__);
                return nil;
            }
        }
        else{
            _library = [_context.device newDefaultLibrary];
        }
        
        _kernel  = [_library newFunctionWithName:functionName];
        
        if (!_kernel) {
            NSLog(@"Error occurred when building compute pipeline for function %@: not found, %s:%i", functionName, __FILE__, __LINE__);
            return nil;
        }
        
        _pipeline = [_context.device newComputePipelineStateWithFunction:_kernel error:&error];
        
        if (error)
        {
            NSLog(@"Error occurred when building compute pipeline for function %@: %@, %s:%i ", functionName, error, __FILE__, __LINE__);
            return nil;
        }
    }
    
    return self;
}

@end
