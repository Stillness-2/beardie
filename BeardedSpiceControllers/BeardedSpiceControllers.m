//
//  BeardedSpiceControllers.m
//  BeardedSpiceControllers
//
//  Created by Roman Sokolov on 05.03.16.
//  Copyright © 2016  GPL v3 http://www.gnu.org/licenses/gpl.html
//

#import "BeardedSpiceControllers.h"
#import "BSCService.h"

@implementation BeardedSpiceControllers

- (void)setShortcuts:(NSDictionary <NSString*, MASShortcut *> *)shortcuts{
    DDLogInfo(@"setShortcuts");
    
    [[BSCService singleton] setShortcuts:shortcuts];
}

- (void)setMediaKeysSupportedApps:(NSArray <NSString *>*)bundleIds{
    DDLogInfo(@"setMediaKeysSupportedApps");
    
    [[BSCService singleton] setMediaKeysSupportedApps:bundleIds];
}

- (void)setPhoneUnplugActionEnabled:(BOOL)enabled{
    DDLogInfo(@"setPhoneUnplugActionEnabled");
    
    [[BSCService singleton] setPhoneUnplugActionEnabled:enabled];
}

- (void)prepareForClosingConnectionWithCompletion:(void (^)(void))completion{

    [[BSCService singleton] removeConnection:_connection];
    
    completion();
}

@end
