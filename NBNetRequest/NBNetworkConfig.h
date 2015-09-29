//
//  YTKNetworkConfig.h
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
#import "NBBaseNetRequest.h"
#import "NBNetRequestModel.h"
@protocol NBUrlFilterProtocol <NSObject>
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(NBBaseNetRequest *)request;
@end

@protocol NBCacheDirPathFilterProtocol <NSObject>
- (NSString *)filterCacheDirPath:(NSString *)originPath withRequestModel:(NBNetRequestModel *)requestModel;
@end

@interface NBNetworkConfig : NSObject

+ (NBNetworkConfig *)sharedInstance;

@property (strong, nonatomic) NSString *baseUrl;
@property (strong, nonatomic) NSString *cdnUrl;
@property (strong, nonatomic, readonly) NSArray *urlFilters;
@property (strong, nonatomic, readonly) NSArray *cacheDirPathFilters;
@property (assign, nonatomic) BOOL isLogin;
@property (strong, nonatomic) NSString *responseCodeKey;
@property (strong, nonatomic) NSString *responseDataKey;

- (void)addUrlFilter:(id<NBUrlFilterProtocol>)filter;
- (void)addCacheDirPathFilter:(id <NBCacheDirPathFilterProtocol>)filter;

@end
