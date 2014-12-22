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

#include "GHTSharedTypes.h"

using namespace metal;

#define PI_2    6.28318530717958647692
#define PI      3.14159265358979323846
#define THRESHOLD 0.5

//Grayscale constant
constant float3 kRec709Luma = float3(0.2126, 0.7152, 0.0722);

//Function prototypes
float atanTwo(float y, float x);
float gaussian5x5Blur(float sample5x5[5][5]);
float gaussian3x3Blur(float sample3x3[3][3]);
float vSobel(float sample3x3[3][3]);
float hSobel(float sample3x3[3][3]);
void line(int x1,int y1,int x2,int y2, texture2d<float, access::write> outTexture);
uint2 cellIndex(uint2 size, uint2 quantization, uint2 coords);

//Gaussian mask
//  2   4   5   4   2
//  4   9   12  9   4
//  5   12  15  12  5
//  4   9   12  9   4
//  2   4   5   4   2
static constant float gaussian5x5Mask[5][5] = {
    {2.0, 4.0, 5.0, 4.0, 2.0},
    {4.0, 9.0, 12.0, 9.0, 4.0},
    {5.0, 12.0, 15.0, 12.0, 5.0},
    {4.0, 9.0, 12.0, 9.0, 4.0},
    {2.0, 4.0, 5.0, 4.0, 2.0}
};

//Gaussian mask
//  2   4   5   4   2
//  4   9   12  9   4
//  5   12  15  12  5
//  4   9   12  9   4
//  2   4   5   4   2
static constant float gaussian3x3Mask[3][3] = {
    {1.0, 2.0, 1.0},
    {2.0, 4.0, 2.0},
    {1.0, 2.0, 1.0}
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
float gaussian5x5Blur(float sample5x5[5][5])
{
    float result = 0.0;
    for (int i = 0; i < 5; i++)
    {
        for (int j = 0; j < 5; j++)
        {
            result += sample5x5[i][j] * gaussian5x5Mask[i][j];
        }
    }
    
    return result/273;//115.0;
}

float gaussian3x3Blur(float sample3x3[3][3])
{
    float result = 0.0;
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            result += sample3x3[i][j] * gaussian5x5Mask[i][j];
        }
    }
    
    return result/16.0;
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
kernel void sourceKernel(texture2d<float, access::read>    inTexture   [[ texture(0) ]],
                         texture2d<float, access::write>   outTexture  [[ texture(1) ]],
                         uint2                             gid         [[ thread_position_in_grid ]])
{
    outTexture.write(inTexture.read(gid), gid);
}

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
    outColor = gaussian5x5Blur(sample5x5);
    outTexture.write(outColor, gid);
}

kernel void gaussian3x3BlurKernel(texture2d<float, access::read>    inTexture   [[ texture(0) ]],
                                  texture2d<float, access::write>   outTexture  [[ texture(1) ]],
                                  uint2                             gid         [[ thread_position_in_grid ]])
{
    float4 outColor;
    
    //Apply gaussian blur
    float sample3x3[3][3];
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            uint2 offset = uint2(i - 1, j - 1);
            uint2 coords = uint2(gid[0] - offset[0], gid[1] - offset[1]);
            sample3x3[i][j] = dot(inTexture.read(coords).rgb, kRec709Luma);
        }
    }
    outColor = gaussian3x3Blur(sample3x3);
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
    
    outColor = float4(phi, phi, phi, phi);
    outTexture.write(outColor, gid);
    
}

kernel void votingKernel(texture2d<float, access::read>     inTexture       [[texture(0)]],
                         texture2d<float, access::write>    outTexture      [[texture(1)]],
                         device GHT::model                 *modelBuffer     [[buffer(0)]],
                         device GHT::parameter             *parameterBuffer [[buffer(1)]],
                         uint2                              gid             [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    if(inColor[3] > 0.00)
    {
        for(uint i = 0; i < parameterBuffer[0].modelLength; i++)
        {
            if(inColor[0] * PI_2 > modelBuffer[i].phi - 0.08 && inColor[0] * PI_2 < modelBuffer[i].phi + 0.08)
            {
                if (gid[0] - modelBuffer[i].x >= 0 && gid[0] - modelBuffer[i].x < 32 && gid[1] - modelBuffer[i].y >= 0 && gid[1] - modelBuffer[i].y < 32)
                {
                    outTexture.write({2.0/255.0, 138.0/255.0, 158.0/255.0, 1.0}, gid);
                    outTexture.write({242.0/255.0, 193/255.0, 46.0/255.0, 1.0}, uint2(gid[0] - modelBuffer[i].x, gid[1] - modelBuffer[i].y));
                    //outTexture.write({0.0, 1.0, 0.0, 1.0}, uint2(gid[0] + modelBuffer[i].x, gid[1] + modelBuffer[i].y));
                }
            }
        }
    } else
    {
        //outTexture.write(defaultColor, gid);
    }
}

/* Shows the model points
 *
 */

kernel void modelKernel(texture2d<float, access::write>         outTexture              [[texture(0)]],
                        device GHT::model                       *modelBuffer            [[buffer(0)]],
                        device GHT::parameter                   *parameterBuffer        [[buffer(1)]],
                        uint2                                   gid                     [[thread_position_in_grid]])
{
    uint2 center = {(uint)(parameterBuffer[0].sourceSize[0] / 2.0), (uint)(parameterBuffer[0].sourceSize[1] / 2.0)};
    
    for (uint i = 0; i < parameterBuffer[0].modelLength; i++)
    {
        if (center[0] + (int)modelBuffer[i].x  == gid[0] && center[1] + (int)modelBuffer[i].y == gid[1])
        {
            outTexture.write({modelBuffer[i].weight, 67.0/255.0, 53.0/255.0, 1.0}, gid);
        }
    }
}

kernel void houghKernel(texture2d<float, access::read>           inTexture               [[texture(0)]],
                        device GHT::houghSpace                   *houghSpaceBuffer       [[buffer(0)]],
                        device GHT::model                        *modelBuffer            [[buffer(1)]],
                        device GHT::parameter                    *parameterBuffer        [[buffer(2)]],
                        uint2                                    gid                     [[thread_position_in_grid]])
{
    float4  inColor             = inTexture.read(gid);
    float   inPhi               = inColor[0] * PI_2;
    uint    numberOfModelPoints = parameterBuffer[0].modelLength;
    
    //is this pixel relevant (alpha channel > 0)
    if(inColor[3] > 0.0)
    {
        //compare this pixel with all model entries
        for(uint i = 0; i < numberOfModelPoints; i++)
        {
#define ANGLE_THRESHOLD 0.15
            
            //is the models phi equal to or close to this phi angle
            if(inPhi > modelBuffer[i].phi - ANGLE_THRESHOLD && inPhi < modelBuffer[i].phi + ANGLE_THRESHOLD)
            {
                // are the new points within the resource's borders
                if (gid[0] + modelBuffer[i].x >= 0 && gid[0] + modelBuffer[i].x < parameterBuffer[0].sourceSize[0] && gid[1] + modelBuffer[i].y >= 0 && gid[1] + modelBuffer[i].y < parameterBuffer[0].sourceSize[1])
                {
                    //vote
                    uint2 houghSpaceCoords;
                    uint pos;

                    houghSpaceCoords = uint2((gid[0] + modelBuffer[i].x)/parameterBuffer[0].houghSpaceQuantization[0],
                                             (gid[1] + modelBuffer[i].y)/parameterBuffer[0].houghSpaceQuantization[1]);

                    pos = houghSpaceCoords[1] * parameterBuffer[0].sourceSize[0]/parameterBuffer[0].houghSpaceQuantization[0] + houghSpaceCoords[0];
                    houghSpaceBuffer[pos].accumulatedVotes += modelBuffer[i].weight;
                }
            }
        }
    }
}

kernel void houghToTextureKernel(texture2d<float, access::write>    outTexture          [[texture(0)]],
                                 device GHT::houghSpace             *houghSpaceBuffer   [[buffer(0)]],
                                 device GHT::parameter              *parameterBuffer    [[buffer(1)]],
                                 uint2                              gid                 [[thread_position_in_grid]])
{
    uint gidToHoughSpace = gid[1] / parameterBuffer[0].houghSpaceQuantization[1] * parameterBuffer[0].sourceSize[0]/parameterBuffer[0].houghSpaceQuantization[0] + gid[0] / parameterBuffer[0].houghSpaceQuantization[0];
    if (houghSpaceBuffer[gidToHoughSpace].accumulatedVotes > 0.90)
    {
        outTexture.write({1.0-houghSpaceBuffer[gidToHoughSpace].accumulatedVotes, 1.0-houghSpaceBuffer[gidToHoughSpace].accumulatedVotes, 200.0/255.0, 1.0}, gid);
    }
}

//deprecated//
kernel void houghSpaceKernel(texture2d<float, access::read>     inTexture           [[texture(0)]],
                             device GHT::parameter             *parameterBuffer     [[buffer(0)]],
                             device GHT::houghSpace            *houghSpaceBuffer    [[buffer(1)]],
                             device GHT::model                 *modelBuffer         [[buffer(2)]],
                             uint2                              gid                 [[thread_position_in_grid]])
{
    float4  inColor             = inTexture.read(gid);
    uint2   quantization        = parameterBuffer[0].houghSpaceQuantization;
    uint    numberOfModelPoints = parameterBuffer[0].modelLength;
    uint2   resourceSize        = parameterBuffer[0].houghSpaceSize;
    uint2   houghSpaceCoords;
    
    uint pos;

    houghSpaceCoords = uint2(gid[0]/quantization[0],
                             gid[1]/quantization[1]);
    pos = houghSpaceCoords[1] * parameterBuffer[0].houghSpaceSize[0] + houghSpaceCoords[0];
//    for (int i = 0; i < (parameterBuffer[0].houghSpaceSize[0]*parameterBuffer[0].houghSpaceSize[1]); i++)
//    {
//        houghSpaceBuffer[i].accumulatedVotes = i;
//    }
    
//    houghSpaceBuffer[pos].accumulatedVotes += 1.0;
    
    //is this pixel relevant (alpha channel > 0)
    if(inColor[3] > 0.0)
    {
        //compare with each model point
        houghSpaceBuffer[10].accumulatedVotes++;
//        for(int i = 0; i < numberOfModelPoints; i++)
//        {
//
//            GHT::model model = modelBuffer[i];
//            //is the models phi equal to or close to this phi angle
//            if(inColor[0] * PI_2 > model.phi - 0.1 && inColor[0] * PI_2 < model.phi + 0.1)
//            {
//                // are the new points within the resource's borders
//                if (gid[0] - model.x >= 0 && gid[0] - model.x < resourceSize[0] && gid[1] - model.y >= 0 && gid[1] - model.y < resourceSize[1])
//                {
//                    //vote
//                    uint2 houghSpaceCoords; //= uint2((gid[0] - modelBuffer[i].x)/houghSpaceBuffer[0].quantization[0],
////                                                   (gid[1] - modelBuffer[i].y)/houghSpaceBuffer[0].quantization[1]);
//                    uint pos; // = houghSpaceCoords[1] * houghSpaceBuffer[0].size[1] + houghSpaceCoords[0];
////                    houghSpaceBuffer[pos].numVotes++;
////                    houghSpaceBuffer[pos].accumulatedVotes += modelBuffer[i].weight;
//                   
//                    houghSpaceCoords = uint2((gid[0] + modelBuffer[i].x)/quantization[0],
//                                                   (gid[1] + modelBuffer[i].y)/quantization[1]);
//                    pos = houghSpaceCoords[1] * parameterBuffer[0].houghSpaceSize[0] + houghSpaceCoords[0];
//                    houghSpaceBuffer[pos].accumulatedVotes += modelBuffer[i].weight;
//                    
//                }
//            }
//        }
    }
}



kernel void normalizeKernel(constant GHT::HoughSpaceCell   *houghSpaceBuffer            [[buffer(0)]],
                            constant float                 *maxAccumulatedVotesBuffer   [[buffer(1)]],
                            texture2d<float, access::write> outTexture                  [[texture(0)]],
                            uint2                           gid                         [[thread_position_in_grid]])
{
    /*  Each point on the texture will be processed. The uint2 will give us the current coordinates.
     *  We need to calculate the equivalent position in the houghSpace.
     *  gid = (1,2) -> houghSpaceCoords = (0,1) with quantization = (2,2)
     */
    uint2 quantization = houghSpaceBuffer[0].quantization;
    uint2 houghSpaceCoords = uint2(gid[0]/quantization[0], gid[1]/quantization[1]);
    uint pos = houghSpaceCoords[1] * houghSpaceBuffer[0].size[0] + houghSpaceCoords[0];
    
    float4 outColor = float4(houghSpaceBuffer[pos].accumulatedVotes / maxAccumulatedVotesBuffer[0], houghSpaceBuffer[pos].accumulatedVotes / maxAccumulatedVotesBuffer[0], houghSpaceBuffer[pos].accumulatedVotes / maxAccumulatedVotesBuffer[0], 1.0);
    
    outTexture.write(outColor, gid);
}