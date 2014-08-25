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
    struct Model
    {
        int         referenceId;
        float       x;
        float       y;
        float       phi;
        float       weight;
        int         length; //Number of model points
        simd::uint2 size;
    };
    
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
