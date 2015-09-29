//
//  NBBaseNetRequest.m
//
//  Copyright (c) 2012-2014 YTKNetwork https://github.com/yuantiku
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NBBaseNetRequest.h"
#import "NBNetworkAgent.h"
#import "NBNetworkPrivate.h"
#import "NBNetworkConfig.h"

@implementation NBBaseNetRequest

/// for subclasses to overwrite
- (void)requestCompleteFilter {
}

- (void)requestFailedFilter {
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (id)jsonValidator {
    return nil;
}

- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    if (statusCode >= 200 && statusCode <=299) {
        return YES;
    } else {
        return NO;
    }
}

- (AFDownloadProgressBlock)resumableDownloadProgressBlock {
    return nil;
}

/// append self to request queue
- (void)start {
    if (self.requestModel.useAccount && ![[NBNetworkConfig sharedInstance] isLogin]) {
        [self toggleAccessoriesWillStopCallBack];
        [self requestFailedFilter];
        if (self.delegate != nil) {
            [self.delegate requestFailed:self];
        }
        if (self.failureCompletionBlock) {
            self.failureCompletionBlock(self);
        }
        [self toggleAccessoriesDidStopCallBack];
        
        [self clearCompletionBlock];

        return;
    }
    
    [self toggleAccessoriesWillStartCallBack];
    [[NBNetworkAgent sharedInstance] addRequest:self];
}

/// remove self from request queue
- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    self.delegate = nil;
    [[NBNetworkAgent sharedInstance] cancelRequest:self];
    [self toggleAccessoriesDidStopCallBack];
}

- (BOOL)isExecuting {
    return self.sessionTask.state == NSURLSessionTaskStateRunning;
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(NBBaseNetRequest *request))success
                                    failure:(void (^)(NBBaseNetRequest *request))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

+ (id)startWithRequestModel:(NBNetRequestModel *)requestModel
 completionBlockWithSuccess:(void (^)(NBBaseNetRequest *request))success
                    failure:(void (^)(NBBaseNetRequest *request))failure
{
    NBBaseNetRequest *request = [[[self class] alloc] init];
    request.requestModel = requestModel;
    [request startWithCompletionBlockWithSuccess:success failure:failure];
    return request;
}

- (void)setCompletionBlockWithSuccess:(void (^)(NBBaseNetRequest *request))success
                              failure:(void (^)(NBBaseNetRequest *request))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)setResponseObject:(id)responseObject
{
    if (_responseJSONObject == responseObject) {
        return;
    }
    _responseJSONObject = responseObject;
}

- (NSString *)responseString {
    if (![self responseJSONObject]) {
        return nil;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self responseJSONObject] options:NSJSONWritingPrettyPrinted error:NULL];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}

- (NSInteger)responseStatusCode {
    return ((NSHTTPURLResponse *)(self.sessionTask.response)).statusCode;
}

- (NSDictionary *)responseHeaders {
    return ((NSHTTPURLResponse *)self.sessionTask.response).allHeaderFields;
}

- (NSString *)responseResultCode
{
    id responseObj = [self responseJSONObject];
    if([responseObj isKindOfClass:[NSDictionary class]]) {
        NSString *key = self.responseCodeKey;
        if (!key) {
            key = [NBNetworkConfig sharedInstance].responseCodeKey;
        }
        return [NSString stringWithFormat:@"%@",key.length>0?[responseObj valueForKey:key]:responseObj];
    }
    return nil;
}

- (NSDictionary *)responseResultDictionary
{
    id responseObj = [self responseJSONObject];
    if([responseObj isKindOfClass:[NSDictionary class]]) {
        NSString *key = self.responseCodeKey;
        if (!key) {
            key = [NBNetworkConfig sharedInstance].responseDataKey;
        }
        NSDictionary *data = key.length>0?[responseObj valueForKey:key]:responseObj;
        if ([data isKindOfClass:[NSDictionary class]]) {
            return data;
        }
    }
    return nil;
}


#pragma mark - Request Accessoies

- (void)addAccessory:(id<NBNetRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end
