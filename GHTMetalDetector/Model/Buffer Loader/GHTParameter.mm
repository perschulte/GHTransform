//
//  GHTParameter.mm
//  GHTMetalDetector
//
//  Created by Per Schulte on 21.10.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

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
    parameter.modelSize                 = {0,0};
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
