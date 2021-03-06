//
//  BSSharedResources.h
//  BeardedSpice
//
//  Created by Roman Sokolov on 20.08.2018.
//  Copyright © 2018  GPL v3 http://www.gnu.org/licenses/gpl.html
//

#define LOG_LEVEL_DEF ddLogLevel

#import <Foundation/Foundation.h>
@import CocoaLumberjack;

typedef void (^BSSListenerBlock)(void);

/////////////////////////////////////////////////////////////////////
#pragma mark - BSSharedResources Constants

extern DDLogLevel ddLogLevel;
extern DDLogLevel defLogLevel;
extern DDLogLevel verboseLogLevel;

extern NSString *const BeardedSpicePlayPauseShortcut;
extern NSString *const BeardedSpiceNextTrackShortcut;
extern NSString *const BeardedSpicePreviousTrackShortcut;
extern NSString *const BeardedSpiceActiveTabShortcut;
extern NSString *const BeardedSpiceFavoriteShortcut;
extern NSString *const BeardedSpiceNotificationShortcut;
extern NSString *const BeardedSpiceActivatePlayingTabShortcut;
extern NSString *const BeardedSpicePlayerNextShortcut;
extern NSString *const BeardedSpicePlayerPreviousShortcut;

extern NSString *const BeardedSpiceFirstRun;
extern NSString *const BeardieBrowserExtensionsFirstRun;

/**
 Timeout for command of the user iteraction.
 */
#define COMMAND_EXEC_TIMEOUT                10.0

/////////////////////////////////////////////////////////////////////
#pragma mark - BSSharedResources

@protocol BSSharedResourcesSwiftExtension <NSObject>

@optional
+ (void)setSwiftLogLevel:(BOOL)debug;

@end

/**
     Class, which provides exchanging data between app and extension.
 */
@interface BSSharedResources : NSObject <BSSharedResourcesSwiftExtension>

/////////////////////////////////////////////////////////////////////
#pragma mark Properties and public methods

/**
 Returns URL where is shared resources.
 */
@property (class, readonly) NSURL *sharedResuorcesURL;
/**
 Returns shared user defaults object.
 */
@property (class, readonly) NSUserDefaults *sharedDefaults;

/// Init logger for main app.
/// @param name Name of the folder where will be log files (use bundleId, product name and so on)
+ (void)initLoggerForAppWithName:(NSString *)name;

/// Init logger for process, which is component.
/// @param name Name of the folder where will be log files (use bundleId, product name and so on)
/// @param changedBlock performed when new log level obtained
+ (void)initLoggerForComponentWithName:(NSString *)name changed:(dispatch_block_t)changedBlock;

/**
 Performs flush of the shared user defaults.
 */
+ (void)synchronizeSharedDefaults;

/**
 Register listener for changing the tab port.

 @param block Performed on internal thread when catched notification.
 */
+ (void)setListenerOnTabPortChanged:(BSSListenerBlock)block;

@property (class) NSUInteger tabPort;

/// Register listener for changing the log level.
/// @param block Performed on internal thread when catched notification.
+ (void)setListenerOnLogLevelChanged:(BSSListenerBlock)block;

@property (class, readonly) BOOL logLevelDebug;

/**
 Register listener for changing the accepters.

 @param block Performed on internal thread when catched notification.
 */
+ (void)setListenerOnAcceptersChanged:(BSSListenerBlock)block;

/**
 Saves strategies accepters JSON in shared storage.
 Completion is executed on global concurent queue.

 @param accepters Accepters dictionary, may be nil.
 @param completion May be nil.
 */
+ (void)setAccepters:(NSDictionary *)accepters completion:(void (^)(void))completion;

/**
 Gets the strategies accepters dictionary from shared storage.
 Completion is executed on global concurent queue.
   */
+ (void)acceptersWithCompletion:(void (^)(NSDictionary *accepters))completion;

@end
