//
//  GHTHoughSpaceFilter.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTHoughSpaceFilter.h"

@implementation GHTHoughSpaceFilter

- (instancetype)initWithShaderLibrary:(id<MTLLibrary>)shaderLibrary device:(id<MTLDevice>)device
{
    self = [super initWithShaderLibrary:shaderLibrary device:device];
    
    if (self)
    {
        self.functionName       = @"houghKernel";
    }
    
    return self;
}

- (void)addHoughSpaceKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                                  inTexture:(id <MTLTexture>)inTexture
                               outputBuffer:(id <MTLBuffer>)houghSpaceBuffer
{
    self.inTexture = inTexture;
    self.hsBuffer = houghSpaceBuffer;
    
    [self addKernelToComputeEncoder:computeEncoder];
}

- (void)addKernelToComputeEncoder:(id<MTLComputeCommandEncoder>)computeEncoder
{
    [super addKernelToComputeEncoder:computeEncoder];
    
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:self.m_Kernel];
        [computeEncoder setTexture:self.inTexture atIndex:0];
        [computeEncoder setBuffer:self.outHoughSpaceBuffer.buffer offset:self.outHoughSpaceBuffer.offset atIndex:0]; //Output Buffer
        [computeEncoder setBuffer:self.modelBuffer.buffer offset:self.modelBuffer.offset atIndex:1];
        [computeEncoder setBuffer:self.parameterBuffer.buffer offset:self.parameterBuffer.offset atIndex:2];
        
        [computeEncoder dispatchThreadgroups:self.m_LocalCount
                       threadsPerThreadgroup:self.m_WorkgroupSize];
        
    }
}
@end
