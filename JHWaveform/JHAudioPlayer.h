//
//  JHAudioPlayer.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 4/6/13.
//  Copyright (c) 2013 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

@interface JHAudioPlayer : NSObject

- (id)initWithContentsOfURL:(NSURL *)url
                      error:(NSError **)outError;

- (id)initWithData:(NSData *)data
             error:(NSError **)outError;

- (BOOL)play;
- (void)stop;

/* properties */

@property(readonly) BOOL playing;

@property(readonly) NSUInteger numberOfChannels;
@property(readonly) NSTimeInterval duration;

@property(readonly) NSURL *url;
@property(readonly) NSData *data;

@property float volume;
@property float rate;
@property NSTimeInterval currentTime;
@property NSInteger numberOfLoops;

/* settings */
@property(readonly) NSDictionary *settings;

/* metering */

@property(readwrite) BOOL meteringEnabled;

- (void)updateMeters;

- (float)peakPowerForChannel:(NSUInteger)channelNumber;

- (float)averagePowerForChannel:(NSUInteger)channelNumber;

@end
