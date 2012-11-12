//
//  JHSampleDataProvider.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/11/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataProvider.h"

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

-(BOOL)_loadDataWithAsset:(AVAsset *)asset
                    track:(AVAssetTrack *)track
              inTimeRange:(CMTimeRange)range {
    
    NSError *error = nil;
    AVAssetReader *sampleReader = [[AVAssetReader alloc] initWithAsset:asset
                                                                 error:&error];
    
    sampleReader.timeRange = range;
    
    NSMutableData *floatData = nil;
    
    if (error == nil) {
        AVAssetTrack *theTrack = track;
        
        NSDictionary *lpcmOutputSetting = @{
        AVFormatIDKey : @( kAudioFormatLinearPCM ),
        AVSampleRateKey : @( 48000 ),
        AVLinearPCMIsFloatKey : @YES,
        AVLinearPCMBitDepthKey : @32,
        AVLinearPCMIsNonInterleaved : @NO,
        AVNumberOfChannelsKey : @1
        };
        
        
        AVAssetReaderTrackOutput *trackOutput =
        [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack: theTrack
                                                   outputSettings: lpcmOutputSetting];
        [sampleReader addOutput:trackOutput ];
        
        [sampleReader startReading];
        
        CMSampleBufferRef buf;
        floatData = [NSMutableData new];
        while ((buf = [trackOutput copyNextSampleBuffer])) {
            
            AudioBufferList audioBufferList;
            CMBlockBufferRef blockBuffer;
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(buf,
                                                                    NULL,
                                                                    &audioBufferList,
                                                                    sizeof(audioBufferList),
                                                                    NULL,
                                                                    NULL,
                                                                    0,
                                                                    &blockBuffer);
            
            AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
            Float32 *frame = (Float32*)audioBuffer.mData;
            [floatData appendBytes:frame length:audioBuffer.mDataByteSize];
            
            CFRelease(blockBuffer);
            CFRelease(buf);
            blockBuffer = NULL;
            buf = NULL;
        }
        
        [sampleReader cancelReading];
        
        _sampleData = [NSData dataWithData:floatData];
        
        return YES;
    } else {
        _sampleData = nil;
        return NO;
    }
}

-(id)initWithAsset:(AVAsset *)asset
             track:(AVAssetTrack *)track
         timeRange:(CMTimeRange)range {
    self = [super init];
    if (self) {
        if (![self _loadDataWithAsset:asset
                          track:track
                         inTimeRange:range]) {
            self = nil;
        }
    }
    return self;
}

-(NSRange)copySamples:(float **)outSamples inRange:(NSRange)range {
    
    NSRange maxRange = NSMakeRange(0, [self samplesLength]);
    NSRange retRange = NSIntersectionRange(range, maxRange);
    
    *outSamples = calloc(retRange.length, sizeof(float));
    float *src = (float *)[_sampleData bytes];
    
    memcpy(*outSamples, src + retRange.location, retRange.length * sizeof(float));
    
    return retRange;
}

-(NSUInteger)samplesLength {
    return [_sampleData length] / sizeof(float);
}


@end


@implementation JHSampleDataProvider


+(id)providerWithAsset:(AVAsset *)asset
             track:(AVAssetTrack *)track
         timeRange:(CMTimeRange)timeRange {
    return [[_JHAVAssetSampleDataProvider alloc] initWithAsset:asset
                                                         track:track
                                                     timeRange:timeRange];

}

+(id)providerWithAsset:(AVAsset *)asset
                 track:(AVAssetTrack *)track {
    return [[_JHAVAssetSampleDataProvider alloc] initWithAsset:asset
                                                         track:track
                                                     timeRange:CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)];
    
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

-(NSRange)copySamples:(float **)outSamples inRange:(NSRange)range {
    return NSMakeRange(NSNotFound, 0);
}

-(NSUInteger)samplesLength {
    return 0;
}


@end
