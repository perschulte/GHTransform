//
//  GHTInput.h
//  GHTransform
//
//  Created by Per Schulte on 26.11.14.
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
#import <UIKit/UIKit.h>
#import <simd/simd.h>

@protocol GHTInputDelegate <NSObject>

- (void)didChangeResolutionTo:(simd::uint2)size;

@end

@interface GHTInput :NSObject
@property (nonatomic, weak) id <GHTInputDelegate> delegate;
@property (nonatomic, readwrite) id <MTLTexture> texture;
@property (nonatomic, readwrite) MTLTextureType  target;
@property (nonatomic, readwrite) uint32_t        width;
@property (nonatomic, readwrite) uint32_t        height;
@property (nonatomic, readwrite) uint32_t        format;

- (BOOL)finalize:(id<MTLDevice>)device;

@end
