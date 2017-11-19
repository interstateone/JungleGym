//
//  LiveViewManager.m
//  JungleGymStub
//
//  Created by Brandon Evans on 2017-11-19.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

#import "LiveViewManager.h"
@import Foundation;
@import UIKit;

@implementation LiveViewManager

- (void)setWindow:(UIWindow *)window {
    if ([window isEqual:_window]) { return; }

    _window = window;

    if (window) {
        [window makeKeyAndVisible];
        [self sendLiveViewAvailable];
    }
    else {
        [self sendLiveViewDismissed];
    }
}

- (void)setViewController:(UIViewController *)viewController {
    if ([viewController isEqual:_viewController]) { return; }

    _viewController = viewController;

    if (viewController) {
        self.view = nil;
        self.window = [self windowForPresentingLiveViewController:viewController];
    }
    else {
        self.window = nil;
    }
}

- (void)setView:(UIView *)view {
    if ([view isEqual:_view]) { return; }

    _view = view;

    if (view) {
        self.viewController = nil;
        self.window = [self windowForPresentingLiveView:view];
    }
    else {
        self.window = nil;
    }
}

- (void)sendLiveViewAvailable {
}

- (void)sendLiveViewDismissed {
    NSDictionary *properties = @{@"date": [NSDate date], @"dismissed": @YES};
    NSData *propertiesData = [NSPropertyListSerialization dataWithPropertyList:properties format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    // DVTPlaygroundCommunicationSender.shared.send(data: data, identifier: "XCPLiveView", version: "XCPLiveView", completion: { error in })
}

- (UIWindow *)windowForPresentingLiveViewController:(UIViewController *)viewController {
    UIWindow *window = [self windowForHostingLiveView];
    CGSize size = [viewController preferredContentSize];
    window.frame = CGRectMake(0, 0, size.width, size.height);
    window.rootViewController = viewController;
    return window;
}

- (UIWindow *) windowForPresentingLiveView:(UIView *)view {
    UIWindow *window = [self windowForHostingLiveView];
    window.frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
    [window addSubview:view];
    return window;
}

- (UIWindow *)windowForHostingLiveView {
    UIWindow *window = [[UIWindow alloc] init];
    window.screen = [UIScreen mainScreen];
    window.backgroundColor = [UIColor blackColor];
    window.opaque = YES;
    return window;
}

@end
