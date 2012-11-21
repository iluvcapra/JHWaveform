//
//  JHSampleDataProvider.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/11/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import <aubio/aubio.h>
#import <sndfile.h>

/* The SampleDataProvider is a class cluster for taking one of several
 different kinds of sources and making them look random-accessible.  It
 presently does this in the most memory-intensive way possible. */

/*
 This class is meant to give us just enough abstraction between data buffers and
 the views to allow us to eventually implement progressive data loading, either 
 through blocks or delegate calls.  Eventually this will operate a bit like a 
 lazy-loading NSData.
 */

@interface JHSampleDataProvider : NSObject {

}

// init a dataProvider with an ABAsset
+(id)providerWithAsset:(AVAsset *)asset
                 track:(AVAssetTrack *)track
             timeRange:(CMTimeRange)timeRange;

+(id)providerWithAsset:(AVAsset *)asset
                 track:(AVAssetTrack *)track;



//init with an ExtAudioFileRef
+(id)providerWithExtAudioFile:(ExtAudioFileRef)audioFileRef;


#ifdef AUBIO_H

// init a dataProvder with an Aubio fVec
+(id)providerWithFVec:(fvec_t *)vector;

#endif

#ifdef SNDFILE_H

// init a dataProvider with a libsndfile sound file
+(id)providerWithSndfile:(SNDFILE *)file;

#endif


-(NSRange)copySamples:(float **)outSamples
            inRange:(NSRange)range;

-(NSUInteger)samplesLength;



@end
