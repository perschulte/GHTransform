//
//  GHTSharedTypes.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 03.08.14.
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
        
        unsigned int    maxNumberOfEdges;                 // 8x8 pixel source image
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
