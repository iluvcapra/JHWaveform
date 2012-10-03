//
//  JHAppDelegate.m
//  JHWaveformView Demo
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHAppDelegate.h"

@implementation JHAppDelegate

@synthesize waveformView = _waveformView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    float testSignal[] = {0.0f,1.0f,-1.0f,1.0f,-1.0f,0.0f};
    [_waveformView setWaveform:testSignal length:6];

}

@end
