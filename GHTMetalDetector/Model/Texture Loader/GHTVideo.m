//
//  GHTVideo.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTVideo.h"

@implementation GHTVideo
- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _width      = 0;
        _height     = 0;
        _format     = MTLPixelFormatRGBA8Unorm;
        _target     = MTLTextureType2D;
        _texture    = nil;
        _flip       = NO;
    }
    
    return self;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, device, NULL, &_textureCacheRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    _width  = 32;
    _height = 32;
    
    uint32_t width      = _width;
    uint32_t height     = _height;
    uint32_t rowBytes   = width * 4;
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 8,
                                                 rowBytes,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if (!context)
    {
        NSLog(@"Error(%@): Could not create context", self.class);
        return NO;
    }
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, _width, _height);
    
    CGContextClearRect(context, bounds);
    
    //Vertical reflect
    if (_flip)
    {
        CGContextTranslateCTM(context, width, height);
        CGContextScaleCTM(context, -1.0, -1.0);
    }

    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:width height:height mipmapped:NO];
    
    _target     = textureDescriptor.textureType;
    _texture    = [device newTextureWithDescriptor:textureDescriptor];
    
    textureDescriptor = nil;
    
    if(!_texture)
    {
        CGContextRelease(context);
        NSLog(@"Error(%@): Could not create texture", self.class);
        return NO;
    }
    
    //Read pixel information from the context and place them on the texture
    const void *pixels = CGBitmapContextGetData(context);
    
    if (pixels != NULL)
    {
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:pixels
                    bytesPerRow:rowBytes];
    }
    
    CGContextRelease(context);
    
    [self _setupVideoCapture];
    
    return YES;
}

- (void)_setupVideoCapture
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    if ([session canSetSessionPreset:AVCaptureSessionPreset640x480])
    {
        session.sessionPreset = AVCaptureSessionPreset640x480;
        
    } else
    {
        // Handle the failure.
    }
    
    
    [session beginConfiguration];
    AVCaptureDevice *device = [AVCaptureDevice
                               defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    if ([session canAddInput:input])
    {
        [session addInput:input];
    }
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:videoOutput];
    
    // Remove an existing capture device.
    // Add a new capture device.
    // Reset the preset.
    [session commitConfiguration];
    
    [session startRunning];
    
    //    CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _m_Device, NULL, _textureCacheRef);
    
    _session = session;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCacheRef, pixelBuffer, NULL, MTLPixelFormatA1BGR5Unorm, 32, 32, 0, &_textureRef);
    
}

@end
