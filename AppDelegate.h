//
//  HeadlessTestAppDelegate.h
//  BatteryHelper
//
//  Created by Chris Kau on 19/11/2009.
//  Copyright 2009 Chris Kau. All rights reserved.
//

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSWindow *sleepWindow;
    NSWindow *aboutWindow;
    
    NSTextField *messageText;
    NSStatusItem *statusItem;
    NSMenu *statusMenu;

    BOOL isLowBatteryWarningAlertShowing;
    BOOL isSleepNotificationShowing;
    
    BOOL paused;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *sleepWindow;
@property (assign) IBOutlet NSWindow *aboutWindow;

@property (assign) IBOutlet NSMenu *statusMenu;



- (void)showLowBatteryWarning;
- (void)emergencySleep;
- (IBAction)closeLowBatteryWarning:(id)sender;

- (BOOL)isLowBatteryWarningShowing;

// status menu items

- (IBAction) menuTogglePause:(id)sender;
- (IBAction) menuQuit:(id)sender;
- (IBAction) menuAbout:(id)sender;

@end
