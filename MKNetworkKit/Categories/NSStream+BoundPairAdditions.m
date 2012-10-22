//
//  NSStream+BoundPairAdditions.m
//  Reproduce
//
//  Created by Blazing Pair on 9/6/12.
//  Copyright (c) 2012 Blazing Pair. All rights reserved.
//

#import "NSStream+BoundPairAdditions.h"

@implementation NSStream (BoundPairAdditions)

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize {
    NSParameterAssert(inputStreamPtr);
    NSParameterAssert(outputStreamPtr);

    CFReadStreamRef     readStream = NULL;
    CFWriteStreamRef    writeStream = NULL;
    
    CFStreamCreateBoundPair(NULL, &readStream, &writeStream, (CFIndex) bufferSize);
    
    *inputStreamPtr  = CFBridgingRelease(readStream);
    *outputStreamPtr = CFBridgingRelease(writeStream);
}
@end
