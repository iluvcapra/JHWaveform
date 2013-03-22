//
//  JHSampleDataTransformer.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/22/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataMonoizer.h"
//#import "Accelerate/Accelerate.h"

@implementation JHSampleDataMonoizer

-(id)initWithSourceProvider:(JHSampleDataProvider *)provider {
    self = [super init];
    if (self) {
        NSAssert(provider != nil,@"provider argument may not be nil");
        _sourceProvider = provider;
    }
    return self;
}

-(NSUInteger)samplesPerFrame {
    return 1;
}

-(double)framesPerSecond {
    return [_sourceProvider framesPerSecond];
}


-(NSUInteger)framesLength {
    return [_sourceProvider framesLength];
}

-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock {

    NSUInteger spf  = [_sourceProvider samplesPerFrame];
    NSRange possibleRange = NSIntersectionRange(aRange,
                                                NSMakeRange(0,[_sourceProvider framesLength])) ;
    
    [_sourceProvider yieldFramesInRange:possibleRange
                                toBlock:^(float *samples, NSRange outRange) {
                                    float *result = NULL;
                                    
                                    result = calloc(outRange.length, sizeof(float));
                                    
                                    if (result) {
                                        NSUInteger i,j;
                                        for (i = 0; i < spf; i++) {
                                            for (j = 0; j < outRange.length; j++) {
                                                result[j] += samples[j * spf + i];
                                            }
                                        }
                                        yieldBlock(result, outRange);
                                        free(result);
                                    } else {
                                        yieldBlock(NULL, NSMakeRange(0, 0));
                                    }
                                    

                                }];
    

    
}

@end
