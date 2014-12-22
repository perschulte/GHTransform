//
//  GHTContextViewController.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTContextViewController.h"

#import "GHTCamSettingsViewController.h"
#import "GHTGaussSettingsViewController.h"


#define SegueIdentifierCam @"embedCam"
#define SegueIdentifierGauss @"embedGauss"
#define SegueIdentifierPhi @"embedPhi"

@interface GHTContextViewController ()

@property (strong, nonatomic) NSString *currentSegueIdentifier;

@end

@implementation GHTContextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentSegueIdentifier = SegueIdentifierCam;
    [self performSegueWithIdentifier:self.currentSegueIdentifier sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SegueIdentifierCam])
    {
        if (self.childViewControllers.count > 0)
        {
            [self swapFromViewController:[self.childViewControllers objectAtIndex:0] toViewController:segue.destinationViewController];
        }
        else
        {
            [self addChildViewController:segue.destinationViewController];
            ((UIViewController *)segue.destinationViewController).view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            [self.view addSubview:((UIViewController *)segue.destinationViewController).view];
            [segue.destinationViewController didMoveToParentViewController:self];
        }
    }
    else
    {
        [self swapFromViewController:[self.childViewControllers objectAtIndex:0] toViewController:segue.destinationViewController];
    }
}

- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController
{
    toViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    if ([toViewController isKindOfClass:[GHTSettingsViewController class]])
    {
        ((GHTSettingsViewController *)toViewController).computeBuilder = _computeBuilder;
    }
    
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    [self transitionFromViewController:fromViewController toViewController:toViewController duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:^(BOOL finished) {
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
    }];
}

#pragma mark - Button handling

- (void)didSelectCam
{
    if (![self.currentSegueIdentifier isEqualToString:SegueIdentifierCam])
    {
        self.currentSegueIdentifier = SegueIdentifierCam;
        [self performSegueWithIdentifier:SegueIdentifierCam sender:nil];
    }
}

- (void)didSelectGauss
{
    if (![self.currentSegueIdentifier isEqualToString:SegueIdentifierGauss])
    {
        self.currentSegueIdentifier = SegueIdentifierGauss;
        [self performSegueWithIdentifier:SegueIdentifierGauss sender:nil];
    }
}

- (void)didSelectPhi
{
    if (![self.currentSegueIdentifier isEqualToString:SegueIdentifierPhi])
    {
        self.currentSegueIdentifier = SegueIdentifierPhi;
        [self performSegueWithIdentifier:SegueIdentifierPhi sender:nil];
    }
}

- (void)didSelectHoughSpaceToBuffer
{
    
}

- (void)didSelectHoughSpaceBufferToTexture
{
    
}

- (void)didSelectQuad
{
    
}

#pragma mark - Getter/Setter
- (void)setComputeBuilder:(GHTComputeBuilder *)computeBuilder
{
    _computeBuilder = computeBuilder;
    
    for (UIViewController *childViewController in self.childViewControllers)
    {
        if ([childViewController isKindOfClass:[GHTSettingsViewController class]])
        {
            ((GHTSettingsViewController *)childViewController).computeBuilder = self.computeBuilder;
        }
    }
}

@end
