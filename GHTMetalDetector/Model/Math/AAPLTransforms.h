//
//  IMPORTANT:  This Apple software is supplied to you by Apple
//  Inc. ("Apple") in consideration of your agreement to the following
//  terms, and your use, installation, modification or redistribution of
//  this Apple software constitutes acceptance of these terms.  If you do
//  not agree with these terms, please do not use, install, modify or
//  redistribute this Apple software.
//
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software.
//  Neither the name, trademarks, service marks or logos of Apple Inc. may
//  be used to endorse or promote products derived from the Apple Software
//  without specific prior written permission from Apple.  Except as
//  expressly stated in this notice, no other rights or licenses, express or
//  implied, are granted by Apple herein, including but not limited to any
//  patent rights that may be infringed by your derivative works or by other
//  works in which the Apple Software may be incorporated.
//
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.

/*
 
 Abstract:
 
  Utility methods for linear transformations of projective
  geometry of the left-handed coordinate system.
  
 */

#ifndef _METAL_MATH_TRANSFORMS_H_
#define _METAL_MATH_TRANSFORMS_H_

#import <simd/simd.h>

#ifdef __cplusplus

namespace AAPL
{
    float radians(const float& degrees);
    
    simd::float4x4 scale(const float& x,
                         const float& y,
                         const float& z);
    
    simd::float4x4 scale(const simd::float3& s);
    
    simd::float4x4 translate(const float& x,
                             const float& y,
                             const float& z);
    
    simd::float4x4 translate(const simd::float3& t);
    
    simd::float4x4 rotate(const float& angle,
                          const float& x,
                          const float& y,
                          const float& z);
    
    simd::float4x4 rotate(const float& angle,
                          const simd::float3& u);
    
    simd::float4x4 frustum(const float& fovH,
                           const float& fovV,
                           const float& near,
                           const float& far);
    
    simd::float4x4 frustum(const float& left,
                           const float& right,
                           const float& bottom,
                           const float& top,
                           const float& near,
                           const float& far);
    
    simd::float4x4 frustum_oc(const float& left,
                              const float& right,
                              const float& bottom,
                              const float& top,
                              const float& near,
                              const float& far);
    
    simd::float4x4 lookAt(const float * const pEye,
                          const float * const pCenter,
                          const float * const pUp);
    
    simd::float4x4 lookAt(const simd::float3& eye,
                          const simd::float3& center,
                          const simd::float3& up);
    
    simd::float4x4 perspective(const float& width,
                               const float& height,
                               const float& near,
                               const float& far);
    
    simd::float4x4 perspective_fov(const float& fovy,
                                   const float& aspect,
                                   const float& near,
                                   const float& far);
    
    simd::float4x4 perspective_fov(const float& fovy,
                                   const float& width,
                                   const float& height,
                                   const float& near,
                                   const float& far);
    
    simd::float4x4 ortho2d_oc(const float& left,
                              const float& right,
                              const float& bottom,
                              const float& top,
                              const float& near,
                              const float& far);
    
    simd::float4x4 ortho2d_oc(const simd::float3& origin,
                              const simd::float3& size);
    
    simd::float4x4 ortho2d(const float& left,
                           const float& right,
                           const float& bottom,
                           const float& top,
                           const float& near,
                           const float& far);
    
    simd::float4x4 ortho2d(const simd::float3& origin,
                           const simd::float3& size);
} // AAPL

#endif

#endif
