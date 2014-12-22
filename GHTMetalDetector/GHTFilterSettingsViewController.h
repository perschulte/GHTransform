//
//  GHTFilterSettingsViewController.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GHTFilterSettingsScrollView.h"
#import "GHTComputeBuilder.h"

@protocol GHTFilterSettingsDelegate <NSObject>

- (void)cancelFilterSettings;

@end

@protocol GHTContextViewControllerDelegate <NSObject>

- (void)didSelectCam;
- (void)didSelectGauss;
- (void)didSelectPhi;
- (void)didSelectHoughSpaceToBuffer;
- (void)didSelectHoughSpaceBufferToTexture;
- (void)didSelectQuad;

@end

@interface GHTFilterSettingsViewController : UIViewController 

@property (nonatomic, weak) id <GHTFilterSettingsDelegate> delegate;
@property (nonatomic, weak) id <GHTContextViewControllerDelegate> contextDelegate;
@property (nonatomic, weak) GHTComputeBuilder *computeBuilder;
@end
