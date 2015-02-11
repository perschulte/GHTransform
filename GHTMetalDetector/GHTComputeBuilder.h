//
//  GHTComputeBuilder.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
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
#import "GHTVideo.h"
#import "GHTModel.h"
#import "GHTConstants.h"
#import "GHTQuad.h"
#import <Metal/Metal.h>
#import "GHTHoughSpaceBuffer.h"

@protocol GHTComputeBuilderDelegate <NSObject>

- (void)setQuadTransform:(simd::float4x4)quadTransform;

@end

@interface GHTComputeBuilder : NSObject <GHTInputDelegate, GHTModelBufferDelegate>

@property (nonatomic, strong) GHTInput *input;
@property (nonatomic, weak)   GHTQuad *quad;

@property (nonatomic, strong) id <MTLTexture> outTexture;
@property (nonatomic, strong) id <MTLBuffer> quadTransformBuffer;
@property (nonatomic, strong) id <MTLSamplerState> quadSampler;
@property (nonatomic, strong) id <MTLDepthStencilState> depthState;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) GHTHoughSpaceBuffer *houghSpaceBuffer;

@property (nonatomic, strong) NSMutableArray *filters;

@property (nonatomic, weak) id <MTLDevice> m_Device;
@property (nonatomic, weak) id <MTLLibrary> m_ShaderLibrary;

- (instancetype)initWithShaderLibrary:(id <MTLLibrary>)shaderLibrary device:(id <MTLDevice>)device quad:(GHTQuad *)quad;
- (BOOL)finalizeBuffer;
- (void)compute:(id <MTLCommandBuffer>)commandBuffer;

- (void)addDefaultFilters;
- (void)addGaussFilter;
- (void)addPhiFilter;
@end
