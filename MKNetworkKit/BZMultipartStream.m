//
//  BZMultipartStream.m
//  Pods
//
//  Created by Mason Glaves on 7/5/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import "BZMultipartStream.h"
#import <MobileCoreServices/UTType.h>
#import <objc/runtime.h>

#define kBZDefaultMimeType @"application/octet-stream"
#define kBZFieldFormat     @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@"
#define kBZFieldFooter     @"\r\n"

#define kBZDataFormat      @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n"
#define kBZFooterFormat    @"--%@--\r\n"

@interface NSString (BZMimeType)
- (NSString*) mimeType;
@end

@implementation NSString (BZMimeType)

- (NSString*) mimeType {
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[self pathExtension], NULL);
    if (uti) {
        CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        CFRelease(uti);
        if (mime) {
            NSString* type = [NSString stringWithString:(__bridge NSString*)mime];
            CFRelease(mime);
            return type;
        }
    }
    return kBZDefaultMimeType;
}

@end

@implementation BZMultipartStream {
    NSMutableDictionary* properties;

    NSStringEncoding encoding;
    NSData* footer;
    NSData* fieldend;
    NSMutableData* fields;
    NSMutableArray* streams;

    NSUInteger index;
    unsigned long sent;
}

@synthesize boundary, length, streamStatus, streamError;

- (id) initWithEncoding:(NSStringEncoding)enc {
    if (self = [super init]) {
        properties = [[NSMutableDictionary alloc] init];

        encoding = enc;
        boundary = [[NSProcessInfo processInfo] globallyUniqueString];
        footer   = [[NSString stringWithFormat:kBZFooterFormat, boundary] dataUsingEncoding:encoding];
        streams  = [[NSMutableArray alloc] init];
        fields   = [[NSMutableData alloc] init];
        fieldend = [kBZFieldFooter dataUsingEncoding:encoding];

        length   = footer.length;
        sent     = 0;
        index    = 0;
    }
    return self;
}

- (void) appendFields:(NSDictionary*)formFields {
    [formFields enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSData class]]) {
            [self appendData:value forKey:key withMimeType:kBZDefaultMimeType];
        } else {
            [self appendField:value forKey:key];
        }
    }];
}

- (void) appendField:(NSData*)value forKey:(NSString*)key {
    NSString* formatted = [NSString stringWithFormat:kBZFieldFormat, boundary, key, value];
    NSData* encoded = [formatted dataUsingEncoding:encoding];

    [fields appendData:encoded];
    [fields appendData:fieldend];

    length += encoded.length + fieldend.length;
}

- (void) appendData:(NSData*)data forKey:(NSString*)key withMimeType:(NSString*)mime {
    NSString* formatted = [NSString stringWithFormat:kBZDataFormat, boundary, key, key, mime ? mime : kBZDefaultMimeType];
    NSData* encoded = [formatted dataUsingEncoding:encoding];

    [streams addObject:[[NSInputStream alloc] initWithData:encoded]];
    [streams addObject:[[NSInputStream alloc] initWithData:data]];
    [streams addObject:[[NSInputStream alloc] initWithData:fieldend]];

    length += encoded.length + data.length + fieldend.length;
}

- (void) appendFile:(NSString*)path forKey:(NSString*)key withMimeType:(NSString*)mime {
    NSString* formatted = [NSString stringWithFormat:kBZDataFormat, boundary, key, [path lastPathComponent], mime ? mime : [path mimeType]];
    NSData* encoded = [formatted dataUsingEncoding:encoding];

    [streams addObject:[[NSInputStream alloc] initWithData:encoded]];
    [streams addObject:[[NSInputStream alloc] initWithFileAtPath:path]];
    [streams addObject:[[NSInputStream alloc] initWithData:fieldend]];

    length += encoded.length + [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL] fileSize] + fieldend.length;
}

- (NSInputStream*) currentStream {
    if (index > streams.count) {
        @throw @"This probably shouldn't happen";
    }

    NSInputStream* stream = [streams objectAtIndex:index];

    if (stream.streamStatus == NSStreamStatusNotOpen) {
        [stream open];
    }

    if (stream.streamStatus == NSStreamStatusAtEnd) {
        [stream close];
        index++;
        stream = [self currentStream];
    }

    return stream;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxlen {
    streamStatus = NSStreamStatusReading;

    if (index >= [streams count]) {
        streamStatus = NSStreamStatusAtEnd;
        return 0;
    }

    NSInputStream* stream = [self currentStream];

    int read = 0;
    while ((read = [stream read:buffer maxLength:maxlen]) == 0) {
        stream = [self currentStream];
    }
    sent += read;
    
    DLog(@"%@ (read %d bytes on stream %d/%d)", self, read, index, [streams count]);

    if (sent >= length) {
        streamStatus = NSStreamStatusAtEnd;
    }

    return read;
}

- (BOOL) setCFClientFlags:(CFOptionFlags)flgs callback:(CFReadStreamClientCallBack)cb context:(CFStreamClientContext*)ctx { return NO; }
- (void) scheduleInCFRunLoop:(CFRunLoopRef)loop forMode:(CFStringRef)mode {}
- (void) unscheduleFromCFRunLoop:(CFRunLoopRef)loop forMode:(CFStringRef)mode {}

+ (BOOL) resolveInstanceMethod:(SEL) selector {
    NSString * name = NSStringFromSelector(selector);
    if ([name hasPrefix:@"_"]) {
        Method method = class_getInstanceMethod(self, NSSelectorFromString([name substringFromIndex:1]));
        if (method) {
            class_addMethod(self, selector, method_getImplementation(method), method_getTypeEncoding(method));
            return YES;
        }
    }
    return [super resolveInstanceMethod:selector];
}

- (BOOL) hasBytesAvailable { return sent < length; }
- (void) close { streamStatus = NSStreamStatusClosed; }
- (void) open {
    if (streamStatus) { @throw @"Stream is already open!"; }
    streamStatus = NSStreamStatusOpening;
    if (fields.length) {
        [streams insertObject:[[NSInputStream alloc] initWithData:fields] atIndex:0];
    }
    [streams addObject:[[NSInputStream alloc] initWithData:footer]];
    streamStatus = NSStreamStatusOpen;
}

- (NSString*) description {
    return [[NSString alloc] initWithFormat:@"<%p> %lu/%lu kB", self, sent / 1000, length / 1000];
}

@end

