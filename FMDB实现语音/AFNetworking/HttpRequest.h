//
//  HttpRequest.h
//
//  Created by wuyiguang on 15/9/26.
//  Copyright © 2015年 YG. All rights reserved.
//
//  AFNetworking二次封装


#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class HttpRequest;

//成功时的回调
typedef void(^SuccessBlock)(id responseObject);

//进度的回调
typedef void(^ProgessBlock)(NSProgress *progess);

//失败时的回调
typedef void(^FailureBlock)(NSError *error);

@interface HttpRequest : NSObject

/**
 *  GET请求
 *
 *  @param urlString 请求时的url
 *  @param success   成功时的回调
 *  @param progess   进度回调
 *  @param failure   失败时的回调
 */
+ (void)GET:(NSString *)urlString paramas:(id)paramas success:(SuccessBlock)success progess:(ProgessBlock)progess failure:(FailureBlock)failure;

/**
 *  POST请求
 *
 *  @param urlString 请求时的url
 *  @param success   成功时的回调
 *  @param failure   失败时的回调
 */
+ (void)POST:(NSString *)urlString paramas:(id)paramas success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
