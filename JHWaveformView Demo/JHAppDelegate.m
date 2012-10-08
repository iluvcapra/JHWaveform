//
//  JHAppDelegate.m
//  JHWaveformView Demo
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

// Copyright (c) 2012, Jamie Hardt
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OR
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "JHAppDelegate.h"

@implementation JHAppDelegate

@synthesize waveformView = _waveformView;
@synthesize audioViewStatus = _audioViewStatus;

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
    [_waveformView addObserver:self
                    forKeyPath:@"isReadingOverview"
                       options:NSKeyValueObservingOptionNew
                       context:NULL];
    [_audioViewStatus setStringValue:@"Idle"];
    _numberOfSamples = 1000;
    _player = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == NULL) {
        if (object == _waveformView && [keyPath isEqualToString:@"isReadingOverview"]) {
            if ([change[NSKeyValueChangeNewKey] boolValue]) {
                [_audioViewStatus setStringValue:@"Reading Preview"];
            } else {
                [_audioViewStatus setStringValue:@"Ready"];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
                       _player = nil;
                       _player = [AVPlayer playerWithURL:[op URL]];
                       [_waveformView setPlayer:_player];
                   }
    }];
}

-(IBAction)playTestFile:(id)sender {
    _waveformView.player.rate = 1.0f;
}


-(IBAction)pauseTestFile:(id)sender {
    [_waveformView.player pause];
}

-(IBAction)rtzTestFile:(id)sender {
    [_waveformView.player seekToTime:CMTimeMake(0, 1)];
}
-(IBAction)speedPlayTestFile:(id)sender {
    _waveformView.player.rate = 2.0f;
    
}

@end
