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

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
	BatteryMonitor *self = info;
    SleeperStateMachine *machine = self.machine;

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

        // Check if we're running on AC power
        CFStringRef powerSourceState = CFDictionaryGetValue(_batteryStatus, CFSTR("Power Source State"));
        if (CFStringCompare(powerSourceState, CFSTR("AC Power"), 0) == kCFCompareEqualTo) {
            [_machine powerChangeToAC];
        } else {
            [_machine _batteryStatusChange:_batteryStatus];
        }

//        if (! isPluggedIn) {
//            // Check if we're already below the battery empty warning threshold
//
//            CFNumberRef sleepThreshold = CFNumberCreate(NULL, kCFNumberIntType, &sleepMinutesLeft);
//            CFNumberRef warningThreshold = CFNumberCreate(NULL, kCFNumberIntType, &warningMinutesLeft);
//            CFNumberRef timeToEmpty = CFDictionaryGetValue(_batteryStatus, CFSTR("Time to Empty"));
//            
//            if (CFNumberCompare(timeToEmpty, sleepThreshold, NULL) == kCFCompareLessThan) {
//                NSLog(@"Forcing sleep!");
//                [_machine batteryCritical];
//            }
//            else if (CFNumberCompare(timeToEmpty, warningThreshold, NULL) == kCFCompareLessThan) {
//                [_machine batteryLow];
//            }
//        }   
    }
    
    return self;
}

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
