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
    self = [super init];
    
    if (self)
    {
        _houghSpaceQuantization = quantization;
        _houghSpaceSize = imageSize;
        
        _sourceSize = imageSize;
        _sourceLength = imageSize[0] * imageSize[1];
        
        _modelSize = modelSize;
        _modelLength = modelLength;
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
    parameter.modelSize                 = _modelSize;
    parameter.modelLength               = _modelLength;
    
    parameterBuffer[0] = parameter;
    
    return parameterBuffer;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    GHT::parameter *data = [self parameterBuffer];
    
    _buffer = [device newBufferWithBytes:data
                                  length:sizeof(GHT::parameter)
                                 options:MTLResourceOptionCPUCacheModeDefault];
    _buffer.label = @"ParameterBuffer";
    
    free(data);
    
    if(!_buffer)
    {
        NSLog(@"Error(%@): Could not create parameter buffer", self.class);
        return NO;
    }
    
    return YES;
}

@end
