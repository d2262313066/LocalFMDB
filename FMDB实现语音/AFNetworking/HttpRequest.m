//
//  HttpRequest.m
//
//  Created by wuyiguang on 15/9/26.
//  Copyright © 2015年 YG. All rights reserved.
//
//  AFNetworking二次封装


#import "HttpRequest.h"
#import "AFNetworking.h"

static HttpRequest *_single = nil;

@interface HttpRequest ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation HttpRequest

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    //static class *manager = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _single = [super allocWithZone:zone];
        _single.manager = [AFHTTPSessionManager manager];

    });
    return _single;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
            }
    return self;
}


+ (NSSet *)setContentTypes
{
    return [NSSet setWithObjects:@"text/json", @"text/html", @"text/plain", @"image/gif", @"application/json", nil];
}

/**
 *  GET请求
 *
 *  @param urlString 请求时的url
 *  @param success   成功时的回调
 *  @param progess   进度回调
 *  @param failure   失败时的回调
 */
+ (void)GET:(NSString *)urlString paramas:(id)paramas success:(SuccessBlock)success progess:(ProgessBlock)progess failure:(FailureBlock)failure
{
    // 判断url是否为空
    if (!urlString)
    {
        return;
    }
    
    _single = [[HttpRequest alloc] init];

    // 设置AFNetworking的数据类型
    _single.manager.responseSerializer.acceptableContentTypes = [self setContentTypes];
    // 发送GET请求
    [_single.manager GET:urlString parameters:paramas progress:^(NSProgress * _Nonnull downloadProgress) {
        
        // 进度回调
        if (progess)
        {
            progess(downloadProgress);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // 成功回调
        if (success)
        {
            success(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
    {
        // 失败回调
        if (failure)
        {
            failure(error);
        }
    }];
}

/**
 *  POST请求
 *
 *  @param urlString 请求时的url
 *  @param success   成功时的回调
 *  @param failure   失败时的回调
 */
+ (void)POST:(NSString *)urlString paramas:(id)paramas success:(SuccessBlock)success failure:(FailureBlock)failure
{
    // 判断url是否为空
    if (!urlString)
    {
        return;
    }

    _single = [[HttpRequest alloc] init];

    _single.manager.responseSerializer.acceptableContentTypes = [self setContentTypes];
    
    // 请求参数以json格式传过去
    _single.manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [_single.manager POST:urlString parameters:paramas progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (success)
        {
            success(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (failure)
        {
            failure(error);
        }
    }];
}

@end
