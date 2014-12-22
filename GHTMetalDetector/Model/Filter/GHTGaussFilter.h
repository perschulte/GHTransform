//
//  GHTGaussFilter.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 10.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTFilter.h"

@interface GHTGaussFilter : GHTFilter
@property (nonatomic, strong) id <MTLTexture> inTexture;
@property (nonatomic, strong) id <MTLTexture> outTexture;
@end
