//
//  YTKNetworkAgent.m
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

#import "NBNetworkAgent.h"
#import "NBNetworkConfig.h"
#import "NBNetworkPrivate.h"

@implementation NBNetworkAgent {
    AFHTTPSessionManager *_manager;
    NBNetworkConfig *_config;
    NSMutableDictionary *_requestsRecord;
}

+ (NBNetworkAgent *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _config = [NBNetworkConfig sharedInstance];
        _manager = [AFHTTPSessionManager manager];
        _requestsRecord = [NSMutableDictionary dictionary];
        _manager.operationQueue.maxConcurrentOperationCount = 4;
    }
    return self;
}

- (NSString *)buildRequestUrl:(NBBaseNetRequest *)request {
    NSString *detailUrl = [request.requestModel path];
    if ([detailUrl hasPrefix:@"http"]) {
        return detailUrl;
    }
    // filter url
    NSArray *filters = [_config urlFilters];
    for (id<NBUrlFilterProtocol> f in filters) {
        detailUrl = [f filterUrl:detailUrl withRequest:request];
    }

    NSString *baseUrl;
    if ([request.requestModel useCDN]) {
        if ([request.requestModel cdnUrl].length > 0) {
            baseUrl = [request.requestModel cdnUrl];
        } else {
            baseUrl = [_config cdnUrl];
        }
    } else {
        if ([request.requestModel baseUrl].length > 0) {
            baseUrl = [request.requestModel baseUrl];
        } else {
            baseUrl = [_config baseUrl];
        }
    }
    NSString * encodedStringUrl = [detailUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSString stringWithFormat:@"%@%@", baseUrl, encodedStringUrl?:@""];
}

- (void)addRequest:(NBBaseNetRequest *)request {
    NBNetRequestMethod method = [request.requestModel requestMethod];
    NSString *url = [self buildRequestUrl:request];
    id param = request.requestModel.requestArgument;
    AFConstructingBlock constructingBlock = [request.requestModel constructingBodyBlock];

    if (request.requestModel.requestSerializerType == NBNetRequestSerializerTypeHTTP) {
        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    else if (request.requestModel.requestSerializerType == NBNetRequestSerializerTypeJSON) {
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    else if (request.requestModel.requestSerializerType == NBNetRequestSerializerTypeURL) {
        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"text/json",@"text/javascript", nil];
    }
    
    _manager.requestSerializer.timeoutInterval = [request.requestModel requestTimeoutInterval];

    // if api need server username and password
    NSArray *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [_manager.requestSerializer setAuthorizationHeaderFieldWithUsername:(NSString *)authorizationHeaderFieldArray.firstObject
                                                                   password:(NSString *)authorizationHeaderFieldArray.lastObject];
    }
    
    // if api need add custom value to HTTPHeaderField
    NSDictionary *headerFieldValueDictionary = [request.requestModel requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (id httpHeaderField in headerFieldValueDictionary.allKeys) {
            id value = headerFieldValueDictionary[httpHeaderField];
            if ([httpHeaderField isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
                [_manager.requestSerializer setValue:(NSString *)value forHTTPHeaderField:(NSString *)httpHeaderField];
            } else {
                NBNetRequestLog(@"Error, class of key/value in headerFieldValueDictionary should be NSString.");
            }
        }
    }

    // if api build custom url request
    NSURLRequest *customUrlRequest= [request.requestModel buildCustomUrlRequest];
    if (customUrlRequest) {
        __block NSURLSessionDataTask *dataTask = [_manager dataTaskWithRequest:customUrlRequest completionHandler:^(NSURLResponse * __nonnull response, id __nonnull responseObject, NSError * __nonnull error) {
            if (error) {
                [self handleRequestResult:dataTask request:request error:error];
            } else {
                [self handleRequestResult:dataTask request:request responseObject:responseObject];
            }
        }];
        request.sessionTask = dataTask;
        // 使用resume方法启动任务
        [dataTask resume];
    } else {
        if (method == NBNetRequestMethodGet) {
            if (request.requestModel.resumableDownloadPath) {
                // add parameters to URL;
                NSString *filteredUrl = [NBNetworkPrivate urlStringWithOriginUrlString:url appendParameters:param];

                NSURLRequest *requestUrl = [NSURLRequest requestWithURL:[NSURL URLWithString:filteredUrl]];
                __block NSURLSessionDownloadTask *downloadTask = [_manager downloadTaskWithRequest:requestUrl
                                                                                  progress:nil
                                                                               destination:^ NSURL * __nonnull(NSURL * __nonnull url, NSURLResponse * __nonnull response) {
                                                                                   // 将下载文件保存在缓存路径中
                                                                                   return [NSURL fileURLWithPath:request.requestModel.resumableDownloadPath];
                                                                               } completionHandler:^ void(NSURLResponse * __nonnull response, NSURL * __nonnull url, NSError * __nonnull error) {
                                                                                   if (error) {
                                                                                       [self handleRequestResult:downloadTask request:request error:error];
                                                                                   } else {
                                                                                       [self handleRequestResult:downloadTask request:request responseObject:url];
                                                                                   }
                                                                               }];
//                [_manager setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
//                    float downloadPercentage = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
//                    NSLog(@"%f",downloadPercentage);
//                }];
                request.sessionTask = downloadTask;
                [downloadTask resume];
            } else {
                request.sessionTask = [_manager GET:url parameters:param success:^(NSURLSessionDataTask * __nonnull task, id __nonnull responseObject) {
                    [self handleRequestResult:task request:request responseObject:responseObject];
                } failure:^(NSURLSessionDataTask * __nonnull task, NSError * __nonnull error) {
                    [self handleRequestResult:task request:request error:error];
                }];
            }
        } else if (method == NBNetRequestMethodPost) {
            if (constructingBlock != nil) {
                request.sessionTask = [_manager POST:url parameters:param constructingBodyWithBlock:constructingBlock
                                                  success:^(NSURLSessionDataTask * __nonnull task, id __nonnull responseObject) {
                                                      [self handleRequestResult:task request:request responseObject:responseObject];
                } failure:^(NSURLSessionDataTask * __nonnull task, NSError * __nonnull error) {
                    [self handleRequestResult:task request:request error:error];
                }];
            } else {
                request.sessionTask = [_manager POST:url parameters:param success:^(NSURLSessionDataTask * __nonnull task, id __nonnull responseObject) {
                    [self handleRequestResult:task request:request responseObject:responseObject];
                }                                 failure:^(NSURLSessionDataTask * __nonnull task, NSError * __nonnull error) {
                    [self handleRequestResult:task request:request error:error];
                }];
            }
        } else if (method == NBNetRequestMethodHead) {
            request.sessionTask = [_manager HEAD:url parameters:param success:^(NSURLSessionDataTask * __nonnull task) {
                [self handleRequestResult:task request:request responseObject:nil];
            }                                 failure:^(NSURLSessionDataTask * __nonnull task, NSError * __nonnull error) {
                [self handleRequestResult:task request:request error:error];
            }];
        } else if (method == NBNetRequestMethodPut) {
            request.sessionTask = [_manager PUT:url parameters:param success:^(NSURLSessionDataTask * __nonnull task, id __nonnull responseObject) {
                [self handleRequestResult:task request:request responseObject:responseObject];
            }                                failure:^(NSURLSessionDataTask * __nonnull task, NSError * __nonnull error) {
                [self handleRequestResult:task request:request error:error];
            }];
        } else if (method == NBNetRequestMethodDelete) {
            request.sessionTask = [_manager DELETE:url parameters:param success:^(NSURLSessionDataTask * __nonnull task, id __nonnull responseObject) {
                [self handleRequestResult:task request:request responseObject:responseObject];
            }                                   failure:^(NSURLSessionDataTask * __nonnull task, NSError * __nonnull error) {
                [self handleRequestResult:task request:request error:error];
            }];
        } else if (method == NBNetRequestMethodPatch) {
            request.sessionTask = [_manager PATCH:url parameters:param success:^(NSURLSessionDataTask * __nonnull task, id __nonnull responseObject) {
                [self handleRequestResult:task request:request responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * __nonnull task, NSError * __nonnull error) {
                [self handleRequestResult:task request:request error:error];
            }];
        } else {
            NBNetRequestLog(@"Error, unsupport method type");
            return;
        }
    }

    NBNetRequestLog(@"Add request: %@", NSStringFromClass([request class]));
    [self addSessionTask:request];
}

- (void)cancelRequest:(NBBaseNetRequest *)request {
    [request.sessionTask cancel];
    [self removeSessionTask:request.sessionTask];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    NSDictionary *copyRecord = [_requestsRecord copy];
    for (NSString *key in copyRecord) {
        NBBaseNetRequest *request = copyRecord[key];
        [request stop];
    }
}

- (BOOL)checkResult:(NBBaseNetRequest *)request {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        return result;
    }
    id validator = [request jsonValidator];
    if (validator != nil) {
        id json = [request responseJSONObject];
        result = [NBNetworkPrivate checkJson:json withValidator:validator];
    }
    return result;
}
- (void)handleRequestResult:(NSURLSessionTask *)task request:(NBBaseNetRequest *)request error:(NSError *)error {
    [self handleRequestResult:task request:request responseObject:nil];
}
- (void)handleRequestResult:(NSURLSessionTask *)task request:(NBBaseNetRequest *)request responseObject:(id)responseObject {
    [request setResponseObject:responseObject];
    [self handleRequestResult:task];
}
- (void)handleRequestResult:(NSURLSessionTask *)task {
    NSString *key = [self requestHashKey:task];
    NBBaseNetRequest *request = _requestsRecord[key];
    NBNetRequestLog(@"Finished Request: %@", NSStringFromClass([request class]));
    if (request) {
        BOOL succeed = [self checkResult:request];
        if (succeed) {
            [request toggleAccessoriesWillStopCallBack];
            [request requestCompleteFilter];
            if (request.delegate != nil) {
                [request.delegate requestFinished:request];
            }
            if (request.successCompletionBlock) {
                request.successCompletionBlock(request);
            }
            [request toggleAccessoriesDidStopCallBack];
        } else {
            NBNetRequestLog(@"Request %@ failed, status code = %ld",
                     NSStringFromClass([request class]), (long)request.responseStatusCode);
            [request toggleAccessoriesWillStopCallBack];
            [request requestFailedFilter];
            if (request.delegate != nil) {
                [request.delegate requestFailed:request];
            }
            if (request.failureCompletionBlock) {
                request.failureCompletionBlock(request);
            }
            [request toggleAccessoriesDidStopCallBack];
        }
    }
    [self removeSessionTask:task];
    [request clearCompletionBlock];
}

- (NSString *)requestHashKey:(NSURLSessionTask *)task {
    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
    return key;
}

- (void)addSessionTask:(NBBaseNetRequest *)request {
    if (request.sessionTask != nil) {
        NSString *key = [self requestHashKey:request.sessionTask];
        @synchronized(self) {
            _requestsRecord[key] = request;
        }
    }
}

- (void)removeSessionTask:(NSURLSessionTask *)task {
    NSString *key = [self requestHashKey:task];
    @synchronized(self) {
        [_requestsRecord removeObjectForKey:key];
    }
    NBNetRequestLog(@"Request queue size = %lu", (unsigned long)[_requestsRecord count]);
}


@end
