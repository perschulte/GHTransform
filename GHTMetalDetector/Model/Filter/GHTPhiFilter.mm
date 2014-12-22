//
//  GHTPhiFilter.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 10.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTPhiFilter.h"

@implementation GHTPhiFilter
- (instancetype)initWithShaderLibrary:(id<MTLLibrary>)shaderLibrary device:(id<MTLDevice>)device
{
    self = [super initWithShaderLibrary:shaderLibrary device:device];
    
    if (self)
    {
        self.functionName       = @"phiKernel";
    }
    
    return self;
}

- (void)addKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
{
    [super addKernelToComputeEncoder:computeEncoder];
    
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:self.m_Kernel];
        [computeEncoder setTexture:_inTexture atIndex:0];
        [computeEncoder setTexture:_outTexture atIndex:1];
        [computeEncoder dispatchThreadgroups:self.m_LocalCount
                       threadsPerThreadgroup:self.m_WorkgroupSize];
    }
}
@end
