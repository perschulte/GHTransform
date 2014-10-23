//
//  GHTHoughSpace.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface GHTHoughSpace : NSObject

@property (nonatomic, readonly) id <MTLBuffer>  buffer;
@property (nonatomic, readonly) id <MTLBuffer>  emptyBuffer;
@property (nonatomic, readonly) id <MTLBuffer>  maxVotesBuffer;

@property (nonatomic, readwrite) NSUInteger     offset;

@property (nonatomic, readonly) simd::uint2     quantization;
@property (nonatomic, readonly) simd::uint2     imageSize;

@property (nonatomic, readonly) unsigned int    length;

- (instancetype)initWithImageSize:(simd::uint2)imageSize quantization:(simd::uint2)quantization;

- (BOOL)finalize:(id<MTLDevice>)device;

//- (id<MTLBuffer>)targetBufferWithDevice:(id<MTLDevice>)device size:(NSUInteger)size;
//
//- (id<MTLBuffer>)normalizedHoughSpaceBuffer:(id<MTLDevice>)device;

- (BOOL)finalizeHoughSpaceMaxWithDevice:(id<MTLDevice>)device;
@end
