//
//  HeadlessTestAppDelegate.h
//  BatteryHelper
//
//  Created by Chris Kau on 19/11/2009.
//  Copyright 2009 Chris Kau. All rights reserved.
//

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    BOOL isLowBatteryWarningAlertShowing;
    BOOL isSleepNotificationShowing;
    NSWindow *sleepWindow;
    NSTextField *messageText;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *sleepWindow;

- (void)showLowBatteryWarning;
- (void)emergencySleep;
- (IBAction)closeLowBatteryWarning:(id)sender;
- (BOOL)isLowBatteryWarningShowing;

@end
