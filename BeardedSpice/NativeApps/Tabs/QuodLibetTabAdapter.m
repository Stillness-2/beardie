//
//  QuodLibetTabAdapter.m
//  BeardedSpice
//
//  Created by Martijn Pieters on 13/02/2021.
//  Copyright (c) 2021 GPL v3 http://www.gnu.org/licenses/gpl.html
//

#import "QuodLibetTabAdapter.h"
#import "BSTrack.h"
#import "BSSharedResources.h"

#import <unistd.h>
#import <sys/stat.h>

#define APPNAME_QUOD_LIBET      @"Quod Libet"
#define APPID_QUOD_LIBET        @"io.github.quodlibet.QuodLibet"

// How long to cache state and track information for? Values expressed as NSTimeInterval (double value, seconds)
#define QL_CACHE_STATE          0.5
#define QL_CACHE_TRACK_INFO     0.5

// QuodLibet is controlled through named pipes, and the tags for
// the currently playing song are written out to a text file.
#define QL_CONTROL              @"~/.quodlibet/control"
#define QL_CURRENT              @"~/.quodlibet/current"
#define FIFO_TIMEOUT            500 * NSEC_PER_MSEC // time until we give up on a response from QL, in nanoseconds

// Control commands for QuodLibet
#define QL_CONTROL_STATUS       @"status"
#define QL_CONTROL_PLAY_PAUSE   @"play-pause"
#define QL_CONTROL_PAUSE        @"pause"
#define QL_CONTROL_NEXT         @"next"
#define QL_CONTROL_PREVIOUS     @"previous"

#define QL_CONTROL_JOINER       @"\0"
NSString *const NSSTRING_EMPTY  = @"";

#define QL_STATUS_PLAYING       @"playing"
#define QL_STATUS_PAUSED        @"paused"

// tag names in QL_CURRENT we are interested in
#define QL_TRACK_TITLE          @"title"
#define QL_TRACK_ARTIST         @"artist"
#define QL_TRACK_ALBUM          @"album"
#define QL_TRACK_FILENAME       @"~filename"
#define QL_TRACK_LENGTH         @"~#length"



static NSString * FormatNSTimeInterval(NSTimeInterval interval) {
    NSInteger ti = (NSInteger)interval;
    if (ti < 3600) {
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)(ti / 60), (long)(ti % 60)];
    } else {
        NSInteger min = ti / 60;
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)(min / 60), (long)(min % 60), (long)(ti % 60)];
    }
}


@implementation QuodLibetTabAdapter{
    QuodLibetStatus _status;
    double _progress;
}

- (id)init {
    self = [super init];
    if (self) {
        _status = QuodLibetStatusUnknown;
        _progress = 0;
    }
    return self;
}

+ (NSString *)displayName{
    return APPNAME_QUOD_LIBET;
}

+ (NSString *)bundleId{
    return APPID_QUOD_LIBET;
}

- (NSString *)URL{
    return APPNAME_QUOD_LIBET;
}

- (NSString *)key{
    return @"A:" APPNAME_QUOD_LIBET;
}

- (NSString *)title{
    @autoreleasepool {
        
        NSString *title;
        BSTrack *trackInfo = [self trackInfo];
        if (trackInfo.track)
            title = trackInfo.track;
        
        if (trackInfo.artist) {
            
            if (title) title = [title stringByAppendingFormat:@" - %@", trackInfo.artist];
            else
                title = trackInfo.artist;
        }
        if ([NSString isNullOrEmpty:title]) {
            title = BSLocalizedString(@"no-track-title", NSSTRING_EMPTY);
        }
        
        return [NSString stringWithFormat:@"%@ | %@", QuodLibetTabAdapter.displayName, title];
    }
}

#pragma mark Player control methods

- (BOOL)toggle{
    return [self sendControlToQuodLibet:QL_CONTROL_PLAY_PAUSE];
}

- (BOOL)pause{
    return [self sendControlToQuodLibet:QL_CONTROL_PAUSE];
}

- (BOOL)next{
    return [self sendControlToQuodLibet:QL_CONTROL_NEXT];
}

- (BOOL)previous{
    return [self sendControlToQuodLibet:QL_CONTROL_PREVIOUS];
}

- (BSTrack *)trackInfo{
    
    [self loadQuodLibetState];
    
    // read track status from current file
    NSError *error = nil;
    NSString *current = [[NSString alloc] initWithContentsOfFile:[QL_CURRENT stringByExpandingTildeInPath]
                                                        encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Failed to read QuodLibet current track info: %@", [error localizedDescription]);
        return nil;
    }
    
    BSTrack *track = [BSTrack new];
    NSString *filename;
    
    NSArray *lines = [current componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSRange delim = [line rangeOfString:@"="];
        if (delim.location != NSNotFound) {
            NSString *key = [line substringToIndex:delim.location];
            NSString *value = [line substringFromIndex:delim.location + 1];
            
            if ([key isEqualToString:QL_TRACK_TITLE]) {
                track.track = value;
            } else if ([key isEqualToString:QL_TRACK_ARTIST]) {
                track.artist = value;
            } else if ([key isEqualToString:QL_TRACK_ALBUM]) {
                track.album = value;
            } else if ([key isEqualToString:QL_TRACK_FILENAME]) {
                filename = value;
            } else if ([key isEqualToString:QL_TRACK_LENGTH]) {
                NSTimeInterval length = [value doubleValue];
                NSTimeInterval position = length * _progress;
                track.progress = [NSString stringWithFormat:@"%@ of %@",
                                  FormatNSTimeInterval(position),
                                  FormatNSTimeInterval(length)];
            }
        }
    }
    
    if ([NSString isNullOrEmpty:track.track]) {
        // No title field for this track, fall back to basename.
        // QuodLibet's "current" file is guaranteed to have a ~filename tag, we can
        // rely on that here. The output format here, using the base
        // filename with localised `[Unknown]` postfix, echoes how QL generates
        // a track title for such tracks.
        NSString *basename = [filename lastPathComponent];
        if ([NSString isNullOrEmpty:basename]) {
            basename = filename;
        }
        NSString *unknown = BSLocalizedString(@"unknown", NSSTRING_EMPTY);
        track.track = [NSString stringWithFormat:@"%@ [%@]", basename, unknown];
    }
    
    return track;
}

- (BOOL)isPlaying{
    [self loadQuodLibetState];
    return _status == QuodLibetStatusPlaying;
}

#pragma mark QuodLibet remote control methods

- (void)loadQuodLibetState{
    
    NSString *response = [self sendControlToQuodLibet:QL_CONTROL_STATUS expectResponse:YES];
    
    if (response) {
        /**
         * The response string is a space-delimited series of fields (from
         * https://github.com/quodlibet/quodlibet/blob/b92e08484e44f7e056a3fb3f7daeb70b201698c9/quodlibet/commands.py#L468-L489)
         * - play status ("playing" / "paused")
         * - view name ("AlbumList", "CollectionBrowser", "CoverGrid", etc)
         * - volume (float range [0.000 - 1.000])
         * - shuffle mode ("shuffle" / "inorder")
         * - repeat mode ("on" / "off")
         * - progress (proportion of track played, float range [0.000 - 1.000])
         */
        
        NSArray *components = [response componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([components count] > 0) {
            if ([components[0] isEqualTo:QL_STATUS_PLAYING]) {
                _status = QuodLibetStatusPlaying;
                if ([components count] >= 6) {
                    _progress = [components[5] doubleValue];
                }
             } else if ([components[0] isEqualTo:QL_STATUS_PAUSED]) {
                _status = QuodLibetStatusPaused;
             } else {
                 NSLog(@"Could not parse QuodLibet response: %@", response);
            }
        }
    }
}

- (BOOL)sendControlToQuodLibet:(NSString *)control{
    return [self sendControlToQuodLibet:control expectResponse:NO] != nil;
}

/// Sends request and returns response or empty string. Returns nil on failure.
- (NSString *)sendControlToQuodLibet:(NSString *)control expectResponse:(BOOL)responseExpected {
    /**
     * QuodLibet communication
     * The QuodLibet named pipe protocol accepts either a newline-terminated message, or
     * a message and return FIFO filename if a response should be sent; the latter format
     * uses NUL delimiters (NUL + message + NUL + filename + NUL). You then need to read
     * the response from the response pipe. All data is UTF-8 encoded.
     */

    __block NSString *result = NSSTRING_EMPTY;
    NSFileHandle *quodLibetControlPipe = [self quodLibetRemotePipe];
    
    if (quodLibetControlPipe) {
        NSString *returnPipe = nil;
        NSFileHandle *returnPipeHandle = nil;

        if (responseExpected && !(returnPipe = [self temporaryFIFOFilename])) {
            // failed to create a return FIFO, abort
            return nil;
        }

        NSString *msg = responseExpected
            ?
                // NUL command NUL response-filename NUL
                [@[ NSSTRING_EMPTY, control, returnPipe, NSSTRING_EMPTY ]
                 componentsJoinedByString:QL_CONTROL_JOINER]
            :
                // command NL
                [control stringByAppendingString:@"\n"];

        @try {
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);

            quodLibetControlPipe.writeabilityHandler = ^(NSFileHandle * fh) {
                [fh writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
                fh.writeabilityHandler = nil;
                dispatch_semaphore_signal(sem);
            };
            dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, FIFO_TIMEOUT));
            quodLibetControlPipe.writeabilityHandler = nil;
            [quodLibetControlPipe closeFile];

            if (responseExpected) {
                // Read from return pipe, but don't wait forever
                NSFileHandle *returnPipeHandle = [NSFileHandle fileHandleForReadingAtPath:returnPipe];
                returnPipeHandle.readabilityHandler = ^(NSFileHandle * fh) {
                    result = [[NSString alloc] initWithData:[fh availableData] encoding:NSUTF8StringEncoding];
                    fh.readabilityHandler = nil;
                    dispatch_semaphore_signal(sem);
                };
                dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, FIFO_TIMEOUT));
                quodLibetControlPipe.readabilityHandler = nil;
                
                if (!result.length) {
                    DDLogError(@"Never received a response from QuodLibet return pipe");
                    result = nil;
                }
            }
        
        } @catch (NSException *exception) {
            DDLogError(@"Exception during communication with QuodLibet: %@", exception);
            result = nil;
        } @finally {
            if (returnPipe) {
                if (returnPipeHandle) {
                    returnPipeHandle.readabilityHandler = nil;
                    [returnPipeHandle closeFile];
                }

                NSError *error = nil;
                [[NSFileManager defaultManager]  removeItemAtPath:returnPipe error:&error];
                if (error) {
                    DDLogWarn(@"Failed to delete QuodLibet return pipe path at %@: %@", returnPipe, error);
                }
            }
        }
    }
    
    return result;
}

- (NSFileHandle *)quodLibetRemotePipe{
    // Verify that the control named pipe exists and is writable
    NSString *controlPath = [QL_CONTROL stringByExpandingTildeInPath];
    if (![[NSFileManager defaultManager] isWritableFileAtPath:controlPath]) {
        DDLogError(@"QuodLibet control path not available for writing");
        return nil;
    }

    const char *controlPathChar = [controlPath fileSystemRepresentation];
    struct stat controlStat;
    if (stat(controlPathChar, &controlStat) == -1) {
        DDLogError(@"Failed to stat QuodLibet control path");
        return nil;
    }
    if (!S_ISFIFO(controlStat.st_mode)) {
        DDLogError(@"QuodLibet control file is not a named pipe");
        return nil;
    }
    
    // open control path for non-blocking writing; this fails if there is
    // no reader on the other end (== QuodLibet is not running properly).
    int fd = open(controlPathChar, O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        DDLogError(@"Failed to open QuodLibet control file, error: %d (%s)", errno, strerror(errno));
    }
    return [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
}

- (NSString *)temporaryFIFOFilename{
    NSString *fifoFilename = nil;

    NSString *tmpTemplate = [NSTemporaryDirectory()
        stringByAppendingPathComponent:@"beardedSpice.XXXXXX"];
    const char *tmpTemplateChar = [tmpTemplate fileSystemRepresentation];

    char *tmpFilenameChar = calloc(strlen(tmpTemplateChar) + 1, sizeof(char));
    strcpy(tmpFilenameChar, tmpTemplateChar);
    mktemp(tmpFilenameChar);

    if (!tmpFilenameChar || strlen(tmpFilenameChar) == 0) {
        DDLogError(@"Error while creating temporary filename for FIFO");
    } else {
        // create a FIFO file we can read from. mkfifo *fails* if the filename exists,
        // so this is safe.
        if (mkfifo(tmpFilenameChar, 0600) == -1) {
            DDLogError(@"Error while creating temporary FIFO: %d (%s)", errno, strerror(errno));
        } else {
            fifoFilename = [[NSFileManager defaultManager]
                            stringWithFileSystemRepresentation:tmpFilenameChar
                            length:strlen(tmpFilenameChar)];
        }
    }
    
    free(tmpFilenameChar);
    return fifoFilename;
}

@end
