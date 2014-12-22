//
//  GHTHoughSpaceToTextureFilter.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 03.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTHoughSpaceToTextureFilter.h"

@implementation GHTHoughSpaceToTextureFilter
- (instancetype)initWithShaderLibrary:(id<MTLLibrary>)shaderLibrary device:(id<MTLDevice>)device
{
    self = [super initWithShaderLibrary:shaderLibrary device:device];
    
    if (self)
    {
        self.functionName       = @"houghToTextureKernel";
    }
    
    return self;
}

- (void)addHoughSpaceKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                                   inBuffer:(id <MTLBuffer>)houghSpaceBuffer
                              outputTexture:(id <MTLTexture>)houghSpaceTexture
{
//    _inHoughSpaceBuffer = houghSpaceBuffer;
    _outHoughSpaceTexture = houghSpaceTexture;
    [_outHoughSpaceTexture setLabel:@"HoughSpaceOutTexture"];
    [self addKernelToComputeEncoder:computeEncoder];
}

- (void)addKernelToComputeEncoder:(id<MTLComputeCommandEncoder>)computeEncoder
{
    [super addKernelToComputeEncoder:computeEncoder];
    
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:self.m_Kernel];
        [computeEncoder setTexture:self.outHoughSpaceTexture atIndex:0];
        [computeEncoder setBuffer:self.inHoughSpaceBuffer.houghBuffer offset:self.inHoughSpaceBuffer.offset atIndex:0]; //Input Buffer
        [computeEncoder setBuffer:self.parameterBuffer.buffer offset:self.parameterBuffer.offset atIndex:1];
        
        [computeEncoder dispatchThreadgroups:self.m_LocalCount
                       threadsPerThreadgroup:self.m_WorkgroupSize];
        
    }
}
@end
