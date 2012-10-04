//
//  JHAudioPreview.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/4/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHWaveformView.h"
#import <AVFoundation/AVFoundation.h>

@interface JHAudioPreview : JHWaveformView {
    AVPlayer *_player;
    
    id _timeObserverDescriptor;

}

@property (readonly) AVPlayer *player;

-(void)setURL:(NSURL *)url;

@end
