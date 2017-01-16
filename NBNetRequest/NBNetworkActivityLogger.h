//
//  NBNetworkActivityLogger.h
//  NBNetRequestDemo
//
//  Created by haha on 2017/1/16.
//  Copyright © 2017年 feng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NBHTTPRequestLoggerLevel) {
    NBHTTPRequestLoggerLevelOff     =0,
    NBHTTPRequestLoggerLevelDebug   =1,
    NBHTTPRequestLoggerLevelInfo    =2,
    NBHTTPRequestLoggerLevelWarn    =3,
    NBHTTPRequestLoggerLevelError   =4,
    NBHTTPRequestLoggerLevelFatal = NBHTTPRequestLoggerLevelOff,
};

@interface NBNetworkActivityLogger : NSObject
/**
 The level of logging detail. See "Logging Levels" for possible values. `AFLoggerLevelInfo` by default.
 */
@property (nonatomic, assign) NBHTTPRequestLoggerLevel level;

/**
 Omit requests which match the specified predicate, if provided. `nil` by default.
 
 @discussion Each notification has an associated `NSURLRequest`. To filter out request and response logging, such as all network activity made to a particular domain, this predicate can be set to match against the appropriate URL string pattern.
 */
@property (nonatomic, strong) NSPredicate *filterPredicate;

/**
 Returns the shared logger instance.
 */
+ (instancetype)sharedLogger;

/**
 Start logging requests and responses.
 */
- (void)startLogging;

/**
 Stop logging requests and responses.
 */
- (void)stopLogging;

/** This method could be overridden in subclasses to create custom http body
 */
- (NSString *)customHttpBody:(NSData *)data;

/** This method could be overridden in subclasses to create custom response object
 */
- (NSObject *)customResponseObject:(NSObject *)object;

@end
