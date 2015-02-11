//
//  GHTFilter.h
//  GHTransform
//
//  Created by Per Schulte on 24.11.14.
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


#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "GHTInput.h"

@interface GHTFilter : NSObject

@property (nonatomic, weak) id <MTLLibrary> m_ShaderLibrary;
@property (nonatomic, weak) id <MTLDevice> m_Device;
@property (nonatomic, copy) NSString *functionName;

@property (nonatomic, weak) GHTInput *input;

@property (nonatomic, strong) id <MTLComputePipelineState>  m_Kernel;

// Compute sizes
@property (nonatomic, assign) MTLSize   m_WorkgroupSize;
@property (nonatomic, assign) MTLSize   m_LocalCount;


- (instancetype)initWithShaderLibrary:(id <MTLLibrary>)shaderLibrary device:(id <MTLDevice>)device;
- (id <MTLFunction>)function;
- (id <MTLComputePipelineState>)kernelWithError:(NSError **)error;
- (id <MTLTexture>)textureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor;
- (void)addKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder;
- (void)cleanUp;
@end
