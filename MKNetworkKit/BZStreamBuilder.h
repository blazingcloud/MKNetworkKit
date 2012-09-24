//
//  BZStreamBuilder.h
//  Pods
//
//  Created by Mason on 9/6/12.
//
//

#import <Foundation/Foundation.h>

@interface BZStreamBuilder : NSObject

@property (nonatomic, strong, readonly) NSString* boundary;
@property (nonatomic, strong, readonly) NSString* tmpfile;
@property (nonatomic, assign, readonly) unsigned long long length;
@property (nonatomic, strong, readonly) NSInputStream* stream;

- (id) initWithEncoding:(NSStringEncoding)enc;

- (void) appendFields:(NSDictionary*)fields;
- (void) appendField:(NSString*)value forKey:(NSString*)key;
- (void) appendData:(NSData*)value forKey:(NSString*)key withMimeType:(NSString*)mime;
- (void) appendFile:(NSString*)path forKey:(NSString*)key withMimeType:(NSString*)mime;

- (void) build;


@end
