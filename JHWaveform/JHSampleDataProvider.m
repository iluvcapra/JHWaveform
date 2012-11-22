//
//  JHSampleDataProvider2.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/21/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataProvider.h"
#import "_JHAVAssetSampleDataProvider.h"

@implementation JHSampleDataProvider

- (id)init {
    self = [super init];
    if (self) {
        _sampleDataBuffer = [NSData data];
        _framesPerSecond = 0;
        _samplesPerFrame = 0;
    }
    return self;
}

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

-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock{
    NSRange maxRange = NSMakeRange(0, [self framesLength]);
    NSRange retRange = NSIntersectionRange(aRange, maxRange);
    
    yieldBlock((float *)[_sampleDataBuffer bytes] +
               retRange.location * _samplesPerFrame,retRange);
    
}

-(void)yieldSampleOnChannel:(NSUInteger)chan
               inFrameRange:(NSRange)aRange
                    toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock {
    
    if (_samplesPerFrame == 1) {
        [self yieldFramesInRange:aRange toBlock:yieldBlock];
    } else if (_samplesPerFrame > chan) {
        yieldBlock(NULL, NSMakeRange(NSNotFound, 0));
    } else {
        
        [self yieldFramesInRange:aRange toBlock:^(float *samples, NSRange outRange) {
            float *yieldPtr = calloc(outRange.length, sizeof(double));
            
            NSUInteger i;
            for (i = 0; i < outRange.length; i++) {
                yieldPtr[i] = samples[i*_samplesPerFrame + chan];
            }
            yieldBlock(yieldPtr,outRange);
            free(yieldPtr);
        }];
    }
}

-(NSUInteger)framesLength {
    return [_sampleDataBuffer length] / (sizeof(float) * _samplesPerFrame);
}

-(double)framesPerSecond {
    return _framesPerSecond;
}

-(NSUInteger)samplesPerFrame {
    return _samplesPerFrame;
}
@end
