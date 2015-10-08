//
//  NBRequestModel.h
//  pengpeng
//
//  Created by ios_feng on 15/9/19.
//  Copyright © 2015年 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "AFDownloadRequestOperation.h"
typedef NS_ENUM(NSInteger , NBNetRequestMethod) {
    NBNetRequestMethodGet = 0,
    NBNetRequestMethodPost,
    NBNetRequestMethodHead,
    NBNetRequestMethodPut,
    NBNetRequestMethodDelete,
    NBNetRequestMethodPatch
};

typedef NS_ENUM(NSInteger , NBNetRequestSerializerType) {
    NBNetRequestSerializerTypeHTTP = 0,
    NBNetRequestSerializerTypeURL,
    NBNetRequestSerializerTypeJSON,
};
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);

@interface NBBaseNetRequestModel : NSObject

/// 请求的BaseURL
@property (nonatomic,strong) NSString *baseUrl;
/// 请求的URL
@property (nonatomic,strong) NSString *path;
/// 请求的CdnURL
@property (nonatomic,strong) NSString *cdnUrl;
/// 请求的参数列表
@property (nonatomic,strong) id requestArgument;
/// 在HTTP报头添加的自定义参数
@property (nonatomic,strong) NSDictionary *requestHeaderFieldValueDictionary;

/// 当需要断点续传时，指定续传的地址
@property (nonatomic,strong) NSString *resumableDownloadPath;
/// 是否使用CDN的host地址
@property (nonatomic,assign) BOOL useCDN;


@property (nonatomic,assign) BOOL useCache;
@property (nonatomic,assign) NSInteger cacheTimeInSeconds;

@property (nonatomic, assign) NBNetRequestMethod requestMethod;
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;
@property (nonatomic, assign) BOOL useAccount;

/// 请求的SerializerType
@property (nonatomic, assign) NBNetRequestSerializerType requestSerializerType;

/// 当POST的内容带有文件等富文本时使用
- (AFConstructingBlock)constructingBodyBlock;

/// 构建自定义的UrlRequest，
/// 若这个方法返回非nil对象，会忽略requestUrl, requestArgument, requestMethod, requestSerializerType
- (NSURLRequest *)buildCustomUrlRequest;

/// 追加公共参数，子类要去重载这个方法
- (void)addCommonParams;

/// 返回是否当前缓存过期
- (BOOL)isCacheExpired;
/// 返回是否当前缓存需要更新
- (BOOL)isCacheVersionExpired;

/// 用于在cache结果，计算cache文件名时，忽略掉一些指定的参数
- (id)cacheFileNameFilterForRequestArgument:(id)argument;

- (long long)cacheVersionFileContent;
- (NSString*)cacheFilePath;
- (int)cacheFileDuration:(NSString *)path;
- (NSString *)cacheVersionFilePath;
- (id)cacheSensitiveData;
/// For subclass to overwrite
- (long long)cacheVersion;

/// 创建请求model
+ (id)modelWithBaseUrl:(NSString *)baseUrl path:(NSString *)path;
/// 创建请求model
+ (id)modelWithBaseUrl:(NSString *)baseUrl path:(NSString *)path params:(id)params;
/// 创建请求model
+ (id)modelWithPath:(NSString *)path;
/// 创建请求model
+ (id)modelWithPath:(NSString *)path params:(id)params;
/// 创建请求model
+ (id)modelWithParams:(id)params;

@end
