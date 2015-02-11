//
//  GHTCamSettingsViewController.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
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


#import "GHTCamSettingsViewController.h"
#import "GHTRoundButtons.h"

@interface GHTCamSettingsViewController ()
@property (weak, nonatomic) IBOutlet GHTRoundButtons *frontCamButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *backCamButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *lowResulutionButton;
@property (weak, nonatomic) IBOutlet GHTRoundButtons *mediumResolutionButton;

@end

@implementation GHTCamSettingsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
    
    }
    
    return self;
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if (self.computeBuilder)
    {
        //Front/Back settings
        if (((GHTVideo *)self.computeBuilder.input).capturePosition == AVCaptureDevicePositionBack)
        {
            _backCamButton.backgroundColor = [UIColor darkGrayColor];
            _frontCamButton.backgroundColor = [UIColor clearColor];
        } else
        {
            _frontCamButton.backgroundColor = [UIColor darkGrayColor];
            _backCamButton.backgroundColor = [UIColor clearColor];
        }
        
        //Resolution settings
        if ([((GHTVideo *)self.computeBuilder.input).captureSessionPreset isEqualToString:AVCaptureSessionPreset352x288])
        {
            _lowResulutionButton.backgroundColor = [UIColor darkGrayColor];
            _mediumResolutionButton.backgroundColor = [UIColor clearColor];
        } else if ([((GHTVideo *)self.computeBuilder.input).captureSessionPreset isEqualToString:AVCaptureSessionPresetLow])
        {
            _mediumResolutionButton.backgroundColor = [UIColor darkGrayColor];
            _lowResulutionButton.backgroundColor = [UIColor clearColor];
        }
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)frontCamPressed:(id)sender
{
    if ([self.computeBuilder.input isKindOfClass:[GHTVideo class]])
    {
        ((GHTVideo *)self.computeBuilder.input).capturePosition = AVCaptureDevicePositionFront;
    }

    _frontCamButton.backgroundColor = [UIColor darkGrayColor];
    _backCamButton.backgroundColor = [UIColor clearColor];
}

- (IBAction)backCamPressed:(id)sender
{
    if ([self.computeBuilder.input isKindOfClass:[GHTVideo class]])
    {
        ((GHTVideo *)self.computeBuilder.input).capturePosition = AVCaptureDevicePositionBack;
    }

    _backCamButton.backgroundColor = [UIColor darkGrayColor];
    _frontCamButton.backgroundColor = [UIColor clearColor];
}

- (IBAction)preset352x288Pressed:(id)sender
{
    if ([self.computeBuilder.input isKindOfClass:[GHTVideo class]])
    {
        ((GHTVideo *)self.computeBuilder.input).captureSessionPreset = AVCaptureSessionPreset352x288;
        [self.computeBuilder addDefaultFilters];
    }
    _lowResulutionButton.backgroundColor = [UIColor darkGrayColor];
    _mediumResolutionButton.backgroundColor = [UIColor clearColor];
    
}
- (IBAction)preset192x144ResolutionPressed:(id)sender
{
    if ([self.computeBuilder.input isKindOfClass:[GHTVideo class]])
    {
        ((GHTVideo *)self.computeBuilder.input).captureSessionPreset = AVCaptureSessionPresetLow;
        [self.computeBuilder addDefaultFilters];
    }
    _mediumResolutionButton.backgroundColor = [UIColor darkGrayColor];
    _lowResulutionButton.backgroundColor = [UIColor clearColor];
}

@end
