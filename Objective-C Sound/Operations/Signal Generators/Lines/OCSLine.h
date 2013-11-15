//
//  OCSLine.h
//  Objective-C Sound
//
//  Created by Adam Boulanger on 6/7/12.
//  Copyright (c) 2012 Hear For Yourself. All rights reserved.
//

#import "OCSAudio.h"
#import "OCSParameter+Operation.h"

/**
 Creates a line that extends from a starting to a second point over the given 
 time duration.  After that duration, the line continues at the same slope until
 the note event ends.  Can be an audio signal or control rate parameter.
 */

@interface OCSLine : OCSAudio

/// Initialize a linear transition from one value to another over specified time.
/// @param startingValue Value to start the line from.
/// @param endingValue   Value to end the line at.
/// @param duration      Duration of linear transition in seconds.
/// @return An opcode to perform a linear transition over a given duration.
- (instancetype)initFromValue:(OCSConstant *)startingValue
            toValue:(OCSConstant *)endingValue
           duration:(OCSConstant *)duration;
    

@end
