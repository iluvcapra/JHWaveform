//
//  JHFVecSampleDataProvider.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/27/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "_JHFVecSampleDataProvider.h"

@implementation _JHFVecSampleDataProvider

-(id)initWithFVec:(fvec_t *)vector
framesPerSecond:(double)fps
     freeWhenDone:(BOOL)freeWhenDone {
    self = [super init];
    if (self) {
        NSAssert(vector != NULL, @"vector aregument must not be NULL");
        _freeWhenDone = freeWhenDone;
        _vector = vector;
        _framesPerSecond = fps;
    }
    return self;
}


-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock {
    
    NSRange maxRange = NSMakeRange(0, [self framesLength]);
    NSRange retRange = NSIntersectionRange(aRange, maxRange);
    
    float *interleaved = calloc(_vector->channels * retRange.length,
                                 sizeof(float));
    
    NSUInteger chan, offset;
    for (chan = 0; chan < _vector->channels; chan++) {
        for (offset = retRange.location; offset < retRange.length; offset++) {
            interleaved[offset * _vector->length + chan] = _vector->data[chan][offset];
        }
    }
    yieldBlock(interleaved,retRange);
    free(interleaved);
}

-(void)yieldSamplesOnChannel:(NSUInteger)chan
                inFrameRange:(NSRange)aRange
                     toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock {
    NSRange maxRange = NSMakeRange(0, [self framesLength]);
    NSRange retRange = NSIntersectionRange(aRange, maxRange);
    
    yieldBlock(_vector->data[chan],retRange);
    
}


-(NSUInteger)framesLength {
    return _vector->length;
}

-(double)framesPerSecond {
    return _framesPerSecond;
}

-(NSUInteger)samplesPerFrame {
    return _vector->channels;
}


@end
