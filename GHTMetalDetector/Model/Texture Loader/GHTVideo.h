//
//  GHTVideo.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreVideo/CVMetalTextureCache.h>
#import <CoreVideo/CVMetalTexture.h>
#import "GHTInput.h"

@interface GHTVideo : GHTInput <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readwrite)BOOL            flip;

@property (nonatomic, strong) AVCaptureSession  *captureSession;
@property (nonatomic, strong) AVCaptureDevice   *captureDevice;
@property (nonatomic, strong) NSString* captureSessionPreset;
@property (nonatomic, assign) AVCaptureDevicePosition capturePosition;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCacheRef;
@property (nonatomic, assign) CVMetalTextureRef textureRef;

- (instancetype)initWithSourceSize:(CGSize)sourceSize;
- (BOOL)finalize:(id<MTLDevice>)device;


@end
