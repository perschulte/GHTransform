//
//  GHTFilter.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 24.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

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
