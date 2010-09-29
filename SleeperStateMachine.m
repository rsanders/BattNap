//
//  SleeperStateMachine.m
//  BattNap
//
//  Created by Robert Sanders on 9/28/10.
//  Copyright (c) 2010 Curious Squid. All rights reserved.
//

#import "SleeperStateMachine.h"


@implementation SleeperStateMachine
@synthesize handler;
@synthesize state;
@synthesize delegate;

@interface SleeperStateMachine (Private)
- (sstate_t) newState:(sstate_t)new_state;
@end

- (SleeperStateMachine*) initWithState:(sstate_t)_state delegate:(AppDelegate*)_delegate
{
    self = [super init];
    self.state = STATE_NO_CHANGE;
    [self newState:_state];
    self.delegate = _delegate;
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
@end

@implementation SleeperStateBatteryCritical
@end

@implementation SleeperStateBatteryLow
@end

@implementation SleeperStateAsleep
@end

