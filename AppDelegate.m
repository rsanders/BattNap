//
//  HeadlessTestAppDelegate.m
//  BatteryHelper
//
//  Created by Chris Kau on 19/11/2009.
//  Copyright 2009 Chris Kau. All rights reserved.
//

#import "AppDelegate.h"
#import "BatteryMonitor.h"


@implementation AppDelegate

@synthesize window;
@synthesize sleepWindow;
@synthesize statusMenu;
@synthesize aboutWindow;

- (void)activateStatusMenu
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];
    
    [statusItem setTitle: NSLocalizedString(@"Nap",@"")];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    BatteryMonitor *monitor = [[BatteryMonitor alloc] init];
    [self activateStatusMenu];
}

- (void)showLowBatteryWarning {
    if (paused) return;

    if (![self isLowBatteryWarningShowing]) {
        [window setLevel:NSStatusWindowLevel];
        [window center];
        isLowBatteryWarningAlertShowing = YES;
        [window makeKeyAndOrderFront:nil];
    }
}

- (IBAction)closeLowBatteryWarning:(id)sender
{
    isLowBatteryWarningAlertShowing = NO;
    [window orderOut:nil];
}


- (BOOL)isLowBatteryWarningShowing
{
    return isLowBatteryWarningAlertShowing;
}

- (void) emergencySleep {
    if (paused) return;

    [sleepWindow setLevel:NSStatusWindowLevel];
    [sleepWindow center];
    isSleepNotificationShowing = YES;
    [sleepWindow makeKeyAndOrderFront:nil];
    
    system("/usr/bin/pmset sleepnow");    
}

#pragma mark Status Menu

- (IBAction) menuTogglePause:(id)sender {
    
}

- (IBAction) menuQuit:(id)sender {
    exit(0);
}

- (IBAction) menuAbout:(id)sender {
    [aboutWindow setLevel:NSStatusWindowLevel];
    [aboutWindow center];
    [aboutWindow makeKeyAndOrderFront:nil];
}

@end
