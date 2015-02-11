//
//  GHTFilterSettingsScrollView.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GHTFilterSettingsScrollView <NSObject>

- (void)didSelectCameraInput;
- (void)didSelectImageInput;

@end

@interface GHTFilterSettingsScrollView : UIScrollView

- (void)start;
@end