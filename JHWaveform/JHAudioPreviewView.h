//
//  JHAudioPreview.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/4/12.
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

#import "JHMonoWaveformView.h"

/* this view requires AVFoundation and CoreMedia in order to work its magic */
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@class JHSampleDataProvider;

@interface JHAudioPreviewView : JHMonoWaveformView {
    AVPlayer    *_player;
    
    id          _timeObserverDescriptor;
    NSUInteger  _playheadPosition;
    Float64     _assetDuration;
    
    NSColor     *_playheadColor;
    
    BOOL        _isReadingOverview, _assetUnplayable;
}

/*
 Setting this property causes the PreviewView to create an overview for whatever
 AVPlayerItem is currently on the player.  The view does not observe changes to
 the playerItem at this time, which probably should be fixed.
 */
@property (readwrite, retain) AVPlayer *player;

/*
 The color of the playhead.
 */
@property (readwrite, copy) NSColor *playheadColor;

/*
 When the player property is set, the view will immediately begin reading audio
 data from the player's asset.  This process is a somewhat lengthy process; you
 can observe the propety to let the user know about the view's progress.
 */
@property (readonly) BOOL isReadingOverview;

@end
