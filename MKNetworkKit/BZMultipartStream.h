//
//  BZMultipartStream.h
//  Pods
//
//  Created by Mason Glaves on 7/5/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BZMultipartStream : NSInputStream

@property (nonatomic, assign, readonly) NSStreamStatus streamStatus;
@property (nonatomic, strong, readonly) NSError* streamError;
@property (nonatomic, strong, readonly) NSString* boundary;

@property (nonatomic, assign, readonly) unsigned long length;

- (id) initWithEncoding:(NSStringEncoding)enc;

- (void) appendFields:(NSDictionary*)fields;
- (void) appendField:(NSString*)value forKey:(NSString*)key;
- (void) appendData:(NSData*)value forKey:(NSString*)key withMimeType:(NSString*)mime;
- (void) appendFile:(NSString*)path forKey:(NSString*)key withMimeType:(NSString*)mime;

@end
