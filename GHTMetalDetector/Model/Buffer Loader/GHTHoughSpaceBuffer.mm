//
//  GHTHoughSpaceBuffer.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTHoughSpaceBuffer.h"
#import "GHTSharedTypes.h"
@interface GHTHoughSpaceBuffer ()


@end

@implementation GHTHoughSpaceBuffer

- (instancetype)initWithLength:(NSUInteger)length
{
    self = [super init];
    if (self)
    {
        self.length = length;
    }
    
    return self;
}

- (float *)houghSpaceBuffer
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
    
    float *houghSpace = (float *)malloc(sizeof(float) * self.length);
    
    for (int i = 0; i < self.length; i++)
    {
//        GHT::houghSpace cell;
//        cell.accumulatedVotes   = 0.0f;
        houghSpace[i]           = 0.0f;
    }
    
    return houghSpace;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    float *data = [self houghSpaceBuffer];
    
    if (!self.houghBuffer)
    {
        self.houghBuffer = [device newBufferWithBytes:data length:self.length * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
        self.houghBuffer.label = @"emptyBuffer";
    }
    
    self.buffer = [device newBufferWithBytes:data
                                      length:self.length * sizeof(GHT::houghSpace)
                                     options:MTLResourceOptionCPUCacheModeDefault];
    
    self.buffer.label = @"HoughSpaceBuffer";
    free(data);
    
    if(!self.buffer)
    {
        NSLog(@"Error(%@): Could not create buffer", self.class);
        return NO;
    }
    
    return YES;
}

- (void)purgeHoughSpaceBufferWithpurgeHoughSpaceBufferWithBlitCommandEncoder:(id <MTLBlitCommandEncoder>)blitCommandEncoder;
{
    [blitCommandEncoder copyFromBuffer:self.buffer sourceOffset:self.offset toBuffer:self.houghBuffer destinationOffset:self.offset size:self.length * sizeof(GHT::houghSpace)];
    
    [blitCommandEncoder fillBuffer:self.buffer range:NSMakeRange(0, self.length * sizeof(GHT::houghSpace)) value:0.0];
}

- (void)normalize
{
    float max = 0.0;
    
    GHT::houghSpace *houghSpace = (GHT::houghSpace *)[self.houghBuffer contents];
    for (int i = 0 ; i < self.length; i++)
    {
        if (houghSpace[i].accumulatedVotes > 0)
        {
            if (houghSpace[i].accumulatedVotes > max)
            {
                max = houghSpace[i].accumulatedVotes;
            }
        }
    }
    
    for (int i = 0 ; i < self.length; i++)
    {
        if (max < 2)
        {
            houghSpace[i].accumulatedVotes = 0.0;
        } else
        {
//            if (houghSpace[i].accumulatedVotes == max)
//            {
//               houghSpace[i].accumulatedVotes = 1.0;
//            } else
//            {
//                houghSpace[i].accumulatedVotes = 0.0;
//            }
            houghSpace[i].accumulatedVotes = houghSpace[i].accumulatedVotes / max;
        }
    }
}

- (void)debugPrintBuffer
{
    GHT::houghSpace *houghSpace = (GHT::houghSpace *)[self.houghBuffer contents];
    for (int i = 0 ; i < self.length; i++)
    {
        if (houghSpace[i].accumulatedVotes > 0)
        {
            NSLog(@"%d: %f", i, houghSpace[i].accumulatedVotes);
        }
    }
}

- (void)dealloc
{
    self.houghBuffer = nil;
}
@end
