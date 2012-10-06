//
//  JHAudioPreview.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/4/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHWaveformView.h"
#import <AVFoundation/AVFoundation.h>

@interface JHAudioPreviewView : JHWaveformView {
    AVPlayer *_player;
    
    id _timeObserverDescriptor;
    NSUInteger  _playheadPosition;
    Float64     _assetDuration;

}

@property (readwrite) AVPlayer *player;



//-(void)setURL:(NSURL *)url error:(NSError *__autoreleasing *)loadError;

@end
