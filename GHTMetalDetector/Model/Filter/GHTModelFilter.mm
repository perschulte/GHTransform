//
//  GHTModelFilter.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 24.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTModelFilter.h"

@interface GHTModelFilter()


@end

@implementation GHTModelFilter

- (instancetype)initWithShaderLibrary:(id<MTLLibrary>)shaderLibrary device:(id<MTLDevice>)device
{
    self = [super initWithShaderLibrary:shaderLibrary device:device];
    
    if (self)
    {
        self.functionName       = @"modelKernel";
    }
    
    return self;
}

- (void)addModelKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                         outputTexture:(id <MTLTexture>)outTexture
{
    NSError *error = nil;
    if (computeEncoder)
    {
        if (!self.m_Kernel)
        {
            self.m_Kernel = [self kernelWithError:&error];
        }
        [computeEncoder setComputePipelineState:self.m_Kernel];
        [computeEncoder setTexture:outTexture atIndex:0];
        [computeEncoder setBuffer:self.modelBuffer.buffer offset:self.modelBuffer.offset atIndex:0];
        [computeEncoder setBuffer:self.parameter.buffer offset:self.parameter.offset atIndex:1];
        
        [computeEncoder dispatchThreadgroups:self.m_LocalCount
                       threadsPerThreadgroup:self.m_WorkgroupSize];
    }
}

@end
