//
//  NBBaseNetRequest.h
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

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <AFDownloadRequestOperation/AFDownloadRequestOperation.h>
#import "NBBaseNetRequestModel.h"



typedef void (^AFDownloadProgressBlock)(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile);

@class NBBaseNetRequest;

@protocol NBNetRequestDelegate <NSObject>

- (void)requestFinished:(NBBaseNetRequest *)request;
- (void)requestFailed:(NBBaseNetRequest *)request;

@optional
- (void)clearRequest;

@end

@protocol NBNetRequestAccessory <NSObject>

@optional

- (void)requestWillStart:(id)request;
- (void)requestWillStop:(id)request;
- (void)requestDidStop:(id)request;

@end

@interface NBBaseNetRequest : NSObject

@property (nonatomic,strong) NBBaseNetRequestModel *requestModel;

/// Tag
@property (nonatomic) NSInteger tag;

/// User info
@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, strong) NSURLSessionTask *sessionTask;

/// request delegate object
@property (nonatomic, weak) id<NBNetRequestDelegate> delegate;


@property (nonatomic, strong, readonly) NSDictionary *responseHeaders;

@property (nonatomic, strong, readonly) NSString *responseString;

@property (nonatomic, readonly) NSInteger responseStatusCode;

@property (nonatomic, copy) void (^successCompletionBlock)(NBBaseNetRequest *);

@property (nonatomic, copy) void (^failureCompletionBlock)(NBBaseNetRequest *);

@property (nonatomic, strong) NSMutableArray *requestAccessories;

@property (nonatomic, strong, readonly) id responseResultCode;

@property (nonatomic, strong, readonly) id responseResultDictionary;

@property (strong, nonatomic) NSString *responseCodeKey;

@property (strong, nonatomic) NSString *responseDataKey;



/// append self to request queue
- (void)start;

/// remove self from request queue
- (void)stop;

- (BOOL)isExecuting;

/// block回调
- (void)startWithCompletionBlockWithSuccess:(void (^)(NBBaseNetRequest *request))success
                                    failure:(void (^)(NBBaseNetRequest *request))failure;

+ (id)startWithRequestModel:(NBBaseNetRequestModel *)requestModel
 completionBlockWithSuccess:(void (^)(NBBaseNetRequest *request))success
                    failure:(void (^)(NBBaseNetRequest *request))failure;

- (void)setCompletionBlockWithSuccess:(void (^)(NBBaseNetRequest *request))success
                              failure:(void (^)(NBBaseNetRequest *request))failure;

/// 把block置nil来打破循环引用
- (void)clearCompletionBlock;

/// Request Accessory，可以hook Request的start和stop
- (void)addAccessory:(id<NBNetRequestAccessory>)accessory;

/// 以下方法由子类继承来覆盖默认值

/// 请求成功的回调
- (void)requestCompleteFilter;

/// 请求失败的回调
- (void)requestFailedFilter;

/// 请求的Server用户名和密码
- (NSArray *)requestAuthorizationHeaderFieldArray;

/// 用于检查JSON是否合法的对象
- (id)jsonValidator;

/// 用于检查Status Code是否正常的方法
- (BOOL)statusCodeValidator;

/// 当需要断点续传时，获得下载进度的回调
- (AFDownloadProgressBlock)resumableDownloadProgressBlock;

- (void)setResponseObject:(id)responseObject;
- (id)responseJSONObject;



/// 返回当前缓存的对象
- (id)cacheJson;

/// 是否当前的数据从缓存获得
- (BOOL)isDataFromCache;

/// 清除缓存
- (void)emptyCache;

/// 强制更新缓存
- (void)startWithoutCache;

/// 手动将其他请求的JsonResponse写入该请求的缓存
- (void)saveJsonResponseToCacheFile:(id)jsonResponse;

@end
