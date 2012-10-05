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

-(void)_setTestSignalToView {
    
    float *testSignal = malloc(_numberOfSamples * sizeof(float));
    
    NSUInteger i;
    
    if (_testSignal == sine) {
        for (i = 0; i < _numberOfSamples ; i++) {
            testSignal[i] = sinf(i);
        }
    } else if (_testSignal == square) {
        for (i = 0; i < _numberOfSamples ; i++) {
            testSignal[i] = (i % 2 - 0.5f) * 2;
        }
    }
    
    [_waveformView setWaveform:testSignal length:_numberOfSamples];
    free(testSignal);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    float testSignal[] = {0.0f,1.0f,-1.0f,1.0f,-1.0f,0.0f};
    [_waveformView setWaveform:testSignal length:6];
    _numberOfSamples = 1000;
}


-(IBAction)setTestSignal:(id)sender {
    _testSignal = [sender selectedTag];
    [self _setTestSignalToView];
}


-(IBAction)setNumberOfSamples:(id)sender {
    _numberOfSamples = [sender integerValue];
    [self _setTestSignalToView];
}

-(IBAction)openTestAudioFile:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];

    [op setAllowsMultipleSelection:NO];
    [op beginSheetModalForWindow:self.window
               completionHandler:^(NSInteger result) {
                   if (result == NSFileHandlingPanelOKButton) {
                       NSError *error = nil;
                       [_waveformView setURL:[op URL] error:&error];
                       
                       if (error != nil) {
                           [NSApp presentError:error];
                       }
                   }
    }];
    
    

}

@end
