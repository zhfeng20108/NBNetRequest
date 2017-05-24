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

@interface NBBaseNetRequest()

@property (strong, nonatomic) id cacheJson;
@property (nonatomic, strong) id responseJSONObject;

@end


@implementation NBBaseNetRequest{
    BOOL _dataFromCache;
}


/// for subclasses to overwrite
- (void)requestCompleteFilter {
    [self saveJsonResponseToCacheFile:[self responseJSONObject]];
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
        if (self.sessionTask.error) {
            return NO;
        }
        return YES;
    } else {
        return NO;
    }
}

/// append self to request queue
- (void)startRequest {
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

+ (id)startWithRequestModel:(NBBaseNetRequestModel *)requestModel
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
    if ([responseObject isKindOfClass:[NSData class]]) {
        _responseJSONObject = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:NULL];
    } else {
        _responseJSONObject = responseObject;
    }
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
        NSString *key = self.responseDataKey;
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

#pragma mark - cache
- (void)start {
    if (self.requestModel.refreshCache) {
        [self startRequest];
        return;
    }
    if (!self.requestModel.useCache) {
        [self startRequest];
        return;
    }
    
    // check cache time
    if ([self.requestModel cacheTimeInSeconds] < 0) {
        [self startRequest];
        return;
    }
    
    // check cache version
    long long cacheVersionFileContent = [self.requestModel cacheVersionFileContent];
    if (cacheVersionFileContent != [self.requestModel cacheVersion]) {
        [self startRequest];
        return;
    }
    
    // check cache existance
    NSString *path = [self.requestModel cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
        [self startRequest];
        return;
    }
    
    // check cache time
    int seconds = [self.requestModel cacheFileDuration:path];
    if (seconds < 0 || seconds > [self.requestModel cacheTimeInSeconds]) {
        [self startRequest];
        return;
    }
    
    // load cache
    _cacheJson = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (_cacheJson == nil) {
        [self startRequest];
        return;
    }
    
    _dataFromCache = YES;
    [self requestCompleteFilter];
    NBBaseNetRequest *strongSelf = self;
    [strongSelf.delegate requestFinished:strongSelf];
    if (strongSelf.successCompletionBlock) {
        strongSelf.successCompletionBlock(strongSelf);
    }
    [strongSelf clearCompletionBlock];
}

/// 清除缓存
- (void)emptyCache
{
    if (_cacheJson) {
        _cacheJson = nil;
    }
    NSString *path = [self.requestModel cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil] == YES) {
        [fileManager removeItemAtPath:path error:NULL];
    }
    
    NSString *versionPath = [self.requestModel cacheVersionFilePath];
    if ([fileManager fileExistsAtPath:versionPath isDirectory:nil]) {
        [fileManager removeItemAtPath:versionPath error:NULL];
    }
}


- (void)startWithoutCache {
    [self startRequest];
}

- (id)cacheJson {
    if (_cacheJson) {
        return _cacheJson;
    } else {
        NSString *path = [self.requestModel cacheFilePath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path isDirectory:nil] == YES) {
            _cacheJson = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        }
        return _cacheJson;
    }
}

- (BOOL)isDataFromCache {
    return _dataFromCache;
}

- (id)responseJSONObject {
    if (_cacheJson) {
        return _cacheJson;
    } else {
        return _responseJSONObject;
    }
}

#pragma mark - Network Request Delegate

// 手动将其他请求的JsonResponse写入该请求的缓存
// 比如AddNoteApi, UpdateNoteApi都会获得Note，且其与GetNoteApi共享缓存，可以通过这个接口写入GetNoteApi缓存
- (void)saveJsonResponseToCacheFile:(id)jsonResponse {
    if (self.requestModel.useCache && [self.requestModel cacheTimeInSeconds] > 0 && ![self isDataFromCache]) {
        NSDictionary *json = jsonResponse;
        if (json != nil) {
            [NSKeyedArchiver archiveRootObject:json toFile:[self.requestModel cacheFilePath]];
            [NSKeyedArchiver archiveRootObject:@([self.requestModel cacheVersion]) toFile:[self.requestModel cacheVersionFilePath]];
        }
    }
}


@end
