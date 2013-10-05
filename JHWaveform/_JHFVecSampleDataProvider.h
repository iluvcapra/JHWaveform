//
//  JHFVecSampleDataProvider.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/27/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataProvider.h"

#ifndef AUBIO_H

typedef struct _fvec_t {
    UInt32 length;
    UInt32 channels;
    float **data;
} fvec_t;

#endif

@interface _JHFVecSampleDataProvider : JHSampleDataProvider {
    fvec_t *_vector;
    BOOL _freeWhenDone;
    double _framesPerSecond;
}

-(id)initWithFVec:(fvec_t *)vector
  framesPerSecond:(double)fps
     freeWhenDone:(BOOL)freeWhenDone;

@end
