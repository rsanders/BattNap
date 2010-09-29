//
//  BatteryMonitor.h
//  BatteryHelper
//
//  Created by Chris Kau on 19/11/2009.
//  Copyright 2009 Chris Kau. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import "AppDelegate.h"
#import "SleeperStateMachine.h"

@interface BatteryMonitor : NSObject {
    CFRunLoopSourceRef _runLoopSource;
    AppDelegate *_delegate;
    
    SleeperStateMachine *_machine;
    
    int warningMinutesLeft;
    int sleepMinutesLeft;
}


@property (assign) int warningMinutesLeft;
@property (assign) int sleepMinutesLeft;


@end
