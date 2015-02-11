//
//  GHTHoughSpaceFilter.m
//  GHTransform
//
//  Created by Per Schulte on 26.11.14.
//
//  Copyright (c) 2015 Per Schulte
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
