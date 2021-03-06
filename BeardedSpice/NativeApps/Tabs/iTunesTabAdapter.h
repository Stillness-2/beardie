//
//  iTunesTabAdapter.h
//  BeardedSpice
//
//  Created by Roman Sokolov on 14.03.15.
//  Copyright (c) 2015 Tyler Rhodes / Jose Falcon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BSNativeAppTabAdapter.h"
#import "iTunes.h"

@class runningSBApplication, Track;

@interface iTunesTabAdapter : BSNativeAppTabAdapter{
    
    BOOL iTunesNeedDisplayNotification;
}

@end
