//
//  GHTHoughSpace.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.08.14.
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
