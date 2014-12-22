//
//  GHTImageInput.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTInput.h"

@interface GHTImageInput : GHTInput

@property (nonatomic, strong) UIImage *inputImage;

- (instancetype)initWithImage:(UIImage *)image;

@end
