//
//  BatteryMonitor.m
//  BatteryHelper
//
//  Created by Chris Kau on 19/11/2009.
//  Copyright 2009 Chris Kau. All rights reserved.
//

#include <SystemConfiguration/SystemConfiguration.h>

#import "BatteryMonitor.h"
#import "AppDelegate.h"


static SCDynamicStoreRef _dynamicStore;
static CFDictionaryRef _batteryStatus;
static BOOL isPluggedIn;

static CFStringRef kLowBatteryWarningKey = CFSTR("State:/IOKit/LowBatteryWarning");
static CFStringRef kPowerAdapterKey = CFSTR("State:/IOKit/PowerAdapter");
static CFStringRef kInternalBatteryKey = CFSTR("State:/IOKit/PowerSources/InternalBattery-0");


/*
    BatteryHealth = Good;
    "Current Capacity" = 97;
    DesignCycleCount = 1000;
    "Hardware Serial Number" = 9G91903LR4M0A;
    "Is Charging" = 1;
    "Is Finishing Charge" = 0;
    "Is Present" = 1;
    "Max Capacity" = 100;
    Name = "InternalBattery-0";
    "Power Source State" = "AC Power";
    "Time to Empty" = 0;
    "Time to Full Charge" = 16;
    "Transport Type" = Internal;
 */

// http://www.cocoabuilder.com/archive/cocoa/196169-unable-to-get-event-for-shutdown-restart-using-qa1340.html

@implementation BatteryMonitor

@synthesize warningMinutesLeft;
@synthesize sleepMinutesLeft;
@synthesize machine = _machine;
@synthesize monitoringPaused;

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
	BatteryMonitor *self = info;
    SleeperStateMachine *machine = self.machine;

    if ([self monitoringPaused]) {
        NSLog(@"Monitoring paused...skipping callback");
        return;
    }
    
	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i = 0; i < count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
        CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
        
        if (!newValue || CFGetTypeID(newValue) == CFDictionaryGetTypeID()) {        
            if (CFStringCompare(key, kLowBatteryWarningKey, 0) == kCFCompareEqualTo) {
                [machine _lowBatteryWarning:newValue];
            }
            else if (CFStringCompare(key, kPowerAdapterKey, 0) == kCFCompareEqualTo) {
                [machine _powerAdapterStatusChange:newValue];
            }
            else if (CFStringCompare(key, kInternalBatteryKey, 0) == kCFCompareEqualTo) {
                [machine _batteryStatusChange:newValue];
            }
        }

        if (newValue != nil) {
            CFRelease(newValue);            
        }
	}
}

- (id)init
{
    self = [super init];
    
    if (self != nil) {
        _delegate = (AppDelegate *)[NSApp delegate];
                
        // default times
        sleepMinutesLeft = 8;
        warningMinutesLeft = 12;
        monitoringPaused = false;
        
        SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};
        
        _dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault,
                                        CFBundleGetIdentifier(CFBundleGetMainBundle()),
                                        scCallback,
                                        &context);
        if (!_dynamicStore) {
            NSLog(@"SCDynamicStoreCreate() failed: %s", SCErrorString(SCError()));
            [self release];
            return nil;
        }
        
        const CFStringRef keys[3] = {
            kLowBatteryWarningKey,
            kPowerAdapterKey,
            kInternalBatteryKey
        };

        CFArrayRef watchedKeys = CFArrayCreate(kCFAllocatorDefault,
                                               (const void **)keys,
                                               3,
                                               &kCFTypeArrayCallBacks);
        
        if (!SCDynamicStoreSetNotificationKeys(_dynamicStore, watchedKeys, NULL)) {
            CFRelease(watchedKeys);
            NSLog(@"SCDynamicStoreSetNotificationKeys() failed: %s", SCErrorString(SCError()));
            CFRelease(_dynamicStore);
            _dynamicStore = NULL;
            
            [self release];
            return nil;
        }

        CFRelease(watchedKeys);
        
        _runLoopSource = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, _dynamicStore, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopDefaultMode);
        CFRelease(_runLoopSource);
        
        _batteryStatus = SCDynamicStoreCopyValue(_dynamicStore, kInternalBatteryKey);
        


        _machine = [[SleeperStateMachine alloc] initWithState:(isPluggedIn ? STATE_AC : STATE_BATTERY_NORMAL) 
                                                     delegate:_delegate];


        [self poll];
        
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector:@selector(didWakeNotification:) 
                                                                   name: @"NSWorkspaceDidWakeNotification" object: nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector:@selector(willSleepNotification:) 
                                                                   name: @"NSWorkspaceWillSleepNotification" object: nil];
    }
    
    return self;
}

- (void) poll {
    // Check if we're running on AC power
    BOOL on_ac;
    
    // skip polling if we're not monitoring - mostly for debugging
    if ([_delegate monitoringPaused]) {
        return;
    }
    
    NSDictionary *batteryStatus = [self getBatteryStatus];
    NSString * powerSourceState = [batteryStatus valueForKey:@"Power Source State"];
    on_ac = [powerSourceState isEqualToString:@"AC Power"];

    if (on_ac) {
        [_machine powerChangeToAC];
    } else {
        [_machine _batteryStatusChange:(CFDictionaryRef)batteryStatus];
    }
    
    if (! on_ac) {
        // Check if we're already below the battery empty warning threshold

        NSInteger sleepThreshold = sleepMinutesLeft;
        NSInteger warningThreshold = warningMinutesLeft;
        NSInteger timeToEmpty = [[batteryStatus valueForKey:@"Time to Empty"] integerValue];
        
        if (timeToEmpty <= sleepThreshold) {
            [_machine batteryCritical];
        }
        else if (timeToEmpty < warningThreshold) {
            [_machine batteryLow];
        }
    }   
}

- (NSString *) powerSource {
    CFDictionaryRef batteryStatus = SCDynamicStoreCopyValue(_dynamicStore, kInternalBatteryKey);
    CFStringRef powerSourceState = CFDictionaryGetValue(batteryStatus, CFSTR("Power Source State"));
    return (NSString *)powerSourceState;
}

- (NSDictionary *) getBatteryStatus {
    CFDictionaryRef batteryStatus = SCDynamicStoreCopyValue(_dynamicStore, kInternalBatteryKey);
    return (NSDictionary *)batteryStatus;
}

- (BOOL) isCharging {
    NSString *powerSourceState = [[self getBatteryStatus] valueForKey:@"Power Source State"];
    return [powerSourceState isEqualToString:@"AC Power"];
}

- (BOOL) isDischarging {
    return ![self isCharging];
}

- (NSString *) batteryStatusString {
    NSDictionary *batteryStatus = [self getBatteryStatus];
    NSInteger pct;
    NSString *remain;
    NSInteger timeToEmpty = [[batteryStatus valueForKey:@"Time to Empty"] integerValue];
    if ([self isCharging]) {
        remain = @"Charging";
    }
    else if (timeToEmpty <= 0) {
        remain = @"Calculating…";
    } else {
        NSInteger hours = timeToEmpty / 60;
        NSInteger minutes = timeToEmpty - (hours * 60);
        remain = [NSString stringWithFormat:@"%d:%02d", hours, minutes];
    }

    NSInteger maxCapacity = [[batteryStatus valueForKey:@"Max Capacity"] integerValue];
    NSInteger currentCapacity = [[batteryStatus valueForKey:@"Current Capacity"] integerValue];

    pct = (currentCapacity * 100) / maxCapacity;
    return [NSString stringWithFormat:@"%d%%, %@", pct, remain];
}

#pragma sleep monitoring

- (void)didWakeNotification:(NSNotification *)notification {
    NSLog(@"didWakeNotification: received NSWorkspaceDidWakeNotification");
    [self poll];
    [_machine hostWake];
}

- (void)willSleepNotification:(NSNotification *)notification{
    NSLog(@"willSleepNotification: received NSWorkspaceWillSleepNotification");
    [_machine hostSleep];
}

#pragma mark cleanup

- (void)dealloc
{
    if (_runLoopSource != nil) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopDefaultMode);
        CFRunLoopSourceInvalidate(_runLoopSource);
    }

	if (_dynamicStore != nil)
		CFRelease(_dynamicStore);
    
    [_machine release];
    
    [super dealloc];
}


@end
