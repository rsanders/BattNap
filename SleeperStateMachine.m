//
//  SleeperStateMachine.m
//  BattNap
//
//  Created by Robert Sanders on 9/28/10.
//  Copyright (c) 2010 Curious Squid. All rights reserved.
//

#import "SleeperStateMachine.h"
#import "AppDelegate.h"

@implementation SleeperStateMachine
@synthesize handler;
@synthesize state;
@synthesize delegate;
@synthesize warningMinutesLeft;
@synthesize sleepMinutesLeft;

@interface SleeperStateMachine (Private)
- (sstate_t) newState:(sstate_t)new_state;
@end

- (SleeperStateMachine*) initWithState:(sstate_t)_state delegate:(AppDelegate*)_delegate
{
    self = [super init];
    self.state = STATE_NO_CHANGE;
    [self newState:_state];
    self.delegate = _delegate;
    
    self.warningMinutesLeft = 15;
    self.sleepMinutesLeft = 8;

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector:@selector(didWakeNotification:) 
                                                               name: @"NSWorkspaceDidWakeNotification" object: nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector:@selector(willSleepNotification:) 
                                                               name: @"NSWorkspaceWillSleepNotification" object: nil];

    
    return self;
}

- (sstate_t) newState:(sstate_t)new_state {
    // same old same old
    if (new_state == STATE_NO_CHANGE || new_state == self.state) {
        return self.state;
    }
    sstate_t old_state = self.state;
    if (self.handler) {
        [self.handler exit];
    }
    self.handler = [SleeperStateObject objectForState:new_state machine:self];
    self.state = new_state;
    [self.handler enterFromState:old_state];
    return new_state;
}

// old

- (NSInteger)_timeToEmpty:(CFDictionaryRef)dict
{
    return [[(NSDictionary *)dict objectForKey:@"Time to Empty"] integerValue];
}

- (NSInteger)_timeToFullCharge:(CFDictionaryRef)dict
{
    return [[(NSDictionary *)dict objectForKey:@"Time to Full Charge"] integerValue];
}


- (void)_lowBatteryWarning:(CFDictionaryRef)newValue {
    [self batteryLow];
}

- (void)_batteryStatusChange:(CFDictionaryRef)newValue
{
    if (newValue) {
        NSInteger currentCapacity = [[(NSDictionary *)newValue objectForKey:@"Current Capacity"] integerValue];
        
        BOOL batteryDischarging = ![[(NSDictionary *)newValue objectForKey:@"Power Source State"] 
                                    isEqualToString:@"AC Power"];
        
        if (! batteryDischarging) {
            NSInteger timeToFullCharge = [self _timeToFullCharge:newValue];
            if (timeToFullCharge <= 0) return;
            NSInteger hours = timeToFullCharge / 60;
            NSInteger minutes = timeToFullCharge - (hours * 60);
            NSLog(@"Current battery charge: %d%%  Estimated time until full: %d:%02d", currentCapacity, hours, minutes);
            // [self powerChangeToAC];
        }
        else {
            NSInteger timeToEmpty = [self _timeToEmpty:newValue];
            
            // unknown estimated time left (still calculating)
            if (timeToEmpty <= 0) return;
            NSInteger hours = timeToEmpty / 60;
            NSInteger minutes = timeToEmpty - (hours * 60);
            NSLog(@"Current battery charge: %d%%  Estimated time remaining: %d:%02d", currentCapacity, hours, minutes);
            
            if (timeToEmpty <= sleepMinutesLeft) {
                [self batteryCritical];   
            } else if (timeToEmpty <= warningMinutesLeft) {
                [self batteryLow];
            } else {
                [self batteryNormal];
            }
        }
    }
}

- (void)_powerAdapterStatusChange:(CFDictionaryRef)newValue
{
    if (newValue != nil) {
        [self powerChangeToAC];
    }
    else {
        [self powerChangeToBattery];
    }
}

- (void)didWakeNotification:(NSNotification *)notification {
    [self hostWake];
    NSLog(@"didWakeNotification: received NSWorkspaceDidWakeNotification");
}

- (void)willSleepNotification:(NSNotification *)notification{
    [self hostSleep];
    NSLog(@"willSleepNotification: received NSWorkspaceWillSleepNotification");
}

// state machine methods

- (sstate_t) hostSleep {
    return [self newState:[handler hostSleep]];
}

- (sstate_t) hostWake {
    return [self newState:[handler hostWake]];
}

- (sstate_t) batteryCritical {
    return [self newState:[handler batteryCritical]];
}

- (sstate_t) batteryLow {
    return [self newState:[handler batteryLow]];
}

- (sstate_t) batteryNormal {
    return [self newState:[handler batteryNormal]];
}

- (sstate_t) powerChangeToAC {
    return [self newState:[handler powerChangeToAC]];
};

- (sstate_t) powerChangeToBattery {
    return [self newState:[handler powerChangeToBattery]];
}

@end


@implementation SleeperStateObject 

@synthesize machine;

+ (SleeperStateObject*) objectForState:(sstate_t)state machine:(SleeperStateMachine*)machine
{
    /*
     STATE_AC,
     STATE_BATTERY_LOW,
     STATE_BATTERY_NORMAL,
     STATE_BATTERY_CRITICAL,
     STATE_ASLEEP
     */
    SleeperStateObject *obj;
    switch (state) {
        case STATE_AC:
            obj = [[SleeperStateAC alloc] init];
            break;
        case STATE_BATTERY_LOW:
            obj = [[SleeperStateBatteryLow alloc] init];
            break;
        case STATE_BATTERY_CRITICAL:
            obj = [[SleeperStateBatteryCritical alloc] init];
            break;
        case STATE_ASLEEP:
            obj = [[SleeperStateAsleep alloc] init];
            break;
        case STATE_BATTERY_NORMAL:
            obj = [[SleeperStateBatteryNormal alloc] init];
            break;
        default:
            NSLog(@"Unknown state: %d", state);
            assert(false);
    }
    
    obj.machine = machine;
    return obj;
}

- (void) enter {
    NSLog(@"Entering state %@", [[self class] className]);
}

- (void) enterFromState:(sstate_t)state {
    [self enter];
}

- (void) exit {
    NSLog(@"Exiting state %@", [[self class] className]);
}

- (sstate_t) hostWake {
    NSLog(@"Host waking up");
    return STATE_NO_CHANGE;
}

- (sstate_t) hostSleep {
    NSLog(@"Host going to sleep");
    return STATE_NO_CHANGE;
}

- (sstate_t) batteryCritical {
    return STATE_BATTERY_CRITICAL;
}

- (sstate_t) batteryLow {
    return STATE_BATTERY_LOW;
}

- (sstate_t) batteryNormal {
    return STATE_BATTERY_NORMAL;
}

- (sstate_t) powerChangeToAC {
    return STATE_AC;
};

- (sstate_t) powerChangeToBattery {
    return STATE_BATTERY_NORMAL;
}
@end


@implementation SleeperStateAC
@end

@implementation SleeperStateBatteryNormal
- (sstate_t) powerChangeToBattery {
    return STATE_BATTERY_NORMAL;
}
@end

@implementation SleeperStateBatteryCritical
- (void) enter
{
    NSLog(@"Entering critical battery state, showing dialog and shutting down!");
    [machine.delegate emergencySleep];
}

- (void) exit
{
    NSLog(@"Exiting critical battery state, hiding dialog!");
}

- (sstate_t) powerChangeToBattery {
    return STATE_NO_CHANGE;
}

// low doesn't take us out of shutdown - that may just be jitter, only AC will take us out of shutdown
- (sstate_t) batteryLow {
    return STATE_NO_CHANGE;
}

- (sstate_t) batteryNormal {
    return STATE_NO_CHANGE;
}
@end



@implementation SleeperStateBatteryLow
- (void) enter
{
    NSLog(@"Entering low battery state, showing dialog!");
    [machine.delegate showLowBatteryWarning];
}

- (void) exit
{
    NSLog(@"Exiting low battery state, hiding dialog!");
    [machine.delegate closeLowBatteryWarning:self];
}

- (sstate_t) powerChangeToBattery {
    return STATE_NO_CHANGE;
}
@end



@implementation SleeperStateAsleep
@end


