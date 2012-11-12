//
//  JHSampleDataProvider.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/11/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataProvider.h"

#define ASSET_SAMPLE_RATE   ( 48000.0f )

@interface _JHAVAssetSampleDataProvider : JHSampleDataProvider {
    AVAsset         *_asset;
    AVAssetTrack    *_track;
    CMTimeRange     _timeRange;
    NSData           *_sampleData;
}

-(id)initWithAsset:(AVAsset *)asset
             track:(AVAssetTrack *)track
         timeRange:(CMTimeRange)range;

@end

@implementation _JHAVAssetSampleDataProvider

-(void)_loadDataWithAsset:(AVAsset *)asset
                    track:(AVAssetTrack *)track
              inTimeRange:(CMTimeRange)range {
    
}

-(id)initWithAsset:(AVAsset *)asset
             track:(AVAssetTrack *)track
         timeRange:(CMTimeRange)range {
    self = [super init];
    if (self) {
        [self _loadDataWithAsset:asset
                          track:track
                    inTimeRange:range];
    }
}


@end


@implementation JHSampleDataProvider


+(id)providerWithAsset:(AVAsset *)asset
             track:(AVAssetTrack *)track
         timeRange:(CMTimeRange)timeRange {
    return nil;

}

+(id)providerWithExtAudioFile:(ExtAudioFileRef)audioFileRef {
    NSAssert(0,@"%s not implemented",(char *)_cmd);
    return nil;
}

#ifdef AUBIO_H

+(id)providerWithFVec:(fvec_t *)vector {
    NSAssert(0,@"%s not implemented",(char *)_cmd);
    return nil;
}

#endif

#ifdef SNDFILE_H

+(id)providerWithSndfile:(SNDFILE *)file {
    NSAssert(0,@"%s not implemented",(char *)_cmd);
    return nil;
}

#endif


-(NSRange)copySamples:(float *)outSamples inRange:(NSRange)range {
    return NSMakeRange(NSNotFound, 0);
}

-(NSUInteger)samplesLength {
    return 0;
}


@end
