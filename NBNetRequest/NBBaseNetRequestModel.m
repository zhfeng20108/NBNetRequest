//
//  NBRequestModel.m
//  pengpeng
//
//  Created by ios_feng on 15/9/19.
//  Copyright © 2015年 AsiaInnovations. All rights reserved.
//

#import "NBBaseNetRequestModel.h"
#import "NBNetworkPrivate.h"
#import "NBNetworkConfig.h"
@implementation NBBaseNetRequestModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        //配置默认值
        _requestSerializerType = NBNetRequestSerializerTypeJSON;//默认json
        _requestMethod = NBNetRequestMethodPost;//默认post请求
        _requestTimeoutInterval = 60;// 请求的连接超时时间，默认为60秒
        _useAccount = YES;//是否需要帐号信息，默认需要帐号信息
        _useCDN = NO;
        _useCache = NO;
        _cacheTimeInSeconds = 86400;//默认缓存时间24小时
        self.priority = NSURLSessionTaskPriorityDefault;
    }
    return self;
}

+ (id)modelWithBaseUrl:(NSString *)baseUrl path:(NSString *)path
{
    return [[self class] modelWithBaseUrl:baseUrl path:path params:nil];
}

+ (id)modelWithBaseUrl:(NSString *)baseUrl path:(NSString *)path params:(id)params
{
    NBBaseNetRequestModel *model = [[[self class] alloc] init];
    model.baseUrl = baseUrl;
    model.path = path;
    model.requestArgument = params;
    [model addCommonParams];
    return model;
}

+ (id)modelWithPath:(NSString *)path
{
    return [[self class] modelWithBaseUrl:nil path:path params:nil];
}

+ (id)modelWithPath:(NSString *)path params:(id)params
{
    return [[self class] modelWithBaseUrl:nil path:path params:params];
}

+ (id)modelWithParams:(id)params
{
    return [[self class] modelWithBaseUrl:nil path:nil params:params];
}

- (AFConstructingBlock)constructingBodyBlock {
    return nil;
}

- (NSURLRequest *)buildCustomUrlRequest {
    return nil;
}

- (void)addCommonParams
{
    
}
#pragma mark - cache

/// 返回是否当前缓存过期
- (BOOL)isCacheExpired
{
    BOOL b = [self isCacheVersionExpired];
    if (b) return b;
    // check cache existance
    NSString *path = [self cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
        return YES;
    }
    
    // check cache time
    int seconds = [self cacheFileDuration:path];
    if (seconds < 0 || seconds > [self cacheTimeInSeconds]) {
        return YES;
    }
    return NO;
}

- (BOOL)isCacheVersionExpired {
    // check cache version
    long long cacheVersionFileContent = [self cacheVersionFileContent];
    if (cacheVersionFileContent != [self cacheVersion]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)cacheFilePath {
    NSString *cacheFileName = [self cacheFileName];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}

- (NSString *)cacheVersionFilePath {
    NSString *cacheVersionFileName = [NSString stringWithFormat:@"%@.version", [self cacheFileName]];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheVersionFileName];
    return path;
}


- (NSString *)cacheFileName {
    NSString *requestUrl = [self path];
    NSString *baseUrl = [NBNetworkConfig sharedInstance].baseUrl;
    id argument = [self cacheFileNameFilterForRequestArgument:[self requestArgument]];
    NSString *requestInfo = [NSString stringWithFormat:@"Method:%ld Host:%@ Url:%@ Argument:%@ AppVersion:%@ Sensitive:%@",
                             (long)[self requestMethod], baseUrl, requestUrl,
                             argument, [NBNetworkPrivate appVersionString], [self cacheSensitiveData]];
    NSString *cacheFileName = [NBNetworkPrivate md5StringFromString:requestInfo];
    return cacheFileName;
}

- (id)cacheFileNameFilterForRequestArgument:(id)argument {
    return argument;
}

- (long long)cacheVersionFileContent {
    NSString *path = [self cacheVersionFilePath];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSNumber *version = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        return [version longLongValue];
    } else {
        return 0;
    }
}


- (NSString *)cacheBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"LazyRequestCache"];
    
    // filter cache base path
    NSArray *filters = [[NBNetworkConfig sharedInstance] cacheDirPathFilters];
    if (filters.count > 0) {
        for (id<NBCacheDirPathFilterProtocol> f in filters) {
            path = [f filterCacheDirPath:path withRequestModel:self];
        }
    }
    
    [self checkDirectory:path];
    return path;
}

- (long long)cacheVersion {
    return 0;
}

- (id)cacheSensitiveData {
    return nil;
}

- (void)checkDirectory:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    } else {
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}

- (void)createBaseDirectoryAtPath:(NSString *)path {
    __autoreleasing NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                               attributes:nil error:&error];
    if (error) {
        NBNetRequestLog(@"create cache directory failed, error = %@", error);
    } else {
        [NBNetworkPrivate addDoNotBackupAttribute:path];
    }
}

- (int)cacheFileDuration:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // get file attribute
    NSError *attributesRetrievalError = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path
                                                             error:&attributesRetrievalError];
    if (!attributes) {
        NBNetRequestLog(@"Error get attributes for file at %@: %@", path, attributesRetrievalError);
        return -1;
    }
    int seconds = -[[attributes fileModificationDate] timeIntervalSinceNow];
    return seconds;
}


@end
