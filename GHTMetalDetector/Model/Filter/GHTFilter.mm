
//
//  GHTFilter.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 24.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTFilter.h"

@interface GHTFilter ()

@end

@implementation GHTFilter

- (instancetype)initWithShaderLibrary:(id <MTLLibrary>)shaderLibrary device:(id <MTLDevice>)device
{
    self = [super init];
    
    if (self)
    {
        _m_ShaderLibrary = shaderLibrary;
        _m_Device = device;
    }
    
    return self;
}

- (id <MTLFunction>)function
{
    if (self.m_ShaderLibrary)
    {
        id <MTLFunction> function = [self.m_ShaderLibrary newFunctionWithName:self.functionName];
        
        if(!function)
        {
            NSLog(@"Error(%@): Failed creating a new function!", self.class);
            
            return nil;
        }
        
        return function;
    } else
    {
        NSLog(@"Error(%@): No shader library!", self.class);
        return nil;
    }
}

- (id <MTLComputePipelineState>)kernelWithError:(NSError **)error
{
    if (self.m_Device)
    {
        id <MTLComputePipelineState> kernel = [self.m_Device newComputePipelineStateWithFunction:[self function]
                                                                                           error:error];

        if(!kernel)
        {
            NSLog(@"Error(%@): Failed creating a new kernel!", self.class);
            
            return nil;
        }
        
        return kernel;
    } else
    {
        NSLog(@"Error(%@): No device!", self.class);
        
        return nil;
    }
}

- (id <MTLTexture>)textureWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor
{
    if (textureDescriptor)
    {
        id <MTLTexture> texture = [self.m_Device newTextureWithDescriptor:textureDescriptor];
        
        if(!texture)
        {
            NSLog(@"Error(%@): Failed creating a new texture!", self.class);
            
            return nil;
        }
        
        return texture;
    } else
    {
        NSLog(@"Error(%@): No texture descriptor!", self.class);
        
        return nil;
    }
}


- (void)addKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
{
    NSError *error = nil;
    if (!self.m_Kernel)
    {
        self.m_Kernel = [self kernelWithError:&error];
    }
    
    if (error)
    {
        NSLog(@"%@", error.description);
    }
}
- (void)dealloc
{
    [self cleanUp];
}

- (void)cleanUp
{
    _m_Kernel = nil;
}
@end
