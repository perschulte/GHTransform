//
//  GHTHoughSpace.mm
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTHoughSpace.h"
#import "GHTSharedTypes.h"

@implementation GHTHoughSpace

- (instancetype)initWithImageSize:(simd::uint2)imageSize quantization:(simd::float2)quantization
{
    self = [super init];
    
    if (self)
    {
        _quantization = quantization;
        _imageSize = imageSize;
        
        _offset     = 0;
    }
    
    return self;
}

- (GHT::HoughSpaceCell *)houghSpace
{
    GHT::HoughSpaceCell *houghSpace = (GHT::HoughSpaceCell *)malloc(sizeof(GHT::Model) * _length);
    
    return houghSpace;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    GHT::HoughSpaceCell *data = nil;
    
    _buffer = [device newBufferWithBytes:data
                                  length:sizeof(GHT::HoughSpaceCell)*_length
                                 options:MTLResourceOptionCPUCacheModeDefault];
    
    free(data);
    if(!_buffer)
    {
        NSLog(@"Error(%@): Could not create buffer", self.class);
        return NO;
    }
    
    return YES;
}
@end
