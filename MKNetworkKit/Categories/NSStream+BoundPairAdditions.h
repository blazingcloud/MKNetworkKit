//
//  NSStream+BoundPairAdditions.h
//  Reproduce
//
//  Created by Blazing Pair on 9/6/12.
//  Copyright (c) 2012 Blazing Pair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream (BoundPairAdditions)
+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize;
@end
