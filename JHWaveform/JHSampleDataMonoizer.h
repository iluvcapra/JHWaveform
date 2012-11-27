//
//  JHSampleDataTransformer.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/22/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleBuffer.h"

@interface JHSampleDataMonoizer : JHSampleBuffer {
    JHSampleBuffer *_sourceProvider;
}

-(id)initWithSourceProvider:(JHSampleBuffer *)provider;

@end