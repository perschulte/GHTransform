//
//  GHTFilterSettingsViewController.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTFilterSettingsViewController.h"
#import "GHTFilterSettingsScrollView.h"
#import "GHTRoundButtons.h"
#import "GHTContextViewController.h"

@interface GHTFilterSettingsViewController ()
@property (weak, nonatomic) IBOutlet UIVisualEffectView *blurView;
@property (weak, nonatomic) IBOutlet GHTFilterSettingsScrollView *filterSettingsScrollView;
@property (weak, nonatomic) IBOutlet UIView *contextViewContainer;

@property (weak, nonatomic) IBOutlet GHTRoundButtons *camButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *gaussButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *phiButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *hsToBufferButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *hsBufferToTextureButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *quadButton;

@end

@implementation GHTFilterSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"default"])
    {
        self.contextDelegate = (GHTContextViewController *)segue.destinationViewController;
        ((GHTContextViewController *)self.contextDelegate).computeBuilder = _computeBuilder;
    }
}

- (void)setComputeBuilder:(GHTComputeBuilder *)computeBuilder
{
    _computeBuilder = computeBuilder;
    if (_contextDelegate)
    {
        ((GHTContextViewController *)self.contextDelegate).computeBuilder = _computeBuilder;
    }
}

- (IBAction)cancelFilterSettings:(id)sender
{
    [_computeBuilder finalize];
    [self.delegate cancelFilterSettings];
}

- (IBAction)camButtonPressed:(id)sender
{
    [self.contextDelegate didSelectCam];
}

- (IBAction)gaussButtonPressed:(id)sender
{
    [self.contextDelegate didSelectGauss];
}

- (IBAction)phiButtonPressed:(id)sender
{
    [self.contextDelegate didSelectPhi];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
