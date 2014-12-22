//
//  GHTParameter.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 21.10.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTBuffer.h"

@interface GHTParameter : GHTBuffer

@property (nonatomic, readwrite) simd::uint2     houghSpaceQuantization;
@property (nonatomic, readwrite) simd::uint2     houghSpaceSize;
@property (nonatomic, readwrite) unsigned int    houghSpaceLength;

@property (nonatomic, readwrite) simd::uint2     sourceSize;
@property (nonatomic, readwrite) unsigned int    sourceLength;

@property (nonatomic, readwrite) simd::uint2     modelSize;
@property (nonatomic, readwrite) unsigned int    modelLength;

- (instancetype)initWithImageSize:(simd::uint2)imageSize quantization:(simd::uint2)quantization modelSize:(simd::uint2)modelSize numberOfModelPoints:(unsigned int)modelLength;

- (BOOL)finalize:(id<MTLDevice>)device;
@end
