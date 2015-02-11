//
//  GHTParameter.mm
//  GHTMetalDetector
//
//  Created by Per Schulte on 21.10.14.
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


#import "GHTParameter.h"
#import "GHTSharedTypes.h"

@implementation GHTParameter

- (instancetype)initWithImageSize:(simd::uint2)imageSize quantization:(simd::uint2)quantization modelSize:(simd::uint2)modelSize numberOfModelPoints:(unsigned int)modelLength
{
    self = [self init];
    
    if (self)
    {
        _houghSpaceQuantization = quantization;
        _houghSpaceSize = imageSize;
        
        _sourceSize = imageSize;
        _sourceLength = imageSize[0] * imageSize[1];
        
        _modelSize = modelSize;
        _modelLength = modelLength;
        
        self.length = 1;
    }
    
    return self;
}
- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _sourceSize = (simd::uint2){1,1};
        _sourceLength = _sourceSize[0] * _sourceSize[1];
        
        _houghSpaceQuantization = (simd::uint2){1,1};
        _houghSpaceSize         = (simd::uint2){1,1};
        
        _modelSize = (simd::uint2){1,1};
        _modelLength = 1;
        
        self.length = 1;
    }
    
    return self;
}

- (GHT::parameter *)parameterBuffer
{
    GHT::parameter *parameterBuffer = (GHT::parameter *)malloc(sizeof(GHT::parameter));

    GHT::parameter parameter;
    parameter.houghSpaceQuantization    = _houghSpaceQuantization;
    parameter.houghSpaceLength          = _houghSpaceLength;
    parameter.sourceSize                = _sourceSize;
    parameter.sourceLength              = _sourceLength;
    parameter.modelLength               = _modelLength;
    parameter.maxNumberOfEdges          = 1000;
    
    parameterBuffer[0] = parameter;
    
    return parameterBuffer;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    GHT::parameter *data = [self parameterBuffer];
    
    self.buffer = [device newBufferWithBytes:data
                                  length:self.length * sizeof(GHT::parameter)
                                 options:MTLResourceOptionCPUCacheModeDefault];
    self.buffer.label = @"ParameterBuffer";
    
    free(data);
    
    if(!self.buffer)
    {
        NSLog(@"Error(%@): Could not create parameter buffer", self.class);
        return NO;
    }
    
    return YES;
}

@end
