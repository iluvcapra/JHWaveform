//
//  JHAppDelegate.h
//  JHWaveformView Demo
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JHWaveformView.h"
#import "JHAudioPreviewView.h"
#import <CoreMedia/CoreMedia.h>

enum testSignals {
    sine = 1001,
    square = 1002
    };

@interface JHAppDelegate : NSObject <NSApplicationDelegate> {
    JHAudioPreviewView *_waveformView;

    NSUInteger _numberOfSamples;
    NSUInteger _testSignal;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet JHWaveformView *waveformView;

-(IBAction)setTestSignal:(id)sender;
-(IBAction)setNumberOfSamples:(id)sender;

-(IBAction)openTestAudioFile:(id)sender;
-(IBAction)playTestFile:(id)sender;
-(IBAction)pauseTestFile:(id)sender;

-(IBAction)rtzTestFile:(id)sender;
-(IBAction)speedPlayTestFile:(id)sender;

@end
