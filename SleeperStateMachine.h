//
//  SleeperStateMachine.h
//  BattNap
//
//  Created by Robert Sanders on 9/28/10.
//  Copyright (c) 2010 Curious Squid. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppDelegate;
@class SleeperStateMachine;

typedef enum {
    STATE_NO_CHANGE = 0,
    STATE_AC,
    STATE_BATTERY_LOW,
    STATE_BATTERY_NORMAL,
    STATE_BATTERY_CRITICAL,
    STATE_ASLEEP
} sstate_t;

@protocol SleepEventHandler <NSObject>
- (sstate_t) batteryCritical;
- (sstate_t) batteryLow;
- (sstate_t) batteryNormal;
- (sstate_t) powerChangeToAC;
- (sstate_t) powerChangeToBattery;
@end

@interface SleeperStateObject : NSObject <SleepEventHandler> {
    SleeperStateMachine *machine;
}

@property (assign) SleeperStateMachine *machine;

+ (SleeperStateObject*) objectForState:(sstate_t)state machine:(SleeperStateMachine*)machine;

- (void) enter;
- (void) enterFromState:(sstate_t)state;
- (void) exit;
@end

@interface SleeperStateAC : SleeperStateObject {
}
@end

@interface SleeperStateBatteryLow : SleeperStateObject {
}
@end

@interface SleeperStateBatteryNormal : SleeperStateObject {
}
@end

@interface SleeperStateBatteryCritical : SleeperStateObject {
}
@end

@interface SleeperStateAsleep : SleeperStateObject {
}
@end

@interface SleeperStateMachine : NSObject <SleepEventHandler> {
    sstate_t    state;
    SleeperStateObject  *handler;
    AppDelegate *delegate;
    int warningMinutesLeft;
    int sleepMinutesLeft;
}

@property (assign) int warningMinutesLeft;
@property (assign) int sleepMinutesLeft;

@property (assign) sstate_t state;
@property (retain) SleeperStateObject *handler;
@property (assign) AppDelegate *delegate;

- (SleeperStateMachine*) initWithState:(sstate_t)state delegate:(AppDelegate*)delegate;

- (void)_lowBatteryWarning:(CFDictionaryRef)newValue;
- (void)_batteryStatusChange:(CFDictionaryRef)newValue;
- (void)_powerAdapterStatusChange:(CFDictionaryRef)newValue;

@end
