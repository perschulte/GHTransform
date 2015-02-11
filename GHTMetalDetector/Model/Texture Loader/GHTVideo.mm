//
//  GHTVideo.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.08.14.
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

#import "GHTVideo.h"

@implementation GHTVideo
- (instancetype)initWithSourceSize:(CGSize)sourceSize
{
    self = [self init];
    
    if (self)
    {
        self.width      = sourceSize.width;
        self.height     = sourceSize.height;
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.format     = MTLPixelFormatRGBA8Unorm;
        self.target     = MTLTextureType2D;
        self.texture    = nil;
        _flip           = YES;
        self.captureSessionPreset = AVCaptureSessionPreset352x288;
        _capturePosition = AVCaptureDevicePositionFront;
    }
    
    return self;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    [self setupCaptureWithDevice:device];
    
    return YES;
}

- (void)setupCaptureWithDevice:(id <MTLDevice>)device
{
    self.texture = nil;
    _captureSession = nil;
    _captureDevice = nil;
    CVMetalTextureCacheCreate(NULL, NULL, device, NULL, &_textureCacheRef);
    
    //Device
    _captureDevice = [self captureDevice];

    //Session
    _captureSession = [[AVCaptureSession alloc] init];
    if ([_captureSession canSetSessionPreset:_captureSessionPreset])
    {
        _captureSession.sessionPreset = _captureSessionPreset;
        
    } else
    {
        // Handle the failure.
    }
    
    //Input
    AVCaptureInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:nil];
    [_captureSession addInput:input];
    
    //Output
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_captureSession addOutput:videoOutput];
    
    [_captureSession startRunning];
}

- (AVCaptureDevice *)captureDevice
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == _capturePosition)
        {
            captureDevice = device;
            break;
        }
    }
    
    // if specific device was not found
    if (!captureDevice)
    {
        NSLog(@"No camera found");
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    id <MTLTexture> textureY = nil;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, _textureCacheRef, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm_sRGB, width, height, 0, &_textureRef);
    if (status == kCVReturnSuccess)
    {
        textureY = CVMetalTextureGetTexture(_textureRef);
        //[textureY setLabel:@"VideoCaptureTexture"];
        CFRelease(_textureRef);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.texture setLabel:@"InputTexture"];
        self.texture = textureY;
    });
}

#pragma mark - Getter/Setter

- (void)setCaptureSessionPreset:(NSString *)captureSessionPreset
{
    _captureSessionPreset = captureSessionPreset;

    if ([captureSessionPreset isEqualToString:AVCaptureSessionPreset352x288])
    {
        self.width = 352;
        self.height = 288;
    } else if ([captureSessionPreset isEqualToString:AVCaptureSessionPresetLow])
    {
        self.width = 192;
        self.height = 144;
    }
}


@end
