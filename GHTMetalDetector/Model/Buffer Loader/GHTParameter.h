//
//  GHTParameter.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 21.10.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface GHTParameter : NSObject

@property (nonatomic, readonly) id <MTLBuffer>  buffer;
@property (nonatomic, readwrite) NSUInteger     offset;

@property (nonatomic, readonly) simd::uint2     houghSpaceQuantization;
@property (nonatomic, readonly) simd::uint2     houghSpaceSize;
@property (nonatomic, readonly) unsigned int    houghSpaceLength;

@property (nonatomic, readonly) simd::uint2     sourceSize;
@property (nonatomic, readonly) unsigned int    sourceLength;

@property (nonatomic, readonly) simd::uint2     modelSize;
@property (nonatomic, readonly) unsigned int    modelLength;

- (instancetype)initWithImageSize:(simd::uint2)imageSize quantization:(simd::uint2)quantization modelSize:(simd::uint2)modelSize numberOfModelPoints:(unsigned int)modelLength;

- (BOOL)finalize:(id<MTLDevice>)device;
@end
