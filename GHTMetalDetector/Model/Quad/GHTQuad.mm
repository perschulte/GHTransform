//
//  GHTQuad.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 28.07.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GHTQuad.h"
#import <simd/simd.h>

static const uint32_t kCountQuadTextureCoordinates  = 6; // Number of Vertices
static const uint32_t kSizeQuadTexCoordinates       = kCountQuadTextureCoordinates * sizeof(simd::float2);

static const uint32_t kCountQuadVertices            = kCountQuadTextureCoordinates;
static const uint32_t kSizeQuadVertices             = kCountQuadVertices * sizeof(simd::float4);

static const simd::float4 kQuadVertices[kCountQuadVertices] =
{
    //First triangle
    { -1.0f,  -1.0f, 0.0f, 1.0f },
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    
    //Second triangle
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    {  1.0f,   1.0f, 0.0f, 1.0f }
};

static const simd::float2 kQuadTexturCoordinates[kCountQuadTextureCoordinates] =
{
    //First triangle
    { 0.0f, 0.0f },
    { 1.0f, 0.0f },
    { 0.0f, 1.0f },
    
    //Second triangle
    { 1.0f, 0.0f },
    { 0.0f, 1.0f },
    { 1.0f, 1.0f }
};

@implementation GHTQuad
{
    // Textured Quad
    id <MTLBuffer> m_VertexBuffer;
    id <MTLBuffer> m_TextureCoordinateBuffer;
    
    //Scale
    simd::float2 m_Scale;
    
}

#pragma mark - Init & clean-up
- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    
    if (self)
    {
        if (!device)
        {
            NSLog(@"Error(%@): Invalid device", self.class);
            return nil;
        }
        
        //New vertex buffer
        m_VertexBuffer = [device newBufferWithBytes:kQuadVertices
                                             length:kSizeQuadVertices
                                            options:MTLResourceOptionCPUCacheModeDefault];
        
        if(!m_VertexBuffer)
        {
            NSLog(@"Error(%@): Failed creating a vertex buffer for a quad!", self.class);
            
            return nil;
        }
        
        //New texture coordinates buffer
        m_TextureCoordinateBuffer = [device newBufferWithBytes:kQuadTexturCoordinates
                                                        length:kSizeQuadTexCoordinates
                                                       options:MTLResourceOptionCPUCacheModeDefault];

        if(!m_TextureCoordinateBuffer)
        {
            NSLog(@"Error(%@): Failed creating a 2d texture coordinate buffer!", self.class);
            
            m_VertexBuffer = nil;
            
            return nil;
        }
        
        _vertexIndex   = 0;
        _textureCoordinateIndex = 1;
        
        _size   = CGSizeMake(0.0, 0.0);
        _bounds = CGRectMake(0.0, 0.0, 0.0, 0.0);
        
        _aspect = 1.0f;
        
        m_Scale = 1.0f;
    }
    
    return self;
}

- (void)_cleanup
{
    m_TextureCoordinateBuffer   = nil;
    m_VertexBuffer              = nil;
}

- (void)dealloc
{
    [self _cleanup];
}

#pragma mark - public
/// Sets bounds and updates aspect ratio
- (void)setBounds:(CGRect)bounds
{
    _bounds = bounds;
    _aspect = fabsf(_bounds.size.width / _bounds.size.height);
}

/// Updates the vertices if the aspect ratio has changed.
- (BOOL)update
{
    BOOL newScale = NO;
    
    simd::float2 scale = 0.0f;
    
    float aspect = 1.0f/_aspect;
    
    scale.x = aspect * _size.width / _bounds.size.width;
    scale.y = _size.height / _bounds.size.height;
    
    // Did the scaling factor change
    newScale = (scale.x != m_Scale.x) || (scale.y != m_Scale.y);
    
    // Set the (x,y) bounds of the quad
    if(newScale)
    {
        // Update the scaling factor
        m_Scale = scale;
        
        // Update the vertex buffer with the quad bounds
        simd::float4 *pVertices = (simd::float4 *)[m_VertexBuffer contents];
        
        if(pVertices != NULL)
        {
            // First triangle
            pVertices[0].x = -m_Scale.x;
            pVertices[0].y = -m_Scale.y;
            
            pVertices[1].x =  m_Scale.x;
            pVertices[1].y = -m_Scale.y;
            
            pVertices[2].x = -m_Scale.x;
            pVertices[2].y =  m_Scale.y;
            
            // Second triangle
            pVertices[3].x =  m_Scale.x;
            pVertices[3].y = -m_Scale.y;
            
            pVertices[4].x = -m_Scale.x;
            pVertices[4].y =  m_Scale.y;
            
            pVertices[5].x =  m_Scale.x;
            pVertices[5].y =  m_Scale.y;
        }
    }

    return newScale;
}

- (void)encode:(id <MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder setVertexBuffer:m_VertexBuffer
                            offset:0
                           atIndex:_vertexIndex ];
    
    [renderEncoder setVertexBuffer:m_TextureCoordinateBuffer
                            offset:0
                           atIndex:_textureCoordinateIndex ];
}
@end
