//
//  GHTCamSettingsViewController.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

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

- (void)awakeFromNib
{
    
//    switch (_videoResolution)
//    {
//        case k352x288:
//            _lowResulutionButton.backgroundColor = [UIColor darkGrayColor];
//            _mediumResolutionButton.backgroundColor = [UIColor clearColor];
//            break;
//        case k640x480:
//            _mediumResolutionButton.backgroundColor = [UIColor darkGrayColor];
//            _lowResulutionButton.backgroundColor = [UIColor clearColor];
//            break;
//        default:
//            break;
//    }
//    
//    switch (_videoCamera)
//    {
//        case kFront:
//            _frontCamButton.backgroundColor = [UIColor darkGrayColor];
//            _backCamButton.backgroundColor = [UIColor clearColor];
//            break;
//        case kBack:
//            _backCamButton.backgroundColor = [UIColor darkGrayColor];
//            _frontCamButton.backgroundColor = [UIColor clearColor];
//            break;
//        default:
//            break;
//    }
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
