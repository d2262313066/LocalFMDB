//
//  SimuChatModel.h
//  FMDB实现语音
//
//  Created by Dahao Jiang on 2018/4/10.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimuChatModel : NSObject

@property (strong, nonatomic) NSString *avatarURL;
@property (strong, nonatomic) NSString *created;
@property (strong, nonatomic) NSString *timeString;
@property (strong, nonatomic) NSNumber *fileId;
@property (strong, nonatomic) NSString *fileUrl;
@property (strong, nonatomic) NSString *identityID;
@property (assign, nonatomic) BOOL isRead;
@property (strong, nonatomic) NSNumber *duration;
@property (strong, nonatomic) NSString *serialNumber;
@property (strong, nonatomic) NSNumber *sourceType;
@property (strong, nonatomic) NSString *UserId;


- (instancetype)initWithDictionary:(NSDictionary *)dic;

@end
