//
//  ViewController.mm
//  GHTransform
//
//  Created by Per Schulte on 28.07.14.
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

#import "ViewController.h"

#import <string.h>

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "AAPLTransforms.h"
#import "GHTQuad.h"
#import "GHTTexture.h"
#import "GHTView.h"

#import "GHTFilterSettingsViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

static const float kUIInterfaceOrientationLandscapeAngle = 45.0f;
static const float kUIInterfaceOrientationPortraitAngle  = 45.0f;

static const float kPrespectiveNear = 0.1f;
static const float kPrespectiveFar  = 100.0f;

static const uint32_t kSizeSIMDFloat4x4 = sizeof(simd::float4x4);

// Only allow 1 command buffers in flight at any given time so
// we don't overwrite the renderpass descriptor.
static const uint32_t kInFlightCommandBuffers = 1;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIButton *inputButton;
@property (weak, nonatomic) IBOutlet UIButton *filterSettingsButton;
@property (weak, nonatomic) IBOutlet UIView *filterSettingsContainer;

//Input
@property (nonatomic, strong) NSArray *assets;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, assign) float zoomScale;

//Compute Builder
@property (nonatomic, strong) GHTComputeBuilder *computeBuilder;

//Render globals
@property (nonatomic, strong) id <MTLDevice>                m_Device;
@property (nonatomic, strong) id <MTLCommandQueue>          m_CommandQueue;
@property (nonatomic, strong) id <MTLLibrary>               m_ShaderLibrary;
@property (nonatomic, strong) MTLRenderPassDescriptor      *m_RenderPassDescriptor;

//App control
@property (nonatomic, strong) CADisplayLink                *m_Timer;
@property (nonatomic, strong) dispatch_semaphore_t          m_InflightSemaphore;

//Quad setup
@property (nonatomic, strong) GHTQuad                      *m_Quad;             //Quad representation
@property (nonatomic, assign) simd::float4x4                m_QuadTransform;

//Textures
@property (nonatomic, strong) id <MTLTexture>               m_OutTexture;

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
    
    //Quad setup
    _m_Quad                 = nil;
    
    //Textures
    _m_OutTexture           = nil;
    
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
            [_computeBuilder finalizeBuffer];
        }
    }
    
    _zoomScale = 0.37;
    
    if(![self _start])
    {
        NSLog(@"Error(%@): Failed initializations!", self.class);
        
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
        
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self.view addGestureRecognizer:pinchRecognizer];
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.view addGestureRecognizer:panRecognizer];
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

#pragma mark - GHTFilterSettingsDelegate
- (void)cancelFilterSettings
{
    [_filterSettingsButton setHidden:NO];
    [_filterSettingsContainer setHidden:YES];
}

@end
