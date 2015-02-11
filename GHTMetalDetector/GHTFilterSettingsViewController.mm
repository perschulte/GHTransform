//
//  GHTFilterSettingsViewController.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.12.14.
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
@property (weak, nonatomic) IBOutlet GHTRoundButtons *closeButton;

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
    [_computeBuilder finalizeBuffer];
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

- (IBAction)infoButtonPressed:(id)sender {
     [self.contextDelegate didSelectInfo];
}

@end
