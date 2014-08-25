//
//  GHTNormalizedRange.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 14.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface GHTNormalizedRange : NSObject

@property (nonatomic, readonly) id <MTLBuffer>  buffer;
@property (nonatomic, readwrite) NSUInteger     offset;

@property (nonatomic, readonly) int             length;

- (instancetype)initWithImageSize:(simd::uint2)imageSize quantization:(simd::uint2)quantization;

- (BOOL)finalize:(id<MTLDevice>)device;


@end
