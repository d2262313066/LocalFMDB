//
//  ChatDataBase.m
//  FMDB实现语音
//
//  Created by Dahao Jiang on 2018/4/10.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import "ChatDataBase.h"
#import "FMDB.h"
#import <objc/runtime.h>
@implementation ChatDataBase
{
    FMDatabase *_db;
}

static ChatDataBase *dataBase;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataBase = [[ChatDataBase alloc] init];
    });
    return dataBase;
}

-(void)openDataBaseByUserID:(NSString *)userId {
    //1、创建数据库
    NSString *paths = [self getDataBasePath];
    NSLog(@"paths = %@",paths);
    _db = [FMDatabase databaseWithPath:paths];
    if ([_db open]) {
        NSLog(@"数据库打开成功");
    } else {
        NSLog(@"数据库打开失败");
    }
    [self createTableByUserId:userId];
}

- (void)createTableByUserId:(NSString *)userid {
    
    SimuChatModel *item = [[SimuChatModel alloc] init];
    
    NSMutableString *mutStr = [NSMutableString string];
    
    unsigned int outCount;
    Ivar *members = class_copyIvarList([item class], &outCount);
    
    
    
    for (int i = 0; i < outCount; i ++) {
        Ivar var = members[i];
        const char *memberName = ivar_getName(var);
        const char *memberType = ivar_getTypeEncoding(var);
//        NSLog(@"%s----%s", memberName, memberType);
        
        NSString *oc_memberName = [[NSString alloc] initWithCString:memberName encoding:NSUTF8StringEncoding];
        oc_memberName = [oc_memberName stringByReplacingOccurrencesOfString:@"_" withString:@""];
        
        NSString *typeStr = [NSString stringWithCString:memberType encoding:NSUTF8StringEncoding];
        if ([typeStr isEqualToString:@"@\"NSString\""]) {
            [mutStr appendFormat:@"%@ TEXT,",oc_memberName];
        } else if ([typeStr isEqualToString:@"@\"NSNumber\""]) {
            [mutStr appendFormat:@"%@ INTEGER,",oc_memberName];
        } else if ([typeStr isEqualToString:@"B"]) {
            [mutStr appendFormat:@"%@ INTEGER,",oc_memberName];
        }
    }
    [mutStr deleteCharactersInRange:NSMakeRange(mutStr.length - 1 , 1)];
//    NSLog(@"mutStr = %@",mutStr);
    
    /**
     create table if not exists  (id integer primary key not null,isRead INTEGER,avatarURL TEXT,created TEXT,timeString TEXT,fileId INTEGER,fileUrl TEXT,identityID TEXT,duration INTEGER,serialNumber TEXT,sourceType INTEGER,UserId TEXT)
     */
    NSString *returnStr = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key not null,%@)",userid,mutStr];
    if([_db executeUpdate:returnStr])
    {
        NSLog(@"%@表创建成功",userid);
    }
}

-(BOOL)insertVoiceRecordByUserId:(NSString *)userid RecordModel:(SimuChatModel *)model {
    
    BOOL exists = [self queryInfoIfExistsInDataBaseByUserId:userid Model:model];
    if (exists) {
        NSLog(@"此数据已存在，fileUrl:%@",model.fileUrl);
        return NO;
    }
    NSArray *propertyNames = [[self getPropertyName:model] componentsSeparatedByString:@","];
    /**
     isRead,avatarURL,created,timeString,fileId,fileUrl,identityID,duration,serialNumber,sourceType,UserId
     */
    NSString *key = [self getPropertyName:model];
    NSMutableString *value = [NSMutableString string];
    NSMutableArray * argumentsArr = [NSMutableArray array]; // 保存所有参数的值的数组
    for (int i = 0; i < propertyNames.count; i ++) {
        (i == 0)?[value appendString:@"?"]:[value appendString:@",?"];
        id object = [model valueForKey:propertyNames[i]]?:@"";
        if ([object isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
            int isread = [object intValue];
            object = [NSNumber numberWithInt:isread];
        }
        [argumentsArr addObject:object];
    }
    NSString *sql = [NSString stringWithFormat:@"insert into %@ (%@) values (%@)",userid,key,value];
    __block BOOL executeUpdate;
    FMDatabaseQueue *databaseQuque = [FMDatabaseQueue databaseQueueWithPath:[self getDataBasePath]];
    //这里使用FMDatabseQueue 否则可能会出现is currently in use的错误，导致无法插入数据
    [databaseQuque inDatabase:^(FMDatabase *db) {
        if ([db open]) {
            //插入数据
            if ([_db executeUpdate:sql withArgumentsInArray:argumentsArr]) {
                NSLog(@"插入成功:%@",sql);
                executeUpdate = YES;
            } else {
                NSLog(@"插入失败:%@",sql);
                executeUpdate = NO;
            }
        } else {
            NSLog(@"打开数据库失败！");
        }
    }];

    return executeUpdate;
    
}

-(BOOL)removeVoiceRecordByUserId:(NSString *)userid RecordModel:(SimuChatModel *)model {
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where fileurl = %@",userid,model.fileUrl];
    
    __block BOOL executeUpdate;
    FMDatabaseQueue *databaseQuque = [FMDatabaseQueue databaseQueueWithPath:[self getDataBasePath]];
    //这里使用FMDatabseQueue 否则可能会出现is currently in use的错误，导致无法插入数据
    [databaseQuque inDatabase:^(FMDatabase *db) {
        if ([db open]) {
            if ([_db executeUpdate:sql]) {
                NSLog(@"删除成功:%@",sql);
                executeUpdate = YES;
            } else {
                NSLog(@"删除失败:%@",sql);
                executeUpdate = NO;
            }
        } else {
            NSLog(@"打开数据库失败！");
        }
    }];
    

    return executeUpdate;
}

- (NSArray *)getVoiceRecordCountByUserId:(NSString *)userid location:(int)loca count:(int)count {
    NSString *sql = [NSString stringWithFormat:@"select * from (select * from %@ order by id desc limit %d , %d)tablename order by id asc",userid, loca ,count];
    FMResultSet *result = [_db executeQuery:sql];
    
    NSMutableArray *recordListArr = [NSMutableArray array];
    
    NSArray *propertyNames = [[self getPropertyName:[SimuChatModel new]] componentsSeparatedByString:@","];
    while ([result next]) {
        SimuChatModel *model = [[SimuChatModel alloc] init];
        for (int j = 0; j < propertyNames.count; j ++) {
            [model setValue:[result stringForColumn:propertyNames[j]] forKey:propertyNames[j]];
        }
        [recordListArr addObject:model];
    }
    return recordListArr;
}

-(BOOL)queryInfoIfExistsInDataBaseByUserId:(NSString *)userid Model:(SimuChatModel *)model {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where fileUrl = %@", userid,[self handlePropertyType:model.fileUrl]];
    
    __block BOOL executeResult;
    FMDatabaseQueue *dataBaseQueue = [FMDatabaseQueue databaseQueueWithPath:[self getDataBasePath]];
    [dataBaseQueue inDatabase:^(FMDatabase *db) {
        if ([db open]) {
            FMResultSet *result = [_db executeQuery:sql];
            if ([result next]) {  // Exist
                executeResult = YES;
            } else {
                executeResult = NO; // Not Exist
            }
        } else {
            NSLog(@"打开数据库失败！");
        }
    }];
    return executeResult;
}

- (BOOL)queryFileIfExistInSandBox:(NSString *)fileLocaltion {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    return [manager fileExistsAtPath:fileLocaltion];
}


/** 获取数据库路径 */
- (NSString *)getDataBasePath {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *paths = [path stringByAppendingPathComponent:@"voiceDataBase.db"];
    return paths;
}


/**
 将字符串加入''，使字符串可以入库

 @param property 传入的值
 @return 返回可传入值
 */
- (id)handlePropertyType:(id)property {
    if ([property isKindOfClass:[NSString class]]) {
        NSString *saveString = [NSString stringWithFormat:@"'%@'",property];
        return saveString;
    }
    return property;
}

/**
 获取需要传入数据库的所有属性

 @param model 模型
 @return 属性字符串
 */
- (NSString *)getPropertyName:(SimuChatModel *)model {
    /* name, age, tel */
    unsigned int outCount;
    NSMutableString *enterInfoString = [NSMutableString string];
    Ivar *members = class_copyIvarList([model class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar var = members[i];
        const char *memberName = ivar_getName(var);
        NSString *oc_memberName = [[NSString alloc] initWithCString:memberName encoding:NSUTF8StringEncoding];
        oc_memberName = [oc_memberName stringByReplacingOccurrencesOfString:@"_" withString:@""];
        [enterInfoString appendFormat:@"%@,",oc_memberName];
    }
    [enterInfoString deleteCharactersInRange:NSMakeRange(enterInfoString.length - 1 , 1)];
    return enterInfoString;
}
/*
 //    NSMutableDictionary *handleValueDic = [NSMutableDictionary dictionary];
 //
 //    for (NSString *propertyName in propertyNames) {
 //        id value = [model valueForKey:propertyName];
 //        id handleValue = [self handlePropertyType:value];
 //        // 将处理完可传入数据库的类型添加到字典
 //        [handleValueDic setValue:handleValue forKey:propertyName];
 //    }
 //
 //    //暂时想不到更好的方法
 //    NSString *sql = [NSString stringWithFormat:@"insert into %@ (%@) values (%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@)",userid,
 //                     [self getPropertyName:model],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[0]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[1]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[2]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[3]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[4]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[5]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[6]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[7]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[8]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[9]]],
 //                     [self handlePropertyType:[model valueForKey:propertyNames[10]]]];
 //
 //
 //    __block BOOL executeUpdate;
 //    FMDatabaseQueue *databaseQuque = [FMDatabaseQueue databaseQueueWithPath:[self getDataBasePath]];
 //    //这里使用FMDatabseQueue 否则会出现is currently in use的错误，导致无法插入数据
 //    [databaseQuque inDatabase:^(FMDatabase *db) {
 //        if ([db open]) {
 //            //插入数据
 //            if ([_db executeUpdate:sql]) {
 //            NSLog(@"插入成功:%@",sql);
 //            executeUpdate = YES;
 //        } else {
 //            NSLog(@"插入失败:%@",sql);
 //            executeUpdate = NO;
 //        }
 //        } else {
 //            NSLog(@"打开数据库失败！");
 //        }
 //    }];
 //return executeUpdate;
 */
@end
