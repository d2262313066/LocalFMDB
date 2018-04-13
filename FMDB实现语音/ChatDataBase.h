//
//  ChatDataBase.h
//  FMDB实现语音
//
//  Created by Dahao Jiang on 2018/4/10.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimuChatModel.h"


@interface ChatDataBase : NSObject

+ (instancetype)sharedInstance;

/** 根据用户ID打开数据库 */
- (void)openDataBaseByUserID:(NSString *)userId;

/** 插入一条语音记录 */
-(BOOL)insertVoiceRecordByUserId:(NSString *)userid RecordModel:(SimuChatModel *)model;

/** 删除一条语音记录 */
- (BOOL)removeVoiceRecordByUserId:(NSString *)userid RecordModel:(SimuChatModel *)model;


/**
 返回查询数组

 @param userid 查询表Id
 @param loca 从哪个位置开始查询 (倒序)  (假设有10条，输入3，从第7条开始返回)
 @param count 查询多少条
 @return 查询到的数量
 */
- (NSArray *)getVoiceRecordCountByUserId:(NSString *)userid location:(int)loca count:(int)count;

/**
 查询数据是否应存在数据库
 @param model 数据模型
 @return 是否已经存在
 */
- (BOOL)queryInfoIfExistsInDataBaseByUserId:(NSString *)userid Model:(SimuChatModel *)model;

/** 查询文件是否已经存在于沙盒 */
- (BOOL)queryFileIfExistInSandBox:(NSString *)fileLocaltion;


@end
