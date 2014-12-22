//
//  GHTHoughSpaceFilter.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTFilter.h"
#import "GHTModel.h"
#import "GHTParameter.h"
#import "GHTHoughSpaceBuffer.h"


@interface GHTHoughSpaceFilter : GHTFilter

@property (nonatomic, strong) GHTModel              *modelBuffer;
@property (nonatomic, strong) GHTParameter          *parameterBuffer;
@property (nonatomic, strong) GHTHoughSpaceBuffer   *outHoughSpaceBuffer;
@property (nonatomic) id <MTLBuffer>    hsBuffer;
@property (nonatomic, strong) id <MTLTexture>       inTexture;

- (void)addHoughSpaceKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                                  inTexture:(id <MTLTexture>)inTexture
                               outputBuffer:(id <MTLBuffer>)houghSpaceBuffer;

@end
