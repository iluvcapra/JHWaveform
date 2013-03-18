//
//  JHSampleDataProvider2.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/21/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

//#import <aubio/aubio.h>
//#import <sndfile.h>

/* The SampleDataProvider is a class cluster for taking one of several
 different kinds of sources and making them look like random-accessible buffers 
 of floats, silently doing whatever data conversions and IO are required to make
 this happen.  It presently does this in the most memory-intensive way possible. */

/*
 This class is meant to give us just enough abstraction between data buffers and
 the views to allow us to eventually implement progressive data loading, either
 through blocks or delegate calls.  Eventually this will operate a bit like a
 lazy-loading NSData.
 */

/*
 This is a redo of this class to support tables of samples in frames.
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
//+(id)providerWithExtAudioFile:(ExtAudioFileRef)audioFileRef;


#ifdef AUBIO_H

// init a dataProvder with an Aubio fVec.
// Because fVec structures have an implicit sample rate, you must give
// an explicit one here in order to fulfill the SampleDataProvider's contract.
+(id)providerWithFVec:(fvec_t *)vector
      framesPerSecond:(NSUInteger)sampleRate
         freeWhenDone:(BOOL)freeWhenDone;

#endif

#ifdef SNDFILE_H

// init a dataProvider with a libsndfile sound file
+(id)providerWithSndfile:(SNDFILE *)file;

#endif
 
-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock;

-(void)yieldSamplesOnChannel:(NSUInteger)chan
               inFrameRange:(NSRange)aRange
                    toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock;

-(NSUInteger)framesLength;
-(double)framesPerSecond;
-(NSUInteger)samplesPerFrame;



@end
