//
//  GHTComputeBuilder.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

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
- (BOOL)finalize;
- (void)compute:(id <MTLCommandBuffer>)commandBuffer;

- (void)addDefaultFilters;
- (void)addGaussFilter;
- (void)addPhiFilter;
@end
