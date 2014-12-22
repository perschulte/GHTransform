//
//  GHTHoughSpace.mm
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTHoughSpace.h"
#import "GHTSharedTypes.h"

@interface GHTHoughSpace ()
{
    GHT::HoughSpaceCell *_emptyBufferData;
    GHT::houghSpace *_emptyHoughBuffer;
    float _maxAccumulatedVotes;
}

@end

@implementation GHTHoughSpace

- (instancetype)initWithImageSize:(simd::uint2)imageSize quantization:(simd::uint2)quantization
{
    self = [super init];
    
    if (self)
    {
        _quantization = quantization;
        _imageSize = imageSize;
        
        _offset     = 0;
        
        _maxAccumulatedVotes = 0.0;
    }
    
    return self;
}

- (void)dealloc
{
    _buffer = nil;
}

- (GHT::HoughSpaceCell *)houghSpace
{
    //_imagesize = (32,32)
    //_quantization = (1,1)
    // -> Houghspace = (32,32)
    
    //_imagesize = (32,32)
    //_quantization = (3,3)
    // -> Houghspace = (11,11)
    
    //_imagesize = (32,32)
    //_quantization = (6,6)
    // -> Houghspace = (6,6)
    
    _length = ceilf(_imageSize[0] / _quantization[0]) * ceilf(_imageSize[1] / _quantization[1]);
    
    GHT::HoughSpaceCell *houghSpace = (GHT::HoughSpaceCell *)malloc(sizeof(GHT::HoughSpaceCell) * _length);
    
    for (int i = 0; i < _length; i++)
    {
        GHT::HoughSpaceCell cell;
        cell.numVotes           = 0;
        cell.accumulatedVotes   = 0.0f;
        cell.quantization       = _quantization;
        cell.size               = _imageSize;
        houghSpace[i]           = cell;
    }
    
    _emptyBufferData = houghSpace;
    
    return houghSpace;
}

- (GHT::houghSpace*)hough
{
    //_imagesize = (32,32)
    //_quantization = (1,1)
    // -> Houghspace = (32,32)
    
    //_imagesize = (32,32)
    //_quantization = (3,3)
    // -> Houghspace = (11,11)
    
    //_imagesize = (32,32)
    //_quantization = (6,6)
    // -> Houghspace = (6,6)
    
    _length = ceilf(_imageSize[0] / _quantization[0]) * ceilf(_imageSize[1] / _quantization[1]);
    
    GHT::houghSpace *houghSpace = (GHT::houghSpace *)malloc(sizeof(GHT::houghSpace) * _length);
    
    for (int i = 0; i < _length; i++)
    {
        GHT::houghSpace cell;
        cell.accumulatedVotes   = 0.0f;
        houghSpace[i]           = cell;
    }
    
    _emptyHoughBuffer = houghSpace;
    
    return houghSpace;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    GHT::houghSpace *data = [self hough];
    
    if (!_emptyBuffer)
    {
        _emptyBuffer = _buffer = [device newBufferWithBytes:data
                                                     length:sizeof(GHT::houghSpace)*_length
                                                    options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    _maxVotesBuffer = [device newBufferWithBytes:&_maxAccumulatedVotes
                                          length:sizeof(float)
                                         options:MTLResourceOptionCPUCacheModeDefault];
    _buffer.label = @"HoughSpaceBuffer";
    free(data);
    if(!_buffer)
    {
        NSLog(@"Error(%@): Could not create buffer", self.class);
        return NO;
    }
    
    return YES;
}

- (BOOL)finalizeHoughSpaceMaxWithDevice:(id<MTLDevice>)device
{
    float result = 0.0;
    
    GHT::houghSpace *data = (GHT::houghSpace *)[_buffer contents];
    
    for (int i = 0; i<_length; i++)
    {
        //NSLog(@"%f Row:%d", data[i].accumulatedVotes, i / data[i].size[1]);
        if (data[i].accumulatedVotes > result)
        {
            result = data[i].accumulatedVotes;
        }
    }
    
    GHT::HoughSpaceCell *bufferPointer = (GHT::HoughSpaceCell *)[_buffer contents];
    memcpy(bufferPointer, &_emptyBufferData, sizeof(GHT::HoughSpaceCell));
    
    _maxAccumulatedVotes = result;
    
    _maxVotesBuffer = [device newBufferWithBytes:&_maxAccumulatedVotes
                                                     length:sizeof(float)
                                                    options:MTLResourceOptionCPUCacheModeDefault];
    

    if(!_maxVotesBuffer)
    {
        NSLog(@"Error(%@): Could not create buffer", self.class);
        return NO;
    }
    
    return YES;
}
@end
