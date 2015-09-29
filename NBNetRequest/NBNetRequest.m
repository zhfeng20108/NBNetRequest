//
//  YTKRequest.m
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

#import "NBNetworkConfig.h"
#import "NBNetRequest.h"
#import "NBNetworkPrivate.h"

@interface NBNetRequest()

@property (strong, nonatomic) id cacheJson;

@end

@implementation NBNetRequest {
    BOOL _dataFromCache;
}

- (void)start {
    if (!self.requestModel.useCache) {
        [super start];
        return;
    }

    // check cache time
    if ([self.requestModel cacheTimeInSeconds] < 0) {
        [super start];
        return;
    }

    // check cache version
    long long cacheVersionFileContent = [self.requestModel cacheVersionFileContent];
    if (cacheVersionFileContent != [self.requestModel cacheVersion]) {
        [super start];
        return;
    }

    // check cache existance
    NSString *path = [self.requestModel cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
        [super start];
        return;
    }

    // check cache time
    int seconds = [self.requestModel cacheFileDuration:path];
    if (seconds < 0 || seconds > [self.requestModel cacheTimeInSeconds]) {
        [super start];
        return;
    }

    // load cache
    _cacheJson = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (_cacheJson == nil) {
        [super start];
        return;
    }

    _dataFromCache = YES;
    [self requestCompleteFilter];
    NBNetRequest *strongSelf = self;
    [strongSelf.delegate requestFinished:strongSelf];
    if (strongSelf.successCompletionBlock) {
        strongSelf.successCompletionBlock(strongSelf);
    }
    [strongSelf clearCompletionBlock];
}

- (void)startWithoutCache {
    [super start];
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
        return [super responseJSONObject];
    }
}

#pragma mark - Network Request Delegate

- (void)requestCompleteFilter {
    [super requestCompleteFilter];
    [self saveJsonResponseToCacheFile:[super responseJSONObject]];
}

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
