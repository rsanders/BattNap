//
//  HeadlessTestAppDelegate.h
//  BatteryHelper
//
//  Created by Chris Kau on 19/11/2009.
//  Copyright 2009 Chris Kau. All rights reserved.
//

@class BatteryMonitor;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSWindow *sleepWindow;
    NSWindow *aboutWindow;
    
    NSTextField *messageText;
    NSStatusItem *statusItem;
    NSMenu *statusMenu;
    
    NSString *powerSource;
    NSString *batteryStatus;
    
    BatteryMonitor *monitor;
    
    BOOL debugMode;

    BOOL isLowBatteryWarningAlertShowing;
    BOOL isSleepNotificationShowing;

    BOOL paused;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *sleepWindow;
@property (assign) IBOutlet NSWindow *aboutWindow;

@property (assign) IBOutlet NSMenu *statusMenu;

@property (retain) NSString *powerSource;
@property (retain) NSString *batteryStatus;

@property BOOL monitoringPaused;
@property BOOL debugMode;

- (void)showLowBatteryWarning;
- (void)showEmergencySleepWarning;
- (void) hideAllNotifications;
- (IBAction)closeLowBatteryWarning:(id)sender;
- (BOOL)isLowBatteryWarningShowing;

- (void)emergencySleep;


// window items
- (IBAction) requestDelay:(id)sender;


// status menu items

- (IBAction) menuAbout:(id)sender;

// debug menu items

- (IBAction) debugSendLow:(id)sender;
- (IBAction) debugSendCritical:(id)sender;
- (IBAction) debugAC:(id)sender;
- (IBAction) debugBattery:(id)sender;



@end
