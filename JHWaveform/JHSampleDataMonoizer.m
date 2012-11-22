//
//  JHSampleDataTransformer.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/22/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataMonoizer.h"
#import "Accelerate/Accelerate.h"

@implementation JHSampleDataMonoizer

-(id)initWithSourceProvider:(JHSampleDataProvider *)provider {
    self = [super init];
    if (self) {
        NSAssert(provider != nil,@"provider argument may not be nil");
        _sourceProvider = provider;
        _samplesPerFrame = 1;
        _framesPerSecond = [provider framesPerSecond];
    }
    return self;
}

-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock{

    __block float *result = NULL;
    __block NSRange retRange;
    [_sourceProvider yieldFramesInRange:aRange
                                toBlock:^(float *samples, NSRange outRange) {
                                    retRange = outRange;
                                    result = calloc(outRange.length, sizeof(float));
                                    
                                    NSUInteger i;
                                    for (i = 0; i < [_sourceProvider samplesPerFrame]; i++) {
                                        vDSP_vadd(result,
                                                  1,
                                                  samples + i,
                                                  [_sourceProvider samplesPerFrame],
                                                  result,
                                                  1,
                                                  outRange.length);
                                    }
                                }];
    
    yieldBlock(result, retRange);
    free(result);
    
}

-(NSUInteger)framesLength {
    return [_sourceProvider framesLength];
}

@end
