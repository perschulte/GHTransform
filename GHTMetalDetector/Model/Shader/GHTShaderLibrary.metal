//
//  GHTShaderLibrary.metal
//  GHTMetalDetector
//
//  Created by Per Schulte on 28.07.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#include <metal_stdlib>
#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>

using namespace metal;


#define PI_2    6.28318530717958647692
#define PI      3.14159265358979323846
#define THRESHOLD 0.4

//Grayscale constant
constant float3 kRec709Luma = float3(0.2126, 0.7152, 0.0722);

//Function prototypes
float atanTwo(float y, float x);
float gaussianBlur(float sample5x5[5][5]);
float vSobel(float sample3x3[3][3]);
float hSobel(float sample3x3[3][3]);

//Gaussian mask
//  2   4   5   4   2
//  4   9   12  9   4
//  5   12  15  12  5
//  4   9   12  9   4
//  2   4   5   4   2
static constant float gaussianMask[5][5] = {
    {2.0, 4.0, 5.0, 4.0, 2.0},
    {2.0, 4.0, 5.0, 4.0, 2.0},
    {2.0, 4.0, 5.0, 4.0, 2.0},
    {2.0, 4.0, 5.0, 4.0, 2.0},
    {2.0, 4.0, 5.0, 4.0, 2.0}
};


//vertical sobel
// 1 0 -1
// 2 0 -2
// 1 0 -1
static constant float verticalSobelMask[3][3] = {
    {1.0, 0.0, -1.0},
    {2.0, 0.0, -2.0},
    {1.0, 0.0, -1.0}
};

//horizontal sobel
//  1  2  1
//  0  0  0
// -1 -2 -1
static constant float horizontalSobelMask[3][3] = {
    {   1.0,    2.0,    1.0},
    {   0.0,    0.0,    0.0},
    {  -1.0,   -2.0,   -1.0}
};


struct VertexOutput
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

struct FragmentInput
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

#pragma mark - private
float atanTwo(float y, float x)
{
    if (y > 0.0)
    {
        return atan2(y,x);
    } else if (y != 0.0)
    {
        return atan2(y,x) + PI_2;
    } else if (x > 0.0)
    {
        return 0.0;
    } else if (x < 0.0)
    {
        return PI;
    }
    
    return 0.0;
}

// Applies the vertical sobel mask and returns the resulting value
float vSobel(float sample3x3[3][3])
{
    float result = 0.0;
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            result += sample3x3[i][j] * verticalSobelMask[i][j];
        }
    }
    
    return result;
}

// Applies the horizontal sobel mask and returns the resulting value
float hSobel(float sample3x3[3][3])
{
    float result = 0.0;
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            result += sample3x3[i][j] * horizontalSobelMask[i][j];
        }
    }
    
    return result;
}

// Applies the gaussian mask to a 5x5 grayscale array and returns its value
float gaussianBlur(float sample5x5[5][5])
{
    float result = 0.0;
    for (int i = 0; i < 5; i++)
    {
        for (int j = 0; j < 5; j++)
        {
            result += sample5x5[i][j] * gaussianMask[i][j];
        }
    }
    
    return result/115.0;
}

#pragma mark - Vertex

vertex VertexOutput texturedQuadVertex(constant float4         *pPosition   [[ buffer(0) ]],
                                       constant packed_float2  *pTexCoords  [[ buffer(1) ]],
                                       constant float4x4       *pMVP        [[ buffer(2) ]],
                                       uint                     vid         [[ vertex_id ]])
{
    VertexOutput outVertices;
    outVertices.m_Position = *pMVP * pPosition[vid];
    outVertices.m_TexCoord = pTexCoords[vid];
    
    return outVertices;
}

#pragma mark - Fragment

fragment half4 texturedQuadFragment(FragmentInput     inFrag    [[ stage_in ]],
                                    texture2d<float>  tex2D     [[ texture(0) ]],
                                    sampler           sampler2D [[ sampler(0) ]])
{
    float4 color = tex2D.sample(sampler2D, inFrag.m_TexCoord);
    
    return half4(color.r, color.g, color.b, color.a);
}

#pragma mark - Kernel

kernel void gaussianBlurKernel(texture2d<float, access::read>    inTexture   [[ texture(0) ]],
                               texture2d<float, access::write>   outTexture  [[ texture(1) ]],
                               uint2                             gid         [[ thread_position_in_grid ]])
{
    float4 outColor;
    
    //Apply gaussian blur
    float sample5x5[5][5];
    for (int i = 0; i < 5; i++)
    {
        for (int j = 0; j < 5; j++)
        {
            uint2 offset = uint2(i - 2, j - 2);
            uint2 coords = uint2(gid[0] - offset[0], gid[1] - offset[1]);
            sample5x5[i][j] = dot(inTexture.read(coords).rgb, kRec709Luma);
        }
    }
    outColor = gaussianBlur(sample5x5);
    outTexture.write(outColor, gid);
}

kernel void phiKernel(texture2d<float, access::read>    inTexture   [[texture(0)]],
                      texture2d<float, access::write>   outTexture  [[texture(1)]],
                      uint2                             gid         [[thread_position_in_grid]])
{
    float4  outColor;
    float   phi = 0.0;
    
    float sobelsample3x3[3][3];
    
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            uint2 offset = uint2(i - 1, j - 1);
            uint2 coords = uint2(gid[0] - offset[0], gid[1] - offset[1]);
            sobelsample3x3[i][j] = dot(inTexture.read(coords).rgb, kRec709Luma);
        }
    }
    
    float verticalEdge = vSobel(sobelsample3x3);
    
    float horizontalEdge = hSobel(sobelsample3x3);
    
    if (sqrt((horizontalEdge * horizontalEdge) +
             (verticalEdge * verticalEdge)) > THRESHOLD)
    {
        phi = atanTwo(verticalEdge, horizontalEdge);
        phi = (phi / PI_2);
    } else
    {
        phi = 0.0;
    }
    
    outColor = float4(phi, phi, phi, 1.0);
    
    outTexture.write(outColor, gid);
}
