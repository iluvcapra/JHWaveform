//
//  JHSampleDataProvider2.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/21/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataProvider.h"
#import "_JHAVAssetSampleDataProvider.h"
#import "_JHFVecSampleDataProvider.h"

@implementation JHSampleDataProvider

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

# pragma mark Providers

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

+(id)providerWithFVec:(fvec_t *)vector
      framesPerSecond:(NSUInteger)sampleRate
         freeWhenDone:(BOOL)freeWhenDone {
    return [[_JHFVecSampleDataProvider alloc] initWithFVec:vector
                                           framesPerSecond:sampleRate
                                              freeWhenDone:freeWhenDone];
}


-(void)yieldSamplesOnChannel:(NSUInteger)chan
               inFrameRange:(NSRange)aRange
                    toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock {
    
    NSUInteger spf = [self samplesPerFrame];
    if (spf == 1) {
        [self yieldFramesInRange:aRange toBlock:yieldBlock];
    } else if ([self samplesPerFrame] > chan) {
        yieldBlock(NULL, NSMakeRange(NSNotFound, 0));
    } else {
        
        [self yieldFramesInRange:aRange toBlock:^(float *samples, NSRange outRange) {
            float *yieldPtr = calloc(outRange.length, sizeof(float));
            
            NSUInteger i;
            for (i = 0; i < outRange.length; i++) {
                yieldPtr[i] = samples[i*spf + chan];
            }
            yieldBlock(yieldPtr,outRange);
            free(yieldPtr);
        }];
    }
}

-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock {
    NSAssert(0, @"%s must be implemented by subclasses", sel_getName(_cmd));
}

-(NSUInteger)framesLength {
    NSAssert(0, @"%s must be implemented by subclasses",sel_getName(_cmd));
    return 0;
}

-(double)framesPerSecond {
    NSAssert(0, @"%s must be implemented by subclasses",sel_getName(_cmd));
    return 0.0f;
}

-(NSUInteger)samplesPerFrame {
    NSAssert(0, @"%s must be implemented by subclasses",sel_getName(_cmd));
    return 0.0f;
}

@end
