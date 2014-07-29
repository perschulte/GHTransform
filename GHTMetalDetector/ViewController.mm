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

static const float kUIInterfaceOrientationLandscapeAngle = 35.0f;
static const float kUIInterfaceOrientationPortraitAngle  = 50.0f;

static const float kPrespectiveNear = 0.1f;
static const float kPrespectiveFar  = 100.0f;

static const uint32_t kSizeSIMDFloat4x4 = sizeof(simd::float4x4);

// Only allow 1 command buffers in flight at any given time so
// we don't overwrite the renderpass descriptor.
static const uint32_t kInFlightCommandBuffers = 1;
static const uint32_t kMaxBufferBytesPerFrame = kSizeSIMDFloat4x4;

@interface ViewController ()

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

//Render globals
@property (nonatomic, strong) id <MTLDevice>                m_Device;
@property (nonatomic, strong) id <MTLCommandQueue>          m_CommandQueue;
@property (nonatomic, strong) id <MTLLibrary>               m_ShaderLibrary;
@property (nonatomic, strong) id <MTLDepthStencilState>     m_DepthState;
@property (nonatomic, strong) MTLRenderPassDescriptor      *m_RenderPassDescriptor;

//App control
@property (nonatomic, strong) CADisplayLink                *m_timer;
@property (nonatomic, assign) dispatch_semaphore_t          m_InflightSemaphore;

//Quad setup
@property (nonatomic, strong) id <MTLRenderPipelineState>   m_PipelineState;
@property (nonatomic, strong) id <MTLSamplerState>          m_QuadSampler;
@property (nonatomic, strong) GHTQuad                      *m_Quad;             //Quad representation
@property (nonatomic, assign) CGSize                        m_QuadTextureSize;  //Dimensions
@property (nonatomic, assign) simd::float4                  m_QuadTransform;
@property (nonatomic, strong) id <MTLBuffer>                m_QuadTransformBuffer;

//Textures
@property (nonatomic, strong) GHTTexture                   *m_InTexture;
@property (nonatomic, strong) id <MTLTexture>               m_OutTexture;

//Filter textures
@property (nonatomic, strong) id <MTLTexture>               m_GaussianTexture;
@property (nonatomic, strong) id <MTLTexture>               m_VotingTexture;
@property (nonatomic, strong) id <MTLTexture>               m_HoughSpaceTexture;
@property (nonatomic, strong) id <MTLTexture>               m_PhiTexture;
@property (nonatomic, strong) id <MTLTexture>           	m_CannyTexture;
@property (nonatomic, strong) id <MTLTexture>           	m_ModelTexture;

//Filter kernels
@property (nonatomic, strong) id <MTLComputePipelineState>  m_GaussKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_VotingKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_HoughSpaceKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_PhiKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_CannyKernel;
@property (nonatomic, strong) id <MTLComputePipelineState>  m_ModelKernel;

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
    _m_GaussianTexture      = nil;
    _m_VotingTexture        = nil;
    _m_HoughSpaceTexture    = nil;
    _m_PhiTexture           = nil;
    _m_CannyTexture         = nil;
    _m_ModelTexture         = nil;
    
    //Filter kernels
    _m_GaussKernel          = nil;
    _m_VotingKernel         = nil;
    _m_HoughSpaceKernel     = nil;
    _m_PhiKernel            = nil;
    _m_CannyKernel          = nil;
    _m_ModelKernel          = nil;

    // Framebuffer/drawable
    _m_RenderingLayer       = nil;
    
    if(_m_timer)
    {
        [_m_timer invalidate];
    }
    
    _m_timer = nil;
}

- (void)dealloc
{
    [self _cleanUp];
}

#pragma mark - Setup
- (BOOL)_setupWithTextureName:(NSString *)textureNameString
                    extension:(NSString *)extensionString
{
    NSError *error = nil;
    
    [self _setupWithError:&error];
    
    return YES;
}

- (BOOL)_setupWithError:(NSError **)error
{
    _m_ShaderLibrary = [_m_Device newDefaultLibrary];
    
    if (!_m_ShaderLibrary)
    {
        NSLog(@"Error(%@): Failed to create a shared library!", self.class);
        
        return NO;
    }
    
    //Gauss kernel
    _m_GaussKernel          = [self _gaussKernelWithError:error];
    
    //Voting kernel
    _m_VotingKernel         = [self _votingKernelWithError:error];
    
    //Hough space kernel
    _m_HoughSpaceKernel     = [self _houghSpaceKernelWithError:error];
    
    //Phi kernel
    _m_PhiKernel            = [self _phiKernelWithError:error];
    
    //Canny kernel
    _m_CannyKernel          = [self _cannyKernelWithError:error];
    
    //Model kernel
    _m_ModelKernel          = [self _modelKernelWithError:error];
    
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
    
    return YES;
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

#pragma mark - View controller
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
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


@end
