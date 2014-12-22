//
//  GHTInput.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTInput.h"

@implementation GHTInput

- (BOOL)finalize:(id<MTLDevice>)device
{
    //No-op.
    
    return NO;
}

#pragma mark - getter/setter

- (void)setWidth:(uint32_t)width
{
    _width = width;
    [self.delegate didChangeResolutionTo:(simd::uint2){self.width, self.height}];
}

- (void)setHeight:(uint32_t)height
{
    _height = height;
    [self.delegate didChangeResolutionTo:(simd::uint2){self.width, self.height}];
}

- (void)setDelegate:(id<GHTInputDelegate>)delegate
{
    _delegate = delegate;
    if (_width && _height)
    {
        [self.delegate didChangeResolutionTo:(simd::uint2){_width, _height}];
    }
}
@end
