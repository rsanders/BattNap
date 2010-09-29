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
@synthesize powerSource;
@synthesize batteryStatus;
@synthesize debugMode;

- (void)activateStatusMenu
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];
    
    self.powerSource = @"Unknown";
    self.batteryStatus = @"Unknown";
    
    [statusItem setTitle: NSLocalizedString(@"Nap",@"")];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    monitor = [[BatteryMonitor alloc] init];
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

- (void) fakeSleep {
    NSLog(@"faking sleep-and-wake cycle");
    [[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:@"NSWorkspaceWillSleepNotification" object:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:@"NSWorkspaceDidWakeNotification" object:self];
}

- (void) showEmergencySleepWarning {
    if (paused) return;
    
    [sleepWindow setLevel:NSStatusWindowLevel];
    [sleepWindow center];
    isSleepNotificationShowing = YES;
    [sleepWindow makeKeyAndOrderFront:nil];
}

- (void) emergencySleep {
    if (paused) return;
    
    if (debugMode) {
        [self fakeSleep];
    }
    else {
        NSLog(@"Issuing pmset sleepnow");
        system("/usr/bin/pmset sleepnow");
    }
        
}

#pragma mark window functions

- (IBAction) requestDelay:(id)sender {
    [monitor.machine requestDelay];
    [sleepWindow orderOut:nil];
}

- (void) hideAllNotifications {
    [sleepWindow orderOut:nil];
    [aboutWindow orderOut:nil];
}

#pragma mark Status Menu

- (IBAction) menuAbout:(id)sender {
    [aboutWindow setLevel:NSStatusWindowLevel];
    [aboutWindow center];
    [aboutWindow makeKeyAndOrderFront:nil];
}

- (void)menuWillOpen:(NSMenu *)menu {
    NSLog(@"Opening status menu");
    self.powerSource = [monitor powerSource];
    self.batteryStatus = [monitor batteryStatusString];
}

#pragma mark Debug Menu

- (IBAction) debugSendLow:(id)sender
{
    [monitor.machine batteryLow];
}

- (IBAction) debugSendCritical:(id)sender
{
    [monitor.machine batteryCritical];    
}

- (IBAction) debugAC:(id)sender
{
    [monitor.machine powerChangeToAC];
}

- (IBAction) debugBattery:(id)sender
{
    [monitor.machine powerChangeToBattery];
}

- (BOOL) monitoringPaused
{
    return [monitor monitoringPaused];
}

- (void) setMonitoringPaused:(BOOL)state
{
    [monitor setMonitoringPaused:state];
}

@end
