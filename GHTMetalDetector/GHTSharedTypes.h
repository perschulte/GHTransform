//
//  GHTSharedTypes.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 03.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#ifndef GHTMetalDetector_GHTSharedTypes_h
#define GHTMetalDetector_GHTSharedTypes_h

#import <simd/simd.h>

#ifdef __cplusplus


namespace GHT
{
    struct model
    {
        int         referenceId;
        float       x;
        float       y;
        float       phi;
        float       weight;
    };
    
    struct houghSpace
    {
        float       accumulatedVotes;
    };
    
    struct parameter
    {                                               // Example values:
        simd::uint2     houghSpaceSize;             // 4x4 cells
        simd::uint2     houghSpaceQuantization;     // 2x2 points per cell
        unsigned int    houghSpaceLength;           // 16 cells
        
        simd::uint2     sourceSize;                 // 8x8 pixel source image
        unsigned int    sourceLength;               // 36 pixels
        
        simd::uint2     modelSize;                 // 8x8 pixel source image
        unsigned int    modelLength;
    };
    
    
//deprecated
    typedef struct
    {
        float       accumulatedVotes;
        int         numVotes;
        simd::uint2 size;   //Hough space size
        simd::uint2 quantization;   //Hough space size
    } HoughSpaceCell;
}

#endif // cplusplus

#endif
