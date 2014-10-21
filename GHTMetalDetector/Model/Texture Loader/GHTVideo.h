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

@interface GHTVideo : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readonly) id <MTLTexture> texture;
@property (nonatomic, readonly) MTLTextureType  target;
@property (nonatomic, readonly) uint32_t        width;
@property (nonatomic, readonly) uint32_t        height;
@property (nonatomic, readonly) uint32_t        format;
@property (nonatomic, readwrite)BOOL            flip;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCacheRef;
@property (nonatomic, assign) CVMetalTextureRef textureRef;

- (BOOL)finalize:(id<MTLDevice>)device;


@end
