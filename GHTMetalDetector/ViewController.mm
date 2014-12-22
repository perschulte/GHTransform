//
//  ViewController.mm
//  GHTMetalDetector
//
//  Created by Per Schulte on 28.07.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "ViewController.h"

#import <string.h>

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "AAPLTransforms.h"
#import "GHTQuad.h"
#import "GHTTexture.h"
#import "GHTView.h"
#import "GHTModel.h"
#import "GHTHoughSpace.h"
#import "GHTVideo.h"
#import "GHTParameter.h"



#import "GHTModelFilter.h"
#import "GHTHoughSpaceFilter.h"
#import "GHTHoughSpaceToTextureFilter.h"

#import "GHTImageInput.h"
#import "GHTFilterSettingsViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import "GHTInputImageCollectionViewCell.h"

static const float kUIInterfaceOrientationLandscapeAngle = 35.0f;
static const float kUIInterfaceOrientationPortraitAngle  = 35.0f;

static const int kQx  = 1;
static const int kQy  = 1;

static const float kPrespectiveNear = 0.1f;
static const float kPrespectiveFar  = 100.0f;

static const uint32_t kSizeSIMDFloat4x4 = sizeof(simd::float4x4);

// Only allow 1 command buffers in flight at any given time so
// we don't overwrite the renderpass descriptor.
static const uint32_t kInFlightCommandBuffers = 1;
static const uint32_t kMaxBufferBytesPerFrame = kSizeSIMDFloat4x4;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIButton *inputButton;
@property (weak, nonatomic) IBOutlet UIButton *filterSettingsButton;
@property (weak, nonatomic) IBOutlet UIView *filterSettingsContainer;

//Input
@property (weak, nonatomic) IBOutlet UICollectionView *inputCollectionView;
@property (nonatomic, strong) NSArray *assets;

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, assign) uint state;
@property (nonatomic, assign) float zoomScale;


//Compute Builder
@property (nonatomic, strong) GHTComputeBuilder *computeBuilder;

//Render globals
@property (nonatomic, strong) id <MTLDevice>                m_Device;
@property (nonatomic, strong) id <MTLCommandQueue>          m_CommandQueue;
@property (nonatomic, strong) id <MTLLibrary>               m_ShaderLibrary;
@property (nonatomic, strong) id <MTLDepthStencilState>     m_DepthState;
@property (nonatomic, strong) MTLRenderPassDescriptor      *m_RenderPassDescriptor;

//App control
@property (nonatomic, strong) CADisplayLink                *m_Timer;
@property (nonatomic, strong) dispatch_semaphore_t          m_InflightSemaphore;

//Quad setup
@property (nonatomic, strong) id <MTLRenderPipelineState>   m_PipelineState;
@property (nonatomic, strong) id <MTLSamplerState>          m_QuadSampler;
@property (nonatomic, strong) GHTQuad                      *m_Quad;             //Quad representation
@property (nonatomic, assign) CGSize                        m_QuadTextureSize;  //Dimensions
@property (nonatomic, assign) simd::float4x4                m_QuadTransform;
@property (nonatomic, strong) id <MTLBuffer>                m_QuadTransformBuffer;

//Textures
@property (nonatomic, strong) GHTInput                     *m_InTexture;
@property (nonatomic, strong) GHTVideo                     *m_VideoTexture;
@property (nonatomic, strong) id <MTLTexture>               m_OutTexture;

//Filter textures
@property (nonatomic, strong) id <MTLTexture>               m_SourceTexture;
@property (nonatomic, strong) id <MTLTexture>               m_GaussianTexture;
@property (nonatomic, strong) id <MTLTexture>               m_VotingTexture;
@property (nonatomic, strong) id <MTLTexture>               m_HoughSpaceTexture;
@property (nonatomic, strong) id <MTLTexture>               m_PhiTexture;
@property (nonatomic, strong) id <MTLTexture>           	m_CannyTexture;
@property (nonatomic, strong) id <MTLTexture>           	m_ModelTexture;

//Filter kernels
@property (nonatomic, strong) id <MTLComputePipelineState>  m_SourceKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_GaussKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_VotingKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_HoughSpaceKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_PhiKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_CannyKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_ModelKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_NormalizeKernel;


//Filter
@property (nonatomic, strong) GHTModelFilter               *modelFilter;
@property (nonatomic, strong) GHTHoughSpaceFilter          *houghSpaceFilter;
@property (nonatomic, strong) GHTHoughSpaceToTextureFilter *houghSpaceToTextureFilter;

//Model Buffer A
@property (nonatomic, strong) GHTModel                     *m_Model;
//Model Buffer B
@property (nonatomic, strong) GHTModel                     *m_ModelB;

//HoughSpace Buffer
@property (nonatomic, strong) GHTHoughSpace                *m_HoughSpace;
@property (nonatomic, strong) GHTHoughSpaceBuffer          *m_HoughSpaceBuffer;

//Parameter Buffer
@property (nonatomic, strong) GHTParameter                 *m_Parameter;

// Viewing matrix is derived from an eye point, a reference point
// indicating the center of the scene, and an up vector.
@property (nonatomic, assign) simd::float4x4                m_LookAt;

// Translate the object in (x,y,z) space.
@property (nonatomic, assign) simd::float4x4                m_Translate;

// Framebuffer/drawable
@property (nonatomic, assign) MTLViewport                   m_Viewport;
@property (nonatomic, strong) CAMetalLayer                 *m_RenderingLayer;

// Compute sizes
@property (nonatomic, assign) MTLSize                       m_WorkgroupSize;
@property (nonatomic, assign) MTLSize                       m_LocalCount;

// Clear color
@property (nonatomic, assign) MTLClearColor                 m_ClearColor;

@end

@implementation ViewController

#pragma mark - Clean-up
- (void)_cleanUp
{
    //Render globals
    _m_Device               = nil;
    _m_CommandQueue         = nil;
    _m_ShaderLibrary        = nil;
    _m_DepthState           = nil;
    
    //Quad setup
    _m_Quad                 = nil;
    _m_PipelineState        = nil;
    _m_QuadSampler          = nil;
    _m_QuadTransformBuffer  = nil;
    
    //Textures
    _m_InTexture            = nil;
    _m_OutTexture           = nil;
    
    //Filter textures
    _m_SourceTexture        = nil;
    _m_GaussianTexture      = nil;
    _m_VotingTexture        = nil;
    _m_HoughSpaceTexture    = nil;
    _m_PhiTexture           = nil;
    _m_CannyTexture         = nil;
    _m_ModelTexture         = nil;
    
    //Filter kernels
    _m_SourceKernel         = nil;
    _m_GaussKernel          = nil;
    _m_VotingKernel         = nil;
    _m_HoughSpaceKernel     = nil;
    _m_PhiKernel            = nil;
    _m_CannyKernel          = nil;
    _m_ModelKernel          = nil;
    _m_NormalizeKernel      = nil;

    //Model Buffer
    _m_Model                = nil;
    
    //HoughSpace Buffer
    _m_HoughSpace           = nil;
    _m_HoughSpaceBuffer     = nil;
    
    //Parameter Buffer
    _m_Parameter            = nil;
    
    // Framebuffer/drawable
    _m_RenderingLayer       = nil;
    
    if(_m_Timer)
    {
        [_m_Timer invalidate];
    }
    
    _m_Timer = nil;
}

- (void)dealloc
{
    [self _cleanUp];
}

#pragma mark - ComputeBuilder

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
    
    _m_PipelineState = [_m_Device newRenderPipelineStateWithDescriptor:quadPipelineStateDescriptor
                                                                 error:error];
    
    quadPipelineStateDescriptor = nil;
    
    vertex_program   = nil;
    fragment_program = nil;
    
    if(!_m_PipelineState)
    {
        NSLog(@"Error(%@): Failed acquiring pipeline state descriptor: %@", self.class, *error);
        
        return NO;
    }
    
    return YES;
}

- (BOOL)_setupComputeBuilder
{
    NSError *error = nil;
    if (![self _setupRenderKernelsAndPipelineStateWithError:&error])
    {
        NSLog(@"Error(%@): Failed setting up kernels and pipeline descriptor!", self.class);
        
        return NO;
    }
    
    _m_QuadTextureSize.width  = _computeBuilder.input.width;
    _m_QuadTextureSize.height = _computeBuilder.input.height;
    
    return YES;
}

#pragma mark - Setup
- (BOOL)_setupWithTextureName:(NSString *)textureNameString
                    extension:(NSString *)extensionString
{
    NSError *error = nil;
    return YES;
    if (![self _setupKernelsAndPipeLineStateWithError:&error])
    {
        NSLog(@"Error(%@): Failed setting up kernels and pipeline descriptor!", self.class);
        
        return NO;
    }
    
    _m_InTexture = [[GHTTexture alloc] initWithResourceName:textureNameString extension:extensionString];

    BOOL isAcquired = [_m_InTexture finalize:_m_Device];
    
    if (!isAcquired)
    {
        NSLog(@"Error(%@): Failed creating an input 2d Texture!", self.class);
        
        return NO;
    }

    _m_VideoTexture = [[GHTVideo alloc] initWithSourceSize:CGSizeMake(352, 288)];
    isAcquired = [_m_VideoTexture finalize:_m_Device];
    
    if (!isAcquired)
    {
        NSLog(@"Error(%@): Failed creating an video 2d Texture!", self.class);
        
        return NO;
    }
    
    if (![self _setupModelBufferWithResourceName:@"circleModel" extension:@"gmf"])
    {
        NSLog(@"Error(%@): Failed setting up a model A buffer", self.class);
        
        return NO;
    }
    
    if (![self _setupHoughSpaceBufferWithResourceSize:{_m_InTexture.width, _m_InTexture.height}])
    {
        NSLog(@"Error(%@): Failed setting up a hough space buffer", self.class);
        
        return NO;
    }
    
    if (![self _setupParameterBufferWithImageSize:{_m_InTexture.width, _m_InTexture.height} quantization:{kQx,kQy} modelSize:{0,0} numberOfModelPoints:_m_Model.length])
    {
        NSLog(@"Error(%@): Failed setting up a hough space buffer", self.class);
        
        return NO;
    }
    
    _m_QuadTextureSize.width  = 352;//_m_InTexture.width;
    _m_QuadTextureSize.height = 288;//_m_InTexture.height;
    
//    //_m_Quad = [[GHTQuad alloc] initWithDevice:_m_Device];
//    
//    if (!_m_Quad)
//    {
//        NSLog(@"Error(%@): Failed creating a quad object!", self.class);
//        
//        return NO;
//    }
    
    _m_Quad.size = _m_QuadTextureSize;
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                                 width:_m_QuadTextureSize.width
                                                                                                height:_m_QuadTextureSize.height
                                                                                             mipmapped:NO];
    if (!textureDescriptor)
    {
        NSLog(@"Error(%@): Failed creating a texture descriptor", self.class);
        
        return NO;
    }
    
    if (![self _setupOutputTexturesWithTextureDescriptor:textureDescriptor])
    {
        NSLog(@"Error(%@): Failed creating textures", self.class);
        
        return NO;
    }

    if (![self _setupQuadSamplerAndDepthStencilState])
    {
        NSLog(@"Error(%@): Failed creating quad sampler and depth stencil state", self.class);
        
        return NO;
    }
    
    // allocate regions of memory for the constant buffer
    _m_QuadTransformBuffer = [_m_Device newBufferWithLength:kMaxBufferBytesPerFrame
                                              options:0];
    
    if(!_m_QuadTransformBuffer)
    {
        NSLog(@"Error(%@): Failed creating a transform buffer!", self.class);
        
        return NO;
    }
    
    _m_QuadTransformBuffer.label = @"TransformBuffer";
    
    // Set the compute kernel's workgroup size and count
    _m_WorkgroupSize    = MTLSizeMake(1, 1, 1);
    _m_LocalCount       = MTLSizeMake(_m_QuadTextureSize.width, _m_QuadTextureSize.height, 1);
    
    //***//
    _modelFilter.m_WorkgroupSize = _m_WorkgroupSize;
    _modelFilter.m_LocalCount = _m_LocalCount;
    _houghSpaceFilter.m_WorkgroupSize = _m_WorkgroupSize;
    _houghSpaceFilter.m_LocalCount = _m_LocalCount;
    _houghSpaceToTextureFilter.m_WorkgroupSize = _m_WorkgroupSize;
    _houghSpaceToTextureFilter.m_LocalCount = _m_LocalCount;
    //***//
    
    return YES;
}

- (BOOL)_setupWithImage:(UIImage *)image
{
    NSError *error = nil;
    
    if (![self _setupKernelsAndPipeLineStateWithError:&error])
    {
        NSLog(@"Error(%@): Failed setting up kernels and pipeline descriptor!", self.class);
        
        return NO;
    }
    
    _m_InTexture = [[GHTImageInput alloc] initWithImage:image];
    
    BOOL isAcquired = [_m_InTexture finalize:_m_Device];
    
    if (!isAcquired)
    {
        NSLog(@"Error(%@): Failed creating an input 2d Texture!", self.class);
        
        return NO;
    }
    
    _m_VideoTexture = [[GHTVideo alloc] initWithSourceSize:CGSizeMake(180, 179)];
    isAcquired = [_m_VideoTexture finalize:_m_Device];
    
    if (!isAcquired)
    {
        NSLog(@"Error(%@): Failed creating an video 2d Texture!", self.class);
        
        return NO;
    }
    
    if (![self _setupModelBufferWithResourceName:@"circleModel" extension:@"gmf"])
    {
        NSLog(@"Error(%@): Failed setting up a model A buffer", self.class);
        
        return NO;
    }
    
    if (![self _setupHoughSpaceBufferWithResourceSize:{_m_InTexture.width, _m_InTexture.height}])
    {
        NSLog(@"Error(%@): Failed setting up a hough space buffer", self.class);
        
        return NO;
    }
    
    if (![self _setupParameterBufferWithImageSize:{_m_InTexture.width, _m_InTexture.height} quantization:{kQx,kQy} modelSize:{0,0} numberOfModelPoints:_m_Model.length])
    {
        NSLog(@"Error(%@): Failed setting up a hough space buffer", self.class);
        
        return NO;
    }
    
    _m_QuadTextureSize.width  = _m_InTexture.width;
    _m_QuadTextureSize.height = _m_InTexture.height;
    
    
    _m_Quad.size = _m_QuadTextureSize;
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                                 width:_m_QuadTextureSize.width
                                                                                                height:_m_QuadTextureSize.height
                                                                                             mipmapped:NO];
    if (!textureDescriptor)
    {
        NSLog(@"Error(%@): Failed creating a texture descriptor", self.class);
        
        return NO;
    }
    
    if (![self _setupOutputTexturesWithTextureDescriptor:textureDescriptor])
    {
        NSLog(@"Error(%@): Failed creating textures", self.class);
        
        return NO;
    }
    
    if (![self _setupQuadSamplerAndDepthStencilState])
    {
        NSLog(@"Error(%@): Failed creating quad sampler and depth stencil state", self.class);
        
        return NO;
    }
    
    // allocate regions of memory for the constant buffer
    _m_QuadTransformBuffer = [_m_Device newBufferWithLength:kMaxBufferBytesPerFrame
                                                    options:0];
    
    if(!_m_QuadTransformBuffer)
    {
        NSLog(@"Error(%@): Failed creating a transform buffer!", self.class);
        
        return NO;
    }
    
    _m_QuadTransformBuffer.label = @"TransformBuffer";
    
    // Set the compute kernel's workgroup size and count
    _m_WorkgroupSize    = MTLSizeMake(1, 1, 1);
    _m_LocalCount       = MTLSizeMake(_m_QuadTextureSize.width, _m_QuadTextureSize.height, 1);
    
    //***//
    _modelFilter.m_WorkgroupSize = _m_WorkgroupSize;
    _modelFilter.m_LocalCount = _m_LocalCount;
    _houghSpaceFilter.m_WorkgroupSize = _m_WorkgroupSize;
    _houghSpaceFilter.m_LocalCount = _m_LocalCount;
    _houghSpaceToTextureFilter.m_WorkgroupSize = _m_WorkgroupSize;
    _houghSpaceToTextureFilter.m_LocalCount = _m_LocalCount;
    //***//
    
    return YES;
}


- (BOOL)_setupOutputTexturesWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        _m_OutTexture           = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if (!_m_OutTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d texture", self.class);
            
            return NO;
        }
        
        _m_SourceTexture        = [self _gaussTextureWithTextureDescriptor:textureDescriptor];
        
        if (!_m_SourceTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d source texture", self.class);
            
            return NO;
        }
        
        _m_GaussianTexture      = [self _gaussTextureWithTextureDescriptor:textureDescriptor];
        
        if (!_m_GaussianTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d gauss texture", self.class);
            
            return NO;
        }
        
        _m_VotingTexture        = [self _votingTextureWithTextureDescriptor:textureDescriptor];
        
        if (!_m_VotingTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d voting texture", self.class);
            
            return NO;
        }
        
        _m_HoughSpaceTexture    = [self _houghSpaceTextureWithTextureDescriptor:textureDescriptor];
        
        if (!_m_HoughSpaceTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d hough space texture", self.class);
            
            return NO;
        }
        
        _m_PhiTexture           = [self _phiTextureWithTextureDescriptor:textureDescriptor];
        
        if (!_m_PhiTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d phi texture", self.class);
            
            return NO;
        }
        
        _m_CannyTexture         = [self _cannyTextureWithTextureDescriptor:textureDescriptor];
        
        if (!_m_CannyTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d canny texture", self.class);
            
            return NO;
        }
        
        _m_ModelTexture         = [self _modelTextureWithTextureDescriptor:textureDescriptor];
        
        if (!_m_ModelTexture)
        {
            NSLog(@"Error(%@): Failed creating an output 2d model texture", self.class);
            
            return NO;
        }
        
    } else
    {
        NSLog(@"Error(%@): No texture descriptor", self.class);
        
        return NO;
    }
    
    return YES;
}

- (BOOL)_setupKernelsAndPipeLineStateWithError:(NSError **)error
{
    
    _m_ShaderLibrary = [_m_Device newDefaultLibrary];
    
    if (!_m_ShaderLibrary)
    {
        NSLog(@"Error(%@): Failed to create a shared library!", self.class);
        
        return NO;
    }
    
    //Source kernel
    _m_SourceKernel         = [self _sourceKernelWithError:error];
    
    //Gauss kernel
    _m_GaussKernel          = [self _gaussKernelWithError:error];
    
    //Voting kernel
    _m_VotingKernel         = [self _votingKernelWithError:error];
    
    //Hough space kernel
    _m_HoughSpaceKernel     = [self _houghSpaceKernelWithError:error];
    
    //Phi kernel
    _m_PhiKernel            = [self _phiKernelWithError:error];
    //
    //    //Canny kernel
    //    _m_CannyKernel          = [self _cannyKernelWithError:error];
    //
    //    //Model kernel
    //    _m_ModelKernel          = [self _modelKernelWithError:error];
    
    //Normalize Kernel
    _m_NormalizeKernel      = [self _normalizeKernelWithError:error];
    
    
    //***//
    _modelFilter                = [[GHTModelFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    _houghSpaceFilter           = [[GHTHoughSpaceFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    _houghSpaceToTextureFilter  = [[GHTHoughSpaceToTextureFilter alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device];
    //***//
    
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
    
    _m_PipelineState = [_m_Device newRenderPipelineStateWithDescriptor:quadPipelineStateDescriptor
                                                                 error:error];
    
    quadPipelineStateDescriptor = nil;
    
    vertex_program   = nil;
    fragment_program = nil;
    
    if(!_m_PipelineState)
    {
        NSLog(@"Error(%@): Failed acquiring pipeline state descriptor: %@", self.class, *error);
        
        return NO;
    }
    
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
    
    _m_QuadSampler = [_m_Device newSamplerStateWithDescriptor:samplerDescriptor];
    
    samplerDescriptor = nil;
    
    if (!_m_QuadSampler)
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
    
    _m_DepthState = [_m_Device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    depthStateDesc = nil;
    
    if(!_m_DepthState)
    {
        NSLog(@"Error(%@): Failed creating a depth stencil state descriptor!", self.class);
        
        return NO;
    }
    
    return YES;
}

- (BOOL)_setupParameterBufferWithImageSize:(simd::uint2)imageSize quantization:(simd::uint2)quantization modelSize:(simd::uint2)modelSize numberOfModelPoints:(unsigned int)modelLength
{
    _m_Parameter = [[GHTParameter alloc] initWithImageSize:(simd::uint2){352,288} quantization:quantization modelSize:modelSize numberOfModelPoints:modelLength];
    
    //***//
    _modelFilter.parameter = _m_Parameter;
    _houghSpaceFilter.parameterBuffer = _m_Parameter;
    _houghSpaceToTextureFilter.parameterBuffer = _m_Parameter;
    //***//
    
    BOOL isAcquired = [_m_Parameter finalize:_m_Device];
    
    if (!isAcquired)
    {
        NSLog(@"Error(%@): Failed creating a parameter buffer!", self.class);
        
        return NO;
    }
    
    return YES;
}

#pragma mark - source setup
- (id <MTLFunction>)_sourceFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> sourceFunction = [_m_ShaderLibrary newFunctionWithName:@"sourceKernel"];
        
        if(!sourceFunction)
        {
            NSLog(@"Error(%@): Failed creating a new source function!", self.class);
            
            return nil;
        }
        
        return sourceFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)_sourceKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> sourceKernel = [_m_Device newComputePipelineStateWithFunction:[self _sourceFunction]
                                                                                             error:error];
        
        if(!sourceKernel)
        {
            NSLog(@"Error(%@): Failed creating a new source kernel!", self.class);
            
            return nil;
        }
        
        return sourceKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)_sourceTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> sourceTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!sourceTexture)
        {
            NSLog(@"Error(%@): Failed creating a new source texture!", self.class);
            
            return nil;
        }
        
        return sourceTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

- (void)_addSourceKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                            inputTexture:(id <MTLTexture>)inTexture
                           outputTexture:(id <MTLTexture>)outTexture
{
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:_m_SourceKernel];
        [computeEncoder setTexture:inTexture atIndex:0];
        [computeEncoder setTexture:outTexture atIndex:1];
        [computeEncoder dispatchThreadgroups:_m_LocalCount
                       threadsPerThreadgroup:_m_WorkgroupSize];
        //[computeEncoder ];
    }
}

#pragma mark - Gauss setup
//  Gaussian blur
- (id <MTLFunction>)_gaussFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> gaussFunction = [_m_ShaderLibrary newFunctionWithName:@"gaussianBlurKernel"];
        
        if(!gaussFunction)
        {
            NSLog(@"Error(%@): Failed creating a new gauss function!", self.class);
            
            return nil;
        }
        
        return gaussFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)_gaussKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> gaussKernel = [_m_Device newComputePipelineStateWithFunction:[self _gaussFunction]
                                                                                            error:error];
        
        if(!gaussKernel)
        {
            NSLog(@"Error(%@): Failed creating a new gauss kernel!", self.class);
            
            return nil;
        }
        
        return gaussKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);

        return nil;
    }
}

- (id <MTLTexture>)_gaussTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> gaussTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!gaussTexture)
        {
            NSLog(@"Error(%@): Failed creating a new gauss texture!", self.class);
            
            return nil;
        }
        
        return gaussTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

- (void)_addGaussKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                           inputTexture:(id <MTLTexture>)inTexture
                          outputTexture:(id <MTLTexture>)outTexture
{
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:_m_GaussKernel];
        [computeEncoder setTexture:inTexture atIndex:0];
        [computeEncoder setTexture:outTexture atIndex:1];
        [computeEncoder dispatchThreadgroups:_m_LocalCount
                       threadsPerThreadgroup:_m_WorkgroupSize];
        //[computeEncoder executeBarrier];
    }
}

#pragma mark - Voting setup
//  The voting kernel visualizes the actual voting process.
//  It draws lines from the edge point to a possible center point.
- (id <MTLFunction>)_votingFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> votingFunction = [_m_ShaderLibrary newFunctionWithName:@"votingKernel"];
        
        if(!votingFunction)
        {
            NSLog(@"Error(%@): Failed creating a new voting function!", self.class);
            
            return nil;
        }
        
        return votingFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)_votingKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> votingKernel = [_m_Device newComputePipelineStateWithFunction:[self _votingFunction]
                                                                                            error:error];
        
        if(!votingKernel)
        {
            NSLog(@"Error(%@): Failed creating a new voting kernel!", self.class);
            
            return nil;
        }
        
        return votingKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)_votingTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> votingTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!votingTexture)
        {
            NSLog(@"Error(%@): Failed creating a new voting texture!", self.class);
            
            return nil;
        }
        
        return votingTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

- (void)_addVotingKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                            inputTexture:(id <MTLTexture>)inTexture
                           outputTexture:(id <MTLTexture>)outTexture
                             modelBuffer:(GHTModel *)modelBuffer
{
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:_m_VotingKernel];
        [computeEncoder setTexture:inTexture atIndex:0];
        [computeEncoder setTexture:outTexture atIndex:1];
        [computeEncoder setBuffer:modelBuffer.buffer offset:modelBuffer.offset atIndex:0];
        [computeEncoder setBuffer:_m_Parameter.buffer offset:_m_Parameter.offset atIndex:1];
        
        [computeEncoder dispatchThreadgroups:_m_LocalCount
                       threadsPerThreadgroup:_m_WorkgroupSize];
        //[computeEncoder executeBarrier];
    }
}

#pragma mark - Hough space setup
- (id <MTLFunction>)_houghSpaceFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> houghSpaceFunction = [_m_ShaderLibrary newFunctionWithName:@"houghSpaceKernel"];

        if(!houghSpaceFunction)
        {
            NSLog(@"Error(%@): Failed creating a new hough space function!", self.class);
            
            return nil;
        }
        
        return houghSpaceFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)_houghSpaceKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> houghSpaceKernel = [_m_Device newComputePipelineStateWithFunction:[self _houghSpaceFunction]
                                                                                             error:error];
        
        if(!houghSpaceKernel)
        {
            NSLog(@"Error(%@): Failed creating a new houghSpace kernel!", self.class);
            
            return nil;
        }
        
        return houghSpaceKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)_houghSpaceTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> houghSpaceTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!houghSpaceTexture)
        {
            NSLog(@"Error(%@): Failed creating a new hough space texture!", self.class);
            
            return nil;
        }
        
        return houghSpaceTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

- (void)_addHoughSpaceKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                                inputTexture:(id <MTLTexture>)inTexture
                            houghSpaceBuffer:(GHTHoughSpace *)houghSpaceBuffer
                                 modelBuffer:(GHTModel *)modelBuffer
{
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:_m_HoughSpaceKernel];
        [computeEncoder setTexture:inTexture atIndex:0];
        [computeEncoder setBuffer:_m_Parameter.buffer offset:_m_Parameter.offset atIndex:0];
        [computeEncoder setBuffer:houghSpaceBuffer.buffer offset:houghSpaceBuffer.offset atIndex:1];
        [computeEncoder setBuffer:modelBuffer.buffer offset:modelBuffer.offset atIndex:2];
        [computeEncoder dispatchThreadgroups:_m_LocalCount
                       threadsPerThreadgroup:_m_WorkgroupSize];
        //[computeEncoder executeBarrier];
    }
}

- (BOOL)_setupHoughSpaceBufferWithResourceSize:(simd::uint2)size
{
    _m_HoughSpace = [[GHTHoughSpace alloc] initWithImageSize:size quantization:{1,1}];
    
    //***//
    
    NSUInteger length = ceilf(size[0] / kQx * size[1] / kQy);
    _m_HoughSpaceBuffer = [[GHTHoughSpaceBuffer alloc] initWithLength:length];
    [_m_HoughSpaceBuffer finalize:_m_Device];
    _houghSpaceFilter.outHoughSpaceBuffer = _m_HoughSpaceBuffer;
    _houghSpaceToTextureFilter.inHoughSpaceBuffer = _m_HoughSpaceBuffer;
    //***//
    
    BOOL isAcquired = [_m_HoughSpace finalize:_m_Device];
    
    if (!isAcquired)
    {
        NSLog(@"Error(%@): Failed creating a hough space buffer!", self.class);
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Phi setup
//  The phi kernel draws edges with direction information embedded inside the color values
- (id <MTLFunction>)_phiFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> phiFunction = [_m_ShaderLibrary newFunctionWithName:@"phiKernel"];
        
        if(!phiFunction)
        {
            NSLog(@"Error(%@): Failed creating a new phi function!", self.class);
            
            return nil;
        }
        
        return phiFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)_phiKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> phiKernel = [_m_Device newComputePipelineStateWithFunction:[self _phiFunction]
                                                                                                 error:error];
        
        if(!phiKernel)
        {
            NSLog(@"Error(%@): Failed creating a new phi kernel!", self.class);
            
            return nil;
        }
        
        return phiKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)_phiTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> phiTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!phiTexture)
        {
            NSLog(@"Error(%@): Failed creating a new phi texture!", self.class);
            
            return nil;
        }
        
        return phiTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

- (void)_addPhiKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                         inputTexture:(id <MTLTexture>)inTexture
                        outputTexture:(id <MTLTexture>)outTexture
{
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:_m_PhiKernel];
        [computeEncoder setTexture:inTexture atIndex:0];
        [computeEncoder setTexture:outTexture atIndex:1];
        [computeEncoder dispatchThreadgroups:_m_LocalCount
                       threadsPerThreadgroup:_m_WorkgroupSize];
        //[computeEncoder executeBarrier];
    }
}

#pragma mark - Canny setup
//  The canny kernel only draws the detected edges
- (id <MTLFunction>)_cannyFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> cannyFunction = [_m_ShaderLibrary newFunctionWithName:@"cannyKernel"];
        
        if(!cannyFunction)
        {
            NSLog(@"Error(%@): Failed creating a new canny function!", self.class);
            
            return nil;
        }
        
        return cannyFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)_cannyKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> cannyKernel = [_m_Device newComputePipelineStateWithFunction:[self _cannyFunction]
                                                                                          error:error];
        
        if(!cannyKernel)
        {
            NSLog(@"Error(%@): Failed creating a new canny kernel!", self.class);
            
            return nil;
        }
        
        return cannyKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)_cannyTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> cannyTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!cannyTexture)
        {
            NSLog(@"Error(%@): Failed creating a new canny texture!", self.class);
            
            return nil;
        }
        
        return cannyTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

#pragma mark - Model setup
//  The model kernel draws the model data
- (id <MTLFunction>)_modelFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> modelFunction = [_m_ShaderLibrary newFunctionWithName:@"modelKernel"];
        
        if(!modelFunction)
        {
            NSLog(@"Error(%@): Failed creating a new model function!", self.class);
            
            return nil;
        }
        
        return modelFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)_modelKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> modelKernel = [_m_Device newComputePipelineStateWithFunction:[self _modelFunction]
                                                                                            error:error];
        
        if(!modelKernel)
        {
            NSLog(@"Error(%@): Failed creating a new model kernel!", self.class);
            
            return nil;
        }
        
        return modelKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)_modelTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> modelTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!modelTexture)
        {
            NSLog(@"Error(%@): Failed creating a new model texture!", self.class);
            
            return nil;
        }
        
        return modelTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}

- (BOOL)_setupModelBufferWithResourceName:(NSString *)resourceName extension:(NSString *)extensionString
{
    _m_Model = [[GHTModel alloc] initWithResourceName:resourceName extension:extensionString];
    
    _m_ModelB = [[GHTModel alloc] initWithResourceName:@"002MOD__TestImage_32x32_black" extension:extensionString];
    [_m_ModelB finalize:_m_Device];
    
    //***//
    _modelFilter.modelBuffer = _m_Model;
    _houghSpaceFilter.modelBuffer = _m_Model;
    //***//
    
    BOOL isAcquired = [_m_Model finalize:_m_Device];
    
    if (!isAcquired)
    {
        NSLog(@"Error(%@): Failed creating a model buffer!", self.class);
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Normalize kernel setup
- (id <MTLFunction>)_normalizeFunction
{
    if (_m_ShaderLibrary)
    {
        id <MTLFunction> normalizeFunction = [_m_ShaderLibrary newFunctionWithName:@"normalizeKernel"];
        
        if(!normalizeFunction)
        {
            NSLog(@"Error(%@): Failed creating a new normalize function!", self.class);
            
            return nil;
        }
        
        return normalizeFunction;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}
- (id <MTLComputePipelineState>)_normalizeKernelWithError:(NSError **)error
{
    if (_m_Device)
    {
        id <MTLComputePipelineState> normalizeKernel = [_m_Device newComputePipelineStateWithFunction:[self _normalizeFunction]
                                                                                                error:error];
        
        if(!normalizeKernel)
        {
            NSLog(@"Error(%@): Failed creating a new normalize kernel!", self.class);
            
            return nil;
        }
        
        return normalizeKernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)_normalizeTextureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> normalizeTexture = [_m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!normalizeTexture)
        {
            NSLog(@"Error(%@): Failed creating a new normalize texture!", self.class);
            
            return nil;
        }
        
        return normalizeTexture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}
- (void)_addNormalizeKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                           houghSpaceBuffer:(GHTHoughSpace *)houghSpaceBuffer
                              outputTexture:(id <MTLTexture>)outTexture
{
    if (computeEncoder)
    {
        [computeEncoder setComputePipelineState:_m_NormalizeKernel];
        [computeEncoder setBuffer:houghSpaceBuffer.buffer offset:houghSpaceBuffer.offset atIndex:0];
        [computeEncoder setBuffer:houghSpaceBuffer.maxVotesBuffer offset:0 atIndex:1];
        [computeEncoder setTexture:outTexture atIndex:0];
        
        [computeEncoder dispatchThreadgroups:_m_LocalCount
                       threadsPerThreadgroup:_m_WorkgroupSize];
        //[computeEncoder executeBarrier];
    }
}

#pragma mark - Start up

- (BOOL)_start
{
    //  Default orientation is unknown
    _interfaceOrientation = UIInterfaceOrientationUnknown;
    
    //  grab the CAALayer created by the nib
    GHTView *renderView = (GHTView *)self.view;
    _m_RenderingLayer = (CAMetalLayer *)renderView.layer;
    
    if (!_m_RenderingLayer)
    {
        NSLog(@"Error(%@): Failed acquring Core Animation Metal layer!", self.class);
        
        return NO;
    }
    
    _m_RenderingLayer.presentsWithTransaction = NO;
    _m_RenderingLayer.drawsAsynchronously = YES;
    
    CGRect viewBounds = _m_RenderingLayer.frame;
    
    _m_Viewport = {0.0f, 0.0f, viewBounds.size.width, viewBounds.size.height, 0.0f, 1.0f};
    
    //  set a background color to make sure the layer appears
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    if (colorspace != NULL)
    {
        CGFloat components[4] = {0.0, 0.0, 0.0, 1.0};
        
        CGColorRef grayColor = CGColorCreate(colorspace, components);
        
        if (grayColor != NULL)
        {
            _m_RenderingLayer.backgroundColor = grayColor;
            
            CFRelease(grayColor);
        }
        
        CFRelease(colorspace);
    }
    
    //  find a usable Device //***//
    //_m_Device = MTLCreateSystemDefaultDevice();
    
    if (!_m_Device)
    {
        NSLog(@"Error(%@): Failed creating a default system device!", self.class);
        
        return NO;
    }
    
    // set the device on the rendering layer and provide a pixel format
    _m_RenderingLayer.device          = _m_Device;
    _m_RenderingLayer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
    _m_RenderingLayer.framebufferOnly = YES;
    
    // create a new command queue
    _m_CommandQueue = [_m_Device newCommandQueue];
    
    if(!_m_CommandQueue)
    {
        NSLog(@"Error(%@): Failed creating a new command queue!", self.class);
        
        return NO;
    }
    
    // Create a viewing matrix derived from an eye point, a reference point
    // indicating the center of the scene, and an up vector.
    simd::float3 eye    = {0.0, 0.0, 0.0};
    simd::float3 center = {0.0, 0.0, 1.0};
    simd::float3 up     = {0.0, 1.0, 0.0};
    
    _m_LookAt = AAPL::lookAt(eye, center, up);
    
    // Translate the object in (x,y,z) space.
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        _m_Translate = AAPL::translate(0.0f, 0.0f, _zoomScale);
    } else
    {
        _m_Translate = AAPL::translate(0.0f, 0.0f, _zoomScale);
    }
    
    
    // Set the default clear color
    _m_ClearColor = MTLClearColorMake(26.0f/255.0f, 34.0/255.0f, 47.0/255.0f, 1.0f);
    
    return YES;
}

- (void)_transform
{
    // Based on the device orientation, set the angle in degrees
    // between a plane which passes through the camera position
    // and the top of your screen and another plane which passes
    // through the camera position and the bottom of your screen.
    float dangle = 0.0f;
    
    switch(_interfaceOrientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            dangle   = kUIInterfaceOrientationLandscapeAngle;
            break;
            
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        default:
            dangle   = kUIInterfaceOrientationPortraitAngle;
            break;
    }
    
    // Describes a tranformation matrix that produces a perspective projection
    const float near   = kPrespectiveNear;
    const float far    = kPrespectiveFar;
    const float rangle = AAPL::radians(dangle);
    const float length = near * tanf(rangle);
    
//    float right   = length/_m_Quad.aspect;
    float right   = length/_computeBuilder.quad.aspect;
    float left    = -right;
    float top     = length;
    float bottom  = -top;
    
    simd::float4x4 perspective = AAPL::frustum_oc(left, right, bottom, top, near, far);
    
    // Create a viewing matrix derived from an eye point, a reference point
    // indicating the center of the scene, and an up vector.
    _m_QuadTransform = _m_LookAt * _m_Translate;
    
    // Create a linear _transformation matrix
    _m_QuadTransform = perspective * _m_QuadTransform;
    
    // Update the buffer associated with the linear _transformation matrix
    float *transform = (float *)[_computeBuilder.quadTransformBuffer contents];
    
    memcpy(transform, &_m_QuadTransform, kSizeSIMDFloat4x4);
}

- (void)_update
{
    // To correctly compute the aspect ration determine the device
    // interface orientation.
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // Update the quad and linear _transformation matrices, if and
    // only if, the device orientation is changed.
    if(_interfaceOrientation != orientation)
    {
        // Update the device orientation
        _interfaceOrientation = orientation;
        
        // Get the bounds for the current rendering layer
        _m_Quad.bounds = _m_RenderingLayer.frame;
        
        // Update the quad bounds
        [_m_Quad update];
        
        // Determine the linear transformation matrix
        [self _transform];
    }
}

#pragma mark - Rendering

- (MTLRenderPassDescriptor *)_renderPassDescriptorWithDrawable:(id <MTLTexture>)texture
{
    _m_RenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    if(!_m_RenderPassDescriptor)
    {
        NSLog(@"Error(%@): Failed acquiring a render pass descriptor!", self.class);
        
        return nil;
    }
    
    _m_RenderPassDescriptor.colorAttachments[0].texture     = texture;
    _m_RenderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
    _m_RenderPassDescriptor.colorAttachments[0].clearColor  = _m_ClearColor;
    _m_RenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    return _m_RenderPassDescriptor;
}

- (void)_compute:(id <MTLCommandBuffer>)commandBuffer
{
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    if(computeEncoder)
    {
        switch (_state)
        {
            case 0:
                /*  State 0
                 *  Input:              original image
                 *  Filter:             none
                 *  Expected output:    original image
                 */
                [self _addSourceKernelToComputeEncoder:computeEncoder inputTexture:_m_VideoTexture.texture outputTexture:_m_OutTexture];
                [self _addGaussKernelToComputeEncoder:computeEncoder inputTexture:_m_VideoTexture.texture outputTexture:_m_GaussianTexture];
                [self _addPhiKernelToComputeEncoder:computeEncoder inputTexture:_m_GaussianTexture outputTexture:_m_OutTexture];
//                [self _addPhiKernelToComputeEncoder:computeEncoder inputTexture:_m_GaussianTexture outputTexture:_m_PhiTexture];
//                [_houghSpaceFilter addHoughSpaceKernelToComputeEncoder:computeEncoder inTexture:_m_PhiTexture outputBuffer:_m_HoughSpaceBuffer.buffer];
//                [_houghSpaceToTextureFilter addHoughSpaceKernelToComputeEncoder:computeEncoder inBuffer:_m_HoughSpaceBuffer.houghBuffer outputTexture:_m_OutTexture];
  
                break;
            case 1:
                /*  State 1
                 *  Input:              original image
                 *  Filter:             Gauss
                 *  Expected output:    image with gauss applied
                 */
                [self _addGaussKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_OutTexture];
                break;
            case 2:
//                [self _addGaussKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_GaussianTexture];
//                [self _addPhiKernelToComputeEncoder:computeEncoder inputTexture:_m_GaussianTexture outputTexture:_m_OutTexture];
//                break;
//            case 3:
//                [self _addGaussKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_GaussianTexture];
//                [self _addPhiKernelToComputeEncoder:computeEncoder inputTexture:_m_GaussianTexture outputTexture:_m_PhiTexture];
//                [self _addHoughSpaceKernelToComputeEncoder:computeEncoder inputTexture:_m_PhiTexture houghSpaceBuffer:_m_HoughSpace modelBuffer:_m_Model];
//                //[self _addNormalizeKernelToComputeEncoder:computeEncoder houghSpaceBuffer:_m_HoughSpace outputTexture:_m_OutTexture];
//                [self _addVotingKernelToComputeEncoder:computeEncoder inputTexture:_m_PhiTexture outputTexture:_m_OutTexture modelBuffer:_m_Model];
//                break;
//            case 4:
//                [self _addSourceKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_OutTexture];
//                [self _addGaussKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_GaussianTexture];
//                [self _addPhiKernelToComputeEncoder:computeEncoder inputTexture:_m_GaussianTexture outputTexture:_m_PhiTexture];
//                [self _addVotingKernelToComputeEncoder:computeEncoder inputTexture:_m_PhiTexture outputTexture:_m_OutTexture modelBuffer:_m_Model];
//                break;
//            case 5:
//                [self _addSourceKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_OutTexture];
//                [self _addGaussKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_GaussianTexture];
//                [self _addPhiKernelToComputeEncoder:computeEncoder inputTexture:_m_GaussianTexture outputTexture:_m_PhiTexture];
//                [self _addVotingKernelToComputeEncoder:computeEncoder inputTexture:_m_PhiTexture outputTexture:_m_OutTexture modelBuffer:_m_ModelB];
//                
                break;

            default:
//                [self _addGaussKernelToComputeEncoder:computeEncoder inputTexture:_m_InTexture.texture outputTexture:_m_GaussianTexture];
//                [self _addPhiKernelToComputeEncoder:computeEncoder inputTexture:_m_GaussianTexture outputTexture:_m_PhiTexture];
//                [self _addHoughSpaceKernelToComputeEncoder:computeEncoder inputTexture:_m_PhiTexture houghSpaceBuffer:_m_HoughSpace modelBuffer:_m_Model];
//                //[self _addNormalizeKernelToComputeEncoder:computeEncoder houghSpaceBuffer:_m_HoughSpace outputTexture:_m_OutTexture];
//                [self _addVotingKernelToComputeEncoder:computeEncoder inputTexture:_m_PhiTexture outputTexture:_m_OutTexture modelBuffer:_m_Model];
                break;
        }
        
        [computeEncoder endEncoding];
        
        computeEncoder = nil;
    }
}

- (void)_encode:(id <MTLRenderCommandEncoder>)renderEncoder
{
    // set context state with the render encoder
    [renderEncoder setViewport:_m_Viewport];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setDepthStencilState:_computeBuilder.depthState];
    
    [renderEncoder setRenderPipelineState:_computeBuilder.pipelineState];
    
    [renderEncoder setVertexBuffer:_computeBuilder.quadTransformBuffer
                            offset:0
                           atIndex:2 ];
    
    [renderEncoder setFragmentTexture:_computeBuilder.outTexture
                              atIndex:0];
    
    [renderEncoder setFragmentSamplerState:_computeBuilder.quadSampler
                                   atIndex:0];
    
    // Encode quad vertex and texture coordinate buffers
    [_m_Quad encode:renderEncoder];
    
    // tell the render context we want to draw our primitives
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:6
                    instanceCount:1];
    
    [renderEncoder endEncoding];
}

- (void)_render:(id <MTLCommandBuffer>)commandBuffer
       drawable:(id <CAMetalDrawable>)drawable
{
    // obtain the renderpass descriptor for this drawable
    MTLRenderPassDescriptor *renderPassDescriptor = [self _renderPassDescriptorWithDrawable:drawable.texture];
    
    if(renderPassDescriptor)
    {
        // Get a render encoder
        id <MTLRenderCommandEncoder>  renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        renderPassDescriptor = nil;
        
        // Encode into a renderer
        [self _encode:renderEncoder];
        
        // Discard renderer and framebuffer
        renderEncoder = nil;
    }
}

- (void)_dispatch:(id <MTLCommandBuffer>)commandBuffer
{
    __block dispatch_semaphore_t dispatchSemaphore = _m_InflightSemaphore;
    
    [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb)
    {
        dispatch_semaphore_signal(dispatchSemaphore);
    }];
}

- (void)_commit:(id <MTLCommandBuffer>)commandBuffer
       drawable:(id <CAMetalDrawable>)drawable
{
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)render:(id)sender
{
    dispatch_semaphore_wait(_m_InflightSemaphore, DISPATCH_TIME_FOREVER);
    
    [self _update];
    
    id <CAMetalDrawable>  drawable      = [_m_RenderingLayer nextDrawable];
    id <MTLCommandBuffer> commandBuffer = [_m_CommandQueue commandBuffer];
    
    //[self _compute:commandBuffer];
    [_computeBuilder compute:commandBuffer];
    [self _render:commandBuffer
         drawable:drawable];
    
    [self _dispatch:commandBuffer];
    

    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>){
        [_computeBuilder.houghSpaceBuffer normalize];
        
    }];

    id <MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    [_computeBuilder.houghSpaceBuffer purgeHoughSpaceBufferWithpurgeHoughSpaceBufferWithBlitCommandEncoder:blitEncoder];
    [blitEncoder endEncoding];
    blitEncoder = nil;
    
    [self _commit:commandBuffer
         drawable:drawable];
    
    commandBuffer = nil;
    drawable      = nil;
}

- (id <MTLDevice>)device
{
    //  find a usable Device
    id <MTLDevice> device = MTLCreateSystemDefaultDevice();
    
    if (!device)
    {
        NSLog(@"Error(%@): Failed creating a default system device!", self.class);
    }
    
    return device;
}

- (id <MTLLibrary>)shaderLibrary
{
    id <MTLLibrary> library = [_m_Device newDefaultLibrary];
    
    if (!library)
    {
        NSLog(@"Error(%@): Failed to create a shared library!", self.class);
    }
    
    return library;
}

- (GHTQuad *)quad
{
    GHTQuad *quad = [[GHTQuad alloc] initWithDevice:_m_Device];
    
    if (!quad)
    {
        NSLog(@"Error(%@): Failed creating a quad object!", self.class);
    }
    
    return quad;
}

#pragma mark - View controller

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _m_Device = [self device];
    _m_ShaderLibrary = [self shaderLibrary];
    _m_Quad = [self quad];
    
    _computeBuilder = [[GHTComputeBuilder alloc] initWithShaderLibrary:_m_ShaderLibrary device:_m_Device quad:_m_Quad];
    
    for (UIViewController *childViewController in self.childViewControllers)
    {
        if ([childViewController isKindOfClass:[GHTFilterSettingsViewController class]])
        {
            ((GHTFilterSettingsViewController *)childViewController).delegate = self;
            ((GHTFilterSettingsViewController *)childViewController).computeBuilder = _computeBuilder;
            [_computeBuilder finalize];
        }
    }
    
    //Loads images - Should be move where it is actually used
    //[self initAssets];
    
    _zoomScale = 0.37;
    
    //This needs to be redone
    _state = 0;
    //[self displayString:@"1 - original image" forDuration:1.0];
    //
    
    if(![self _start])
    {
        NSLog(@"Error(%@): Failed initializations!", self.class);
        
        [self _cleanUp];
        
        exit(-1);
    }
    else
    {
        if(![self _setupWithTextureName:@"circle" extension:@"png"])
        {
            NSLog(@"Error(%@): Failed creating assets!", self.class);
            
            [self _cleanUp];
            
            exit(-1);
        }
        else
        {
            //Initial update
            // Get the bounds for the current rendering layer
            //_m_Quad.bounds = _m_RenderingLayer.frame;
            _computeBuilder.quad.bounds = _m_RenderingLayer.frame;
            // Update the quad bounds
            //[_m_Quad update];
            [_computeBuilder.quad update];
            
            // Determine the linear transformation matrix
            [self _transform];
            
            //Setup the timer
            _m_InflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
            
            // as the timer fires, we render
            _m_Timer = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(render:)];
            
            [_m_Timer addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSDefaultRunLoopMode];
            
            
//            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//            [self.view addGestureRecognizer:tapRecognizer];
            UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
            [self.view addGestureRecognizer:pinchRecognizer];
            UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [self.view addGestureRecognizer:panRecognizer];
        }
    }
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if([self isViewLoaded] && ([[self view] window] == nil))
    {
        self.view = nil;
        
        [self _cleanUp];
    }
}

- (void)displayString:(NSString *)string forDuration:(NSTimeInterval)timeInterval
{
    _stateLabel.text = [string copy];
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void){
        _stateLabel.alpha = 1.0;
    } completion:^(BOOL){
        [UIView animateWithDuration:0.1 delay:timeInterval options:UIViewAnimationOptionAllowUserInteraction animations:^(void){
            _stateLabel.alpha = 0.0;
        } completion:NULL];
    }];
}

#pragma mark - gestures
- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
    _state = (_state + 1) % 6;
    switch (_state)
    {
        case 0:
            [self displayString:@"0 - original image" forDuration:1.0];
            break;
        case 1:
            [self displayString:@"1 - image with gauss filter applied" forDuration:1.0];
            break;
        case 2:
            [self displayString:@"2 - something something" forDuration:1.0];
            break;
        case 3:
            [self displayString:@"3 - something something" forDuration:1.0];
            break;
        case 4:
            [self displayString:@"4 - something something" forDuration:1.0];
            break;
        default:
            [self displayString:@"unknown state" forDuration:1.0];

            break;
    }
    
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    _zoomScale *= 1 + (1 - recognizer.scale);
    
    if (_zoomScale < 0.1) {
        _zoomScale = 0.1;
    }
    [self displayString:[NSString stringWithFormat:@"%f",_zoomScale] forDuration:0.01];
    _m_Translate = AAPL::translate(0.0f, 0.0f, _zoomScale);
    [self _transform];
    recognizer.scale = 1;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    
    if (translation.x > 0)
    {
        
    }
    _m_Translate = AAPL::translate(translation.x/10000.0, translation.y/10000.0, 0.0f);
    //[self _transform];
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

#pragma mark - Filter Selection
- (IBAction)filterSettingsPressed:(id)sender
{
    [_filterSettingsContainer setHidden:NO];
    [_filterSettingsButton setHidden:YES];
}

#pragma mark - Input Selection

- (IBAction)inputPressed:(UIButton *)sender
{
    if ([_inputCollectionView isHidden])
    {
        _inputCollectionView.hidden = NO;
        [sender setTitle:@"Cancel" forState:UIControlStateNormal];
    } else
    {
        _inputCollectionView.hidden = YES;
        [sender setTitle:@"Input" forState:UIControlStateNormal];
    }
}

- (IBAction)dismissInputView:(id)sender {
    _inputCollectionView.hidden = YES;
    _inputButton.hidden = NO;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_m_Timer invalidate];
    _m_Timer = nil;
    
    GHTInputImageCollectionViewCell *cell = (GHTInputImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (CGImageGetWidth(cell.image.CGImage) * CGImageGetHeight(cell.image.CGImage) < 400000)
    {
        [self _setupWithImage:cell.image];
    } else
    {
        [self displayString:@"Image size too large" forDuration:1.0];
    }
    
    //Initial update
    // Get the bounds for the current rendering layer
    _m_Quad.bounds = _m_RenderingLayer.frame;
    
    // Update the quad bounds
    [_m_Quad update];
    
    // Determine the linear transformation matrix
    [self _transform];
    
    //Setup the timer
    _m_InflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
    
    // as the timer fires, we render
    _m_Timer = [CADisplayLink displayLinkWithTarget:self
                                           selector:@selector(render:)];
    
    [_m_Timer addToRunLoop:[NSRunLoop mainRunLoop]
                   forMode:NSDefaultRunLoopMode];
    
    _inputCollectionView.hidden = YES;
    [_inputButton setTitle:@"Input" forState:UIControlStateNormal];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GHTInputImageCollectionViewCell *cell = (GHTInputImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"inputImageCell" forIndexPath:indexPath];
    
    ALAsset *asset = self.assets[indexPath.row];
    
    cell.asset = asset;
    
    return cell;
}

//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
//{
//    UICollectionReusableView *reusableview = nil;
//    
//    if (kind == UICollectionElementKindSectionHeader)
//    {
//        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
//        
//        reusableview = headerView;
//    }
//        
//    return reusableview;
//}

#pragma mark - GHTFilterSettingsDelegate
- (void)cancelFilterSettings
{
    [_filterSettingsButton setHidden:NO];
    [_filterSettingsContainer setHidden:YES];
}

#pragma mark - image loading
- (void)initAssets
{
    _assets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    // 1
    ALAssetsLibrary *assetsLibrary = [ViewController defaultAssetsLibrary];
    // 2
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result)
            {
                // 3
                [tmpAssets addObject:result];
            }
        }];
        
        // 4
        //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        //self.assets = [tmpAssets sortedArrayUsingDescriptors:@[sort]];
        self.assets = tmpAssets;
        
        // 5
        [self.inputCollectionView reloadData];
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading images %@", error);
    }];
}

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}
@end
