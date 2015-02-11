//
//  GHTHoughSpaceBuffer.m
//  GHTMetalDetector
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
    float *houghSpace = (float *)malloc(sizeof(float) * self.length);
    
    for (int i = 0; i < self.length; i++)
    {
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
            
            //Uncomment to show only the best result
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
