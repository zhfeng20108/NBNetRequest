//
//  NBNetworkActivityLogger.m
//  NBNetRequestDemo
//
//  Created by haha on 2017/1/16.
//  Copyright © 2017年 feng. All rights reserved.
//

#import "NBNetworkActivityLogger.h"
#import "AFURLSessionManager.h"
#import <objc/runtime.h>

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    NSURLRequest *request = nil;
    if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        request = [[notification object] originalRequest];
    } else if ([[notification object] respondsToSelector:@selector(request)]) {
        request = [[notification object] request];
    }
    
    return request;
}

static NSError * AFNetworkErrorFromNotification(NSNotification *notification) {
    NSError *error = nil;
    if ([[notification object] isKindOfClass:[NSURLSessionTask class]]) {
        error = [(NSURLSessionTask *)[notification object] error];
        if (!error) {
            error = notification.userInfo[AFNetworkingTaskDidCompleteErrorKey];
        }
    }
    
    return error;
}


@implementation NBNetworkActivityLogger

+ (instancetype)sharedLogger {
    static NBNetworkActivityLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[self alloc] init];
    });
    
    return _sharedLogger;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.level = NBHTTPRequestLoggerLevelInfo;
    
    return self;
}

- (void)dealloc {
    [self stopLogging];
}

- (void)startLogging {
    [self stopLogging];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingTaskDidResumeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingTaskDidCompleteNotification object:nil];
}

- (void)stopLogging {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSNotification

static void * AFNetworkRequestStartDate = &AFNetworkRequestStartDate;

- (void)networkRequestDidStart:(NSNotification *)notification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURLRequest *request = AFNetworkRequestFromNotification(notification);
        
        if (!request) {
            return;
        }
        
        if (request && self.filterPredicate && [self.filterPredicate evaluateWithObject:request]) {
            return;
        }
        
        objc_setAssociatedObject(notification.object, AFNetworkRequestStartDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        NSString *body = nil;
        if ([request HTTPBody]) {
            NSString *b = [self customHttpBody:[request HTTPBody]];
            if (b) {
                body = b;
            } else {
                body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
            }
        }
        
        switch (self.level) {
            case NBHTTPRequestLoggerLevelDebug:
                NSLog(@"%@ '%@': %@ %@", [request HTTPMethod], [[request URL] absoluteString], [request allHTTPHeaderFields], body);
                break;
            case NBHTTPRequestLoggerLevelInfo:
                NSLog(@"%@ '%@'", [request HTTPMethod], [[request URL] absoluteString]);
                break;
            default:
                break;
        }
    });
}

- (void)networkRequestDidFinish:(NSNotification *)notification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURLRequest *request = AFNetworkRequestFromNotification(notification);
        NSURLResponse *response = [notification.object response];
        NSError *error = AFNetworkErrorFromNotification(notification);
        
        if (!request && !response) {
            return;
        }
        
        if (request && self.filterPredicate && [self.filterPredicate evaluateWithObject:request]) {
            return;
        }
        
        NSUInteger responseStatusCode = 0;
        NSDictionary *responseHeaderFields = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            responseStatusCode = (NSUInteger)[(NSHTTPURLResponse *)response statusCode];
            responseHeaderFields = [(NSHTTPURLResponse *)response allHeaderFields];
        }
        
        id responseObject = nil;
        if (notification.userInfo) {
            responseObject = notification.userInfo[AFNetworkingTaskDidCompleteSerializedResponseKey];
        }
        NSObject *responseObj = [self customResponseObject:responseObject];
        if(responseObj) {
            responseObject = responseObj;
        }
        
        NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:objc_getAssociatedObject(notification.object, AFNetworkRequestStartDate)];
        
        if (error) {
            switch (self.level) {
                case NBHTTPRequestLoggerLevelDebug:
                case NBHTTPRequestLoggerLevelInfo:
                case NBHTTPRequestLoggerLevelWarn:
                case NBHTTPRequestLoggerLevelError:
                    NSLog(@"[Error] %@ '%@' (%ld) [%.04f s]: %@", [request HTTPMethod], [[response URL] absoluteString], (long)responseStatusCode, elapsedTime, error);
                default:
                    break;
            }
        } else {
            switch (self.level) {
                case NBHTTPRequestLoggerLevelDebug:
                {
                    NSLog(@"%ld '%@' [%.04f s]: %@ %@", (long)responseStatusCode, [[response URL] absoluteString], elapsedTime, responseHeaderFields,responseObject);
                    break;
                }
                case NBHTTPRequestLoggerLevelInfo:
                    NSLog(@"%ld '%@' [%.04f s]", (long)responseStatusCode, [[response URL] absoluteString], elapsedTime);
                    break;
                default:
                    break;
            }
        }
    });
}

#pragma mark - Override Methods

- (NSString *)customHttpBody:(NSData *)data {
    return nil;
}

- (NSObject *)customResponseObject:(NSObject *)object {
    return nil;
}


@end
