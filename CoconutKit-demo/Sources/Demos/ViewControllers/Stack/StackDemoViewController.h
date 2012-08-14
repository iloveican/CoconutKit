//
//  StackDemoViewController.h
//  CoconutKit-demo
//
//  Created by Samuel Défago on 22.07.11.
//  Copyright 2011 Hortis. All rights reserved.
//

/**
 * Designated initializer: init
 */
@interface StackDemoViewController : HLSPlaceholderViewController <HLSStackControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
@private
    UIPickerView *m_transitionPickerView;
    UISwitch *m_inTabBarControllerSwitch;
    UISwitch *m_inNavigationControllerSwitch;
    UISwitch *m_animatedSwitch;
}

@property (nonatomic, retain) IBOutlet UIPickerView *transitionPickerView;
@property (nonatomic, retain) IBOutlet UISwitch *inTabBarControllerSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *inNavigationControllerSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *animatedSwitch;

- (IBAction)displayLifeCycleTest:(id)sender;
- (IBAction)displayContainmentTest:(id)sender;
- (IBAction)displayStretchable:(id)sender;
- (IBAction)displayFixedSize:(id)sender;
- (IBAction)displayPortraitOnly:(id)sender;
- (IBAction)displayLandscapeOnly:(id)sender;
- (IBAction)hideWithModal:(id)sender;
- (IBAction)displayTransparent:(id)sender;
- (IBAction)testInModal:(id)sender;
- (IBAction)pop:(id)sender;
- (IBAction)popToRoot:(id)sender;
- (IBAction)popThree:(id)sender;

- (IBAction)navigateForwardNonAnimated:(id)sender;
- (IBAction)navigateBackNonAnimated:(id)sender;

@end
