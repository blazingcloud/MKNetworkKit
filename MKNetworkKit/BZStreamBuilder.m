//
//  BZStreamBuilder.m
//  Pods
//
//  Created by Mason on 9/6/12.
//
//

#import "BZStreamBuilder.h"
#import <MobileCoreServices/UTType.h>

#define kBZBUFFER_SIZE 1024 * 32

#define kBZDefaultMimeType @"application/octet-stream"

#define kBZFieldFormat     @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@"
#define kBZFieldFooter     @"\r\n"

#define kBZDataFormat      @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n"

#define kBZFooterFormat    @"--%@--\r\n"

@interface NSString (BZMimeType)
- (NSString*) mimeType;
- (unsigned long long) fileSize;
@end

@implementation NSString (BZMimeType)

- (NSString*) mimeType {
    CFStringRef tag = (__bridge CFStringRef)[self pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, tag, NULL);
    if (uti) {
        NSString *mime = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        CFRelease(uti);
        if (mime) {
            return mime;
        }
    }
    return kBZDefaultMimeType;
}

- (unsigned long long) fileSize {
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:self error:NULL] fileSize];
}

@end

@implementation BZStreamBuilder {
    
    NSStringEncoding encoding;
    
    NSFileHandle* output;
    
    NSData* footer;
    NSData* fieldend;
    NSMutableData* fields;
        
}

- (id) initWithEncoding:(NSStringEncoding)enc {
    if (self = [super init]) {
        encoding  = enc;
        _boundary = [[NSProcessInfo processInfo] globallyUniqueString];
        
        footer    = [[NSString stringWithFormat:kBZFooterFormat, _boundary] dataUsingEncoding:encoding];
        fields    = [[NSMutableData alloc] init];
        fieldend  = [kBZFieldFooter dataUsingEncoding:encoding];
        
        _tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:_boundary];
        
        if (![[NSFileManager defaultManager] createFileAtPath:_tmpfile contents:nil attributes:nil]) {
            
        }
        output    = [NSFileHandle fileHandleForWritingAtPath:_tmpfile];

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
    NSString* formatted = [NSString stringWithFormat:kBZFieldFormat, _boundary, key, value];
    NSData* header = [formatted dataUsingEncoding:encoding];
        
    [output writeData:header];
    [output writeData:fieldend];    
}

- (void) appendData:(NSData*)data forKey:(NSString*)key withMimeType:(NSString*)mime {
    NSString* formatted = [NSString stringWithFormat:kBZDataFormat, _boundary, key, key, mime ? mime : kBZDefaultMimeType];
    NSData* header = [formatted dataUsingEncoding:encoding];
    
    [output writeData:header];
    [output writeData:data];
    [output writeData:fieldend];
}

- (void) appendFile:(NSString*)path forKey:(NSString*)key withMimeType:(NSString*)mime {
    NSString* formatted = [NSString stringWithFormat:kBZDataFormat, _boundary, key, [path lastPathComponent], mime ? mime : [path mimeType]];
    NSData* header = [formatted dataUsingEncoding:encoding];
    [output writeData:header];
        
    unsigned long long size = [path fileSize];
    
    NSFileHandle* input = [NSFileHandle fileHandleForReadingAtPath:path];
        
    for (unsigned long long i = 0; i < size; i += kBZBUFFER_SIZE) {
        [output writeData:[input readDataOfLength:kBZBUFFER_SIZE]];
    }
    [input closeFile];
    [output writeData:fieldend];
}

- (void) build {
    [output writeData:footer];
    [output closeFile];
}

- (unsigned long long) length {
    return [_tmpfile fileSize];
}

- (NSInputStream*) stream {
    return [NSInputStream inputStreamWithFileAtPath:_tmpfile];
}

- (void) dealloc {
    [[NSFileManager defaultManager] removeItemAtPath:_tmpfile error:NULL];
}

@end
