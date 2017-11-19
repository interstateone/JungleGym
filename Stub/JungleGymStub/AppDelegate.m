//
//  AppDelegate.m
//  JungleGymStub
//
//  Created by Brandon Evans on 2017-11-19.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

#import "AppDelegate.h"
#import "LiveViewManager.h"
@import Foundation;

NSString * const NeedsIndefiniteExecutionDidChangeNotificationName = @"PlaygroundPageNeedsIndefiniteExecutionDidChangeNotification";
NSString * const LiveViewDidChangeNotificationName = @"PlaygroundPageLiveViewDidChangeNotification";
NSString * const FinishExecutionNotificationName = @"PlaygroundPageFinishExecutionNotification";

@interface AppDelegate ()

@property(nonatomic, strong) LiveViewManager *liveViewManager;
@property(nonatomic, assign) BOOL needsIndefiniteExecution;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // This is temporary so that the app doesn't crash
    // Once the debugger is set up to evaluate the playground expression, the live view manager will have installed a window before this method returns
    self.window = [[UIWindow alloc] init];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    self.liveViewManager = [[LiveViewManager alloc] init];

    [application setStatusBarHidden:true];

    [self registerForPlaygroundSupportNotifications];
    [self enqueueRunLoopBlock];

    return YES;
}

- (void)finishExecutionNotification:(NSNotification *)notification {
    // Communicate back to the host over a socket
    // DVTPlaygroundCommunicationSender.shared.send(data: nil, identifier: "DVTPlaygroundShouldFinishExecution", version: 1, completionBlock: { error in })
}

- (void)liveViewDidChangeNotification:(NSNotification *)notification {
    UIView *newLiveView = notification.userInfo[@"PlaygroundPageLiveView"];
    UIViewController *newLiveViewController = notification.userInfo[@"PlaygroundPageLiveViewController"];

    if (newLiveView) {
        self.liveViewManager.viewController = nil;
        self.liveViewManager.view = newLiveView;
    }
    else if (newLiveViewController) {
        self.liveViewManager.view = nil;
        self.liveViewManager.viewController = newLiveViewController;
    }
    else {
        self.liveViewManager.view = nil;
        self.liveViewManager.viewController = nil;
    }
}

- (void)needsIndefiniteExecutionChangedNotification:(NSNotification *)notification {
    NSNumber *needsIndefiniteExecutionNumber = notification.userInfo[@"PlaygroundPageNeedsIndefiniteExecution"];
    if (needsIndefiniteExecutionNumber) {
        self.needsIndefiniteExecution = needsIndefiniteExecutionNumber.boolValue;
    }
}

- (void)registerForPlaygroundSupportNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needsIndefiniteExecutionChangedNotification:) name:NeedsIndefiniteExecutionDidChangeNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liveViewDidChangeNotification:) name:LiveViewDidChangeNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishExecutionNotification:) name:FinishExecutionNotificationName object:nil];
}

- (void)unregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)finishExecution {
    [self unregisterNotifications];
    [self _playgroundExecutionWillFinish];
    // DVTFinishPlaygroundCommunication()
    exit(0);
}

- (void)enqueueRunLoopBlock {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopPerformBlock(runLoop, kCFRunLoopCommonModes, ^{
        [self _executePlayground];
        fflush(stdout);
        fflush(stderr);
        // DVTExecutePlaygroundDidFinish()
        if (!self.needsIndefiniteExecution) {
            [self finishExecution];
        }
    });
}

// Deliberate no-ops, these are used only as symbols for breakpoints
- (void)_executePlayground {}
- (void)_playgroundExecutionWillFinish {}

@end
