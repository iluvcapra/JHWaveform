//
//  JHAppDelegate.h
//  JHWaveformView Demo
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JHWaveformView.h"

@interface JHAppDelegate : NSObject <NSApplicationDelegate> {
    JHWaveformView *_waveformView;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet JHWaveformView *waveformView;

@end
