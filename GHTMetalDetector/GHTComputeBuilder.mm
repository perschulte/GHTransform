//
//  GHTComputeBuilder.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTComputeBuilder.h"
//Buffer

#import "GHTSourceFilter.h"
#import "GHTGaussFilter.h"
#import "GHTPhiFilter.h"
#import "GHTHoughSpaceFilter.h"
#import "GHTHoughSpaceToTextureFilter.h"


static const uint32_t kSizeSIMDFloat4x4 = sizeof(simd::float4x4);

// Only allow 1 command buffers in flight at any given time so
// we don't overwrite the renderpass descriptor.
static const uint32_t kMaxBufferBytesPerFrame = kSizeSIMDFloat4x4;

@interface GHTComputeBuilder ()
@property (nonatomic, strong) GHTModel *modelBuffer;
@property (nonatomic, strong) GHTParameter *parameterBuffer;

// Compute sizes
@property (nonatomic, assign) MTLSize                       m_WorkgroupSize;
@property (nonatomic, assign) MTLSize                       m_LocalCount;

@end

@implementation GHTComputeBuilder

- (instancetype)initWithShaderLibrary:(id <MTLLibrary>)shaderLibrary device:(id <MTLDevice>)device quad:(GHTQuad *)quad
{
    self = [super init];
    if (self)
    {
        _m_ShaderLibrary = shaderLibrary;
        _m_Device = device;
        _quad = quad;
        _filters = [NSMutableArray new];
        
        //Temporary defaults
        [self defaultSetup];
    }
    
    return self;
}

- (void)defaultSetup
{
    _input = [GHTVideo new];
    ((GHTVideo *)_input).delegate = self;
    [((GHTVideo *)_input) finalize:_m_Device];
    //Model
    if (!_modelBuffer)
    {
        _modelBuffer = [[GHTModel alloc] initWithResourceName:@"circleModel" extension:@"gmf"];
        _modelBuffer.delegate = self;
    }
    
    //Parameter
    if (!self.parameterBuffer)
    {
        self.parameterBuffer = [[GHTParameter alloc] init];
    }
    
    _parameterBuffer.houghSpaceQuantization = (simd::uint2){15,15};
    
    //HoughSpace
    NSUInteger houghSpaceLength = ceilf(self.parameterBuffer.sourceSize[0] / self.parameterBuffer.houghSpaceQuantization[0] *
                                        self.parameterBuffer.sourceSize[1] / self.parameterBuffer.houghSpaceQuantization[1]);
    _houghSpaceBuffer = [[GHTHoughSpaceBuffer alloc] initWithLength:houghSpaceLength];
    
    //quad transform buffer
    if (![self _setupQuadTransformBuffer])
    {
        //quad transform buffer error handling
    }
    
    //depth stencil state
    if (![self _setupQuadSamplerAndDepthStencilState])
    {
        //depth stencil error handling
    }
    
    //pipeline state
    NSError *error = nil;
    if (![self _setupRenderKernelsAndPipelineStateWithError:&error])
    {
        //pipeline state error handling
    }

    _outTexture = [self textureWithTextureDescriptor:[self textureDesciptor]];
    [_outTexture setLabel:@"OutTexture"];
    
    if (!_outTexture)
    {
        NSLog(@"Error(%@): Failed creating an output texture", self.class);
    }
    
    if (_filters)
    {
        [self addDefaultFiltersNoGauss];
    }
}

- (BOOL)finalizeBuffer
{
    if (_m_Device)
    {
        
        if (![self.input finalize:_m_Device])
        {
            return NO;
        }
        
        if (![self.parameterBuffer finalize:_m_Device])
        {
            return NO;
        }
        
        BOOL isAcquired = [_houghSpaceBuffer finalize:_m_Device];
        
        if (!isAcquired)
        {
            NSLog(@"Error(%@): Failed creating a hough space buffer!", self.class);
        
            return NO;
        }

        isAcquired = [_modelBuffer finalize:_m_Device];
        
        if (!isAcquired)
        {
            NSLog(@"Error(%@): Failed creating a model buffer!", self.class);
            
            return NO;
        }
        
        return YES;
    } else
    {
        return NO;
    }
}

- (void)compute:(id<MTLCommandBuffer>)commandBuffer
{
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    for (GHTFilter *filter in _filters)
    {
        [filter addKernelToComputeEncoder:computeEncoder];
    }
    
    [computeEncoder endEncoding];
    
    computeEncoder = nil;
}

- (void)setInput:(GHTInput *)input
{
    _input = input;
    
    if ([input isKindOfClass:[GHTVideo class]])
    {
        if (!self.parameterBuffer)
        {
            self.parameterBuffer = [[GHTParameter alloc] init];
        }
    }
}

#pragma mark - Textures

- (id <MTLTexture>)textureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> texture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!texture)
        {
            NSLog(@"Error(%@): Failed creating a new texture!", self.class);
            
            return nil;
        }
        
        return texture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

- (MTLTextureDescriptor *)textureDesciptor
{
    if (_parameterBuffer.sourceSize[0] && _parameterBuffer.sourceSize[1])
    {
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                                     width:self.parameterBuffer.sourceSize[0]
                                                                                                    height:self.parameterBuffer.sourceSize[1]
                                                                                                 mipmapped:NO];
        
        if (!textureDescriptor)
        {
            NSLog(@"Error(%@): Failed creating a texture descriptor", self.class);
        }
        
        return textureDescriptor;
    }
    
    NSLog(@"Error(%@): Parameter not properly set", self.class);
    
    return nil;
}


#pragma mark - Setups

- (BOOL)_setupRenderKernelsAndPipelineStateWithError:(NSError **)error
{
    // load the fragment program into the library
    id <MTLFunction> fragment_program = [_m_ShaderLibrary newFunctionWithName:@"texturedQuadFragment"];
    
    if(!fragment_program)
    {
        NSLog(@"Error(%@): Failed creating a fragment shader!", self.class);
        
        return NO;
    }
    
    // load the vertex program into the library
    id <MTLFunction> vertex_program = [_m_ShaderLibrary newFunctionWithName:@"texturedQuadVertex"];
    
    if(!vertex_program)
    {
        NSLog(@"Error(%@): Failed creating a vertex shader!", self.class);
        
        return NO;
    }
    
    //  create a pipeline state for the quad
    MTLRenderPipelineDescriptor *quadPipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    
    if(!quadPipelineStateDescriptor)
    {
        NSLog(@"Error(%@): Failed creating a pipeline state descriptor!", self.class);
        
        return NO;
    } // if
    
    quadPipelineStateDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatInvalid;
    quadPipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    quadPipelineStateDescriptor.sampleCount      = 1;
    quadPipelineStateDescriptor.vertexFunction   = vertex_program;
    quadPipelineStateDescriptor.fragmentFunction = fragment_program;
    
    _pipelineState = [_m_Device newRenderPipelineStateWithDescriptor:quadPipelineStateDescriptor
                                                                 error:error];
    
    quadPipelineStateDescriptor = nil;
    
    vertex_program   = nil;
    fragment_program = nil;
    
    if(!_pipelineState)
    {
        NSLog(@"Error(%@): Failed acquiring pipeline state descriptor: %@", self.class, *error);
        
        return NO;
    }
    
    return YES;
}

- (BOOL)_setupQuadTransformBuffer
{
    // allocate regions of memory for the constant buffer
    _quadTransformBuffer = [_m_Device newBufferWithLength:kMaxBufferBytesPerFrame
                                                    options:0];
    [_quadTransformBuffer setLabel:@"QuadTransformBuffer"];
    if(!_quadTransformBuffer)
    {
        NSLog(@"Error(%@): Failed creating a transform buffer!", self.class);
        return NO;
    }
    
    _quadTransformBuffer.label = @"TransformBuffer";

    return YES;
}

- (BOOL)_setupQuadSamplerAndDepthStencilState
{
    // create a sampler for the quad
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    
    if(!samplerDescriptor)
    {
        NSLog(@"Error(%@): Failed creating a sampler descriptor!", self.class);
        
        return NO;
    }
    
    samplerDescriptor.minFilter             = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter             = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.mipFilter             = MTLSamplerMipFilterNotMipmapped;
    samplerDescriptor.maxAnisotropy         = 1.0f;
    samplerDescriptor.sAddressMode          = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode          = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.rAddressMode          = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.normalizedCoordinates = YES;
    samplerDescriptor.lodMinClamp           = 0;
    samplerDescriptor.lodMaxClamp           = FLT_MAX;
    
    _quadSampler = [_m_Device newSamplerStateWithDescriptor:samplerDescriptor];
    
    samplerDescriptor = nil;
    
    if (!_quadSampler)
    {
        NSLog(@"Error(%@): Failed creating a sampler state descriptor!", self.class);
        
        return NO;
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [MTLDepthStencilDescriptor new];
    
    if(!depthStateDesc)
    {
        NSLog(@"Error(%@): Failed creating a depth stencil descriptor!", self.class);
        
        return NO;
    }
    
    depthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    depthStateDesc.depthWriteEnabled    = YES;
    
    _depthState = [_m_Device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    depthStateDesc = nil;
    
    if(!_depthState)
    {
        NSLog(@"Error(%@): Failed creating a depth stencil state descriptor!", self.class);
        
        return NO;
    }
    
    return YES;
}


#pragma mark - Filter

- (void)updateWorkGroupSizeAndLocalCountForAllFilter
{
    for (GHTFilter *filter in _filters)
    {
        filter.m_WorkgroupSize = _m_WorkgroupSize;
        filter.m_LocalCount = _m_LocalCount;
    }
}

/**
 * Removes all previous filter and adds the default filter setup to the compute queue
 * That includes:
 * -> Gauss
 * -> Phi
 * -> HoughToBuffer
 * -> HoughBufferToTexture
 * 
 * in that order.
 */
- (void)addDefaultFilters
{
    [_filters removeAllObjects];
    //Source
    GHTSourceFilter *source = [[GHTSourceFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    source.outTexture = _outTexture;
    source.input = _input;
    [_filters addObject:source];
    
    id <MTLTexture> gaussOutTexture = [self textureWithTextureDescriptor:[self textureDesciptor]];
    [gaussOutTexture setLabel:@"GaussTexture"];
    id <MTLTexture> phiOutTexture = [self textureWithTextureDescriptor:[self textureDesciptor]];
    [phiOutTexture setLabel:@"phiTexture"];
    
    //Gauss
    GHTGaussFilter *gauss = [[GHTGaussFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    gauss.outTexture = gaussOutTexture;
    gauss.input = _input;
    
    //Phi
    GHTPhiFilter *phi = [[GHTPhiFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    phi.inTexture = gaussOutTexture;
    phi.outTexture = phiOutTexture;
    
    //HoughToBuffer
    GHTHoughSpaceFilter *houghToBuffer = [[GHTHoughSpaceFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    houghToBuffer.inTexture = phiOutTexture;
    houghToBuffer.outHoughSpaceBuffer = _houghSpaceBuffer;
    houghToBuffer.modelBuffer = _modelBuffer;
    houghToBuffer.parameterBuffer = _parameterBuffer;
    
    //HoughBufferToTexture
    GHTHoughSpaceToTextureFilter *houghBufferToTexture =[[GHTHoughSpaceToTextureFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    houghBufferToTexture.inHoughSpaceBuffer = _houghSpaceBuffer;
    houghBufferToTexture.parameterBuffer = _parameterBuffer;
    houghBufferToTexture.outHoughSpaceTexture = _outTexture;
    
    [_filters addObject:gauss];
    [_filters addObject:phi];
    [_filters addObject:houghToBuffer];
    [_filters addObject:houghBufferToTexture];
    
    [self updateWorkGroupSizeAndLocalCountForAllFilter];
}

/**
 * Removes all previous filter and adds the default filter setup not including the gauss filter to the compute queue
 * That includes:
 * -> Phi
 * -> HoughToBuffer
 * -> HoughBufferToTexture
 *
 * in that order.
 */
- (void)addDefaultFiltersNoGauss
{
    [_filters removeAllObjects];
    //Source
    GHTSourceFilter *source = [[GHTSourceFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    source.outTexture = _outTexture;
    source.input = _input;
    [_filters addObject:source];
    
    id <MTLTexture> phiOutTexture = [self textureWithTextureDescriptor:[self textureDesciptor]];
    [phiOutTexture setLabel:@"phiTexture"];
    
    //Phi
    GHTPhiFilter *phi = [[GHTPhiFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    phi.input = _input;
    phi.outTexture = phiOutTexture;
    
    //HoughToBuffer
    GHTHoughSpaceFilter *houghToBuffer = [[GHTHoughSpaceFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    houghToBuffer.inTexture = phiOutTexture;
    houghToBuffer.outHoughSpaceBuffer = _houghSpaceBuffer;
    houghToBuffer.modelBuffer = _modelBuffer;
    houghToBuffer.parameterBuffer = _parameterBuffer;
    
    //HoughBufferToTexture
    GHTHoughSpaceToTextureFilter *houghBufferToTexture =[[GHTHoughSpaceToTextureFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    houghBufferToTexture.inHoughSpaceBuffer = _houghSpaceBuffer;
    houghBufferToTexture.parameterBuffer = _parameterBuffer;
    houghBufferToTexture.outHoughSpaceTexture = _outTexture;
    
    [_filters addObject:phi];
    [_filters addObject:houghToBuffer];
    [_filters addObject:houghBufferToTexture];
    
    [self updateWorkGroupSizeAndLocalCountForAllFilter];
}


- (void)addGaussFilter
{
    [self.filters removeAllObjects];
    
    //Gauss
    GHTGaussFilter *gauss = [[GHTGaussFilter alloc] initWithShaderLibrary:self.m_ShaderLibrary device:self.m_Device];
    gauss.outTexture = self.outTexture;
    gauss.input = self.input;
    gauss.m_WorkgroupSize = self.m_WorkgroupSize;
    gauss.m_LocalCount = self.m_LocalCount;
    
    [self.filters addObject:gauss];
}

- (void)addPhiFilter
{
    [self.filters removeAllObjects];
    
    id <MTLTexture> gaussOutTexture = [self textureWithTextureDescriptor:[self textureDesciptor]];
    [gaussOutTexture setLabel:@"GaussTexture"];
    
    //Gauss
    GHTGaussFilter *gauss = [[GHTGaussFilter alloc] initWithShaderLibrary:self.m_ShaderLibrary device:self.m_Device];
    gauss.outTexture = gaussOutTexture;
    gauss.input = self.input;
    gauss.m_WorkgroupSize = self.m_WorkgroupSize;
    gauss.m_LocalCount = self.m_LocalCount;
    
    //Phi
    GHTPhiFilter *phi = [[GHTPhiFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    phi.inTexture = gaussOutTexture;
    phi.outTexture = self.outTexture;
    phi.m_WorkgroupSize = self.m_WorkgroupSize;
    phi.m_LocalCount = self.m_LocalCount;
    
    //HoughToBuffer
    GHTHoughSpaceFilter *houghToBuffer = [[GHTHoughSpaceFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    houghToBuffer.inTexture = phi.outTexture;
    houghToBuffer.outHoughSpaceBuffer = _houghSpaceBuffer;
    houghToBuffer.modelBuffer = _modelBuffer;
    houghToBuffer.parameterBuffer = _parameterBuffer;
    
    //HoughBufferToTexture
    GHTHoughSpaceToTextureFilter *houghBufferToTexture =[[GHTHoughSpaceToTextureFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    houghBufferToTexture.inHoughSpaceBuffer = _houghSpaceBuffer;
    houghBufferToTexture.parameterBuffer = _parameterBuffer;
    houghBufferToTexture.outHoughSpaceTexture = _outTexture;
    
    [self.filters addObject:gauss];
    [self.filters addObject:phi];
    [self.filters addObject:houghToBuffer];
    [self.filters addObject:houghBufferToTexture];
    [self updateWorkGroupSizeAndLocalCountForAllFilter];
}

#pragma mark - GHTInputDelegate

- (void)didChangeResolutionTo:(simd::uint2)size
{
    if (!self.parameterBuffer)
    {
        self.parameterBuffer = [[GHTParameter alloc] init];
    }
    
    //The quad size should be the same as the input size for now
    self.quad.size = CGSizeMake(size[0], size[1]);
    
    self.parameterBuffer.sourceSize = size;
    self.outTexture = [self textureWithTextureDescriptor:[self textureDesciptor]];

    // Set the compute kernel's workgroup size and count
    _m_WorkgroupSize    = MTLSizeMake(1, 1, 1);
    _m_LocalCount       = MTLSizeMake(self.parameterBuffer.sourceSize[0], self.parameterBuffer.sourceSize[1], 1);
    [self updateWorkGroupSizeAndLocalCountForAllFilter];
    
}

#pragma mark - GHTModelBufferDelegate

- (void)didChangeDataWithLength:(unsigned int)length;
{
    if (!self.parameterBuffer)
    {
        self.parameterBuffer = [[GHTParameter alloc] init];
    }
    
    self.parameterBuffer.modelLength = length;
}

#pragma mark - Buffers


@end
