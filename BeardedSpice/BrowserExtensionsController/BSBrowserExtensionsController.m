//
//  BSBrowserExtensionsController.m
//  BeardedSpice
//
//  Created by Roman Sokolov on 14.09.17.
//  Copyright © 2017 GPL v3 http://www.gnu.org/licenses/gpl.html
//

#import "BSBrowserExtensionsController.h"
#import "NSString+Utils.h"
#import "NSURL+Utils.h"
#import "NSException+Utils.h"
#import "AppDelegate.h"
#import "GeneralPreferencesViewController.h"
#import "BSPreferencesWindowController.h"
#import <Beardie-Swift.h>


@implementation BSBrowserExtensionsController {
    NSMutableArray *_observers;
    dispatch_queue_t _workQueue;
    NSOperationQueue *_oQueue;
    BOOL _started;
    BOOL _paused;
    BOOL _displayWarningDialog;
}

static BSBrowserExtensionsController *singletonBSBrowserExtensionsController;

+ (BSBrowserExtensionsController *)singleton {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        singletonBSBrowserExtensionsController = [BSBrowserExtensionsController alloc];
        
        //redefine this for SafariTechPrev
        singletonBSBrowserExtensionsController = [singletonBSBrowserExtensionsController init];
    });
    
    return singletonBSBrowserExtensionsController;
}

- (id)init {
    
    
    if (self != singletonBSBrowserExtensionsController) {
        [[NSException exceptionWithName:NSGenericException reason:@"Only singleton!" userInfo:nil] raise];
    }
    
    self = [super init];
    if (self) {
        _started = NO;
        _observers = [NSMutableArray new];
        _workQueue = dispatch_queue_create("BrowserExtensionsController", DISPATCH_QUEUE_SERIAL);
        _webSocketServer = [BSStrategyWebSocketServer singleton];
    }
    return self;
}

- (void)dealloc {
    for (id item in _observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:item];
    }
}

/////////////////////////////////////////////////////////////////////////
#pragma mark Public properties and methods

- (void)start {
    dispatch_async(_workQueue, ^{
        if (! self->_started) {
            self->_oQueue = [NSOperationQueue new];
            self->_oQueue.underlyingQueue = self->_workQueue;
            id observer = [[NSNotificationCenter defaultCenter]
                           addObserverForName:GeneralPreferencesWebSocketServerEnabledChangedNoticiation
                           object:nil queue:self->_oQueue usingBlock:^(NSNotification * _Nonnull note) {
                               @autoreleasepool {
                                   if ([[NSUserDefaults standardUserDefaults] boolForKey:BSWebSocketServerEnabled]) {
                                       [self installNativeMessagingComponents];
                                       DDLogInfo(@"ChromeExtensionMaintenance install result: %@", [ChromeExtensionMaintenance install] ? @"YES" : @"NO");
                                       if ([self->_webSocketServer start] == NO) {
                                           [[NSUserDefaults standardUserDefaults] setBool:NO forKey:BSWebSocketServerEnabled];
                                       }
                                   }
                                   else {
                                       [self uninstallNativeMessagingComponents];
                                       DDLogInfo(@"ChromeExtensionMaintenance uninstall result: %@", [ChromeExtensionMaintenance uninstall] ? @"YES" : @"NO");
                                       [self->_webSocketServer stopWithComletion:nil];
                                   }
                               }
                           }];
            if (observer) {
                [self->_observers addObject:observer];
            }
            if ([[NSUserDefaults standardUserDefaults] boolForKey:BSWebSocketServerEnabled]) {
                [self installNativeMessagingComponents];
                DDLogInfo(@"ChromeExtensionMaintenance install result: %@", [ChromeExtensionMaintenance install] ? @"YES" : @"NO");
                if ([self->_webSocketServer start] == NO) {
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:BSWebSocketServerEnabled];
                }
            }
            self->_started = YES;
        }
    });
}

- (void)pause {
    dispatch_sync(_workQueue, ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSWebSocketServerEnabled]) {
            if (self->_paused == NO) {
                [self->_webSocketServer stopWithComletion:nil];
                DDLogInfo(@"BSBrowserExtensionsController paused");
                self->_paused = YES;
            }
        }
    });
}
- (BOOL)resume {
    __block BOOL result = NO;
    dispatch_sync(_workQueue, ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSWebSocketServerEnabled]) {
            if (self->_paused) {
                result = [self->_webSocketServer start];
                if (result == NO) {
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:BSWebSocketServerEnabled];
                    return;
                }
                DDLogInfo(@"BSBrowserExtensionsController resumed");
            }
        }
    });
    _paused = !result;
    return result;
}

- (void)openGetExtensions {
    AppDelegate *app = (AppDelegate *)NSApp.delegate;
    BSPreferencesWindowController *windowController = (BSPreferencesWindowController *)app.preferencesWindowController;
    [app openPreferences:self];
    [windowController selectControllerWithIdentifier:GeneralPreferencesViewController.className];
    dispatch_async(dispatch_get_main_queue(), ^{
        GetExtensions *dialog = [[GetExtensions alloc] initWithWindowNibName:@"GetExtensions"];
        [dialog beginSheetForWindow:windowController.window];
    });

}
- (void)firstRunPerformWithCompletion:(dispatch_block_t)completion {

    ASSIGN_WEAK(self);
    ASSIGN_WEAK(completion);
    
    __block id observer;
    dispatch_block_t execBlock = ^() {
        @autoreleasepool {
            ASSIGN_STRONG(self);
            ASSIGN_STRONG(completion);
            
            if (observer) {
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
                observer = nil;
            }
            
            NSAlert *alert = [NSAlert new];
            alert.alertStyle = NSAlertStyleWarning;
            alert.messageText = BSLocalizedString(@"install-enable-extension-title", @"Title of the suggestion about installing BeardedSpice extensions for browsers.");
            alert.informativeText = BSLocalizedString(@"install-enable-extension-text", @"Informative text of the suggestion about installing BeardedSpice extensions for browsers.");
            [alert addButtonWithTitle:BSLocalizedString(@"install-enable-extension-button-title", @"Button title")];
            
            [alert addButtonWithTitle:BSLocalizedString(@"cancel-button-title", @"Button title")];
            
            [UIController windowWillBeVisible:alert completion:^{
                if ([alert runModal] == NSAlertFirstButtonReturn) {
                    [USE_STRONG(self) openGetExtensions];
                };
                if (USE_STRONG(completion)) {
                    USE_STRONG(completion)();
                }

                [UIController removeWindow:alert];
            }];
            
        }
    };
    
    if (_webSocketServer.started == NO) {
        observer = [[NSNotificationCenter defaultCenter]
                    addObserverForName:BSWebSocketServerStartedNotification
                    object:nil queue:_oQueue usingBlock:^(NSNotification * _Nonnull note) {
                        dispatch_async(dispatch_get_main_queue(), execBlock);
                    }];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), execBlock);
    }
}

/////////////////////////////////////////////////////////////////////////
#pragma mark Helper methods (Private)

/// Update manifests for native messaging app and so on
/// for supported browsers
- (void)installNativeMessagingComponents {
    BOOL result = [ChromeNativeMessaging updateManifest];
    DDLogInfo(@"ChromeNativeMessaging install result: %@", result ? @"YES" : @"NO");
}
/// Remove manifests for native messaging app and so on
/// for supported browsers
- (void)uninstallNativeMessagingComponents {
    BOOL result = [ChromeNativeMessaging removeManifest];
    DDLogInfo(@"ChromeNativeMessaging uninstall result: %@", result ? @"YES" : @"NO");
}


@end
