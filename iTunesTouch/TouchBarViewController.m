//
//  TouchBarViewController.m
//  iTunesTouch
//
//  Created by Jonathan Rauch on 2/20/17.
//  Copyright © 2017 Jonathan Rauch. All rights reserved.
//

#import "TouchBarViewController.h"
#import "iTunes.h"
#import "Spotify.h"

@interface TouchBarViewController ()

@property NSString *currentTrackText;
@property NSTimer *repeatingTimer;
@property NSImage *artwork;

@end

@implementation TouchBarViewController

static NSString *iTunesBundleId = @"com.apple.iTunes";
static NSString *spotifyBundleId = @"com.spotify.client";
static NSImage *grayPlaceholderImage;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentTrackText = @"";
    grayPlaceholderImage = placeholderImage(CGSizeMake(30, 30), [NSColor lightGrayColor]);
    self.artwork = grayPlaceholderImage;
    
    self.repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
}


BOOL isRunning(NSString *bundleId) {
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in apps) {
        if ([app.bundleIdentifier isEqualToString:bundleId])
            return true;
    }
    return false;
}

- (void)updateLabel {

    if (isRunning(iTunesBundleId)) {
        [self updateFromiTunes];
    }
    else if (isRunning(spotifyBundleId)) {
        [self updateFromSpotify];
        return;
    }
}

- (void)updateFromSpotify {
    SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:spotifyBundleId];
    SpotifyTrack *currentTrack = [spotify currentTrack];
    if (currentTrack != nil) {
        self.currentTrackText = [NSString stringWithFormat:@"%@ - %@", [currentTrack artist], [currentTrack name]];
        
        NSURL *url = [NSURL URLWithString:[currentTrack artworkUrl]];
        
        NSURLSessionDownloadTask *downloadPhotoTask = [[NSURLSession sharedSession]
                                                       downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                           
                                                           NSImage *downloadedImage = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:location]];
                                                           NSImage *resizedImage = resizeImageForTouchBar(downloadedImage);
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               self.artwork = resizedImage;
                                                           });
                                                       }];
        [downloadPhotoTask resume];
    }
    else {
        self.currentTrackText = @"";
    }
}

NSImage *resizeImageForTouchBar(NSImage *image) {
    CGSize destinationSize = CGSizeMake(30, 30);
    NSImage *scaleToFillImage = [NSImage imageWithSize:destinationSize
                                               flipped:NO
                                        drawingHandler:^BOOL(NSRect dstRect) {
                                            
                                            NSSize imageSize = [image size];
                                            NSRect srcRect = NSMakeRect(0, 0, imageSize.width, imageSize.height);
                                            
                                            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
                                            
                                            [image drawInRect:dstRect
                                                               fromRect:srcRect
                                                              operation:NSCompositingOperationCopy
                                                               fraction:1.0
                                                         respectFlipped:YES
                                                                  hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
                                            
                                            return YES;
                                        }];
    return scaleToFillImage;
}

NSImage *placeholderImage(CGSize size, NSColor *color) {
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    [color drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [image unlockFocus];
    return image;
}

- (void)updateFromiTunes {
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:iTunesBundleId];
    iTunesTrack *currentTrack = [iTunes currentTrack];
    if (currentTrack != nil) {
        self.currentTrackText = [NSString stringWithFormat:@"%@ - %@", [currentTrack artist], [currentTrack name]];
        
        NSArray<iTunesArtwork *> * artworks = [[currentTrack artworks] get];
        NSImage *originalArtwork = [[artworks lastObject] data];
        if (!originalArtwork) {
            self.artwork = grayPlaceholderImage;
        }
        else {
            self.artwork = resizeImageForTouchBar(originalArtwork);
        }
        
        return;
    }
}

@end
