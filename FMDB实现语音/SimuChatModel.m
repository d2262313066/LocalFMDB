//
//  SimuChatModel.m
//  FMDB实现语音
//
//  Created by Dahao Jiang on 2018/4/10.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import "SimuChatModel.h"

@implementation SimuChatModel

-(instancetype)initWithDictionary:(NSDictionary *)dic {
    self = [super init];
    if (self){
        [self setValuesForKeysWithDictionary:dic];
    }
    return self;
}
-(void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"long"]) {
        _duration = value;
    }
}

-(id)valueForUndefinedKey:(NSString *)key {
    return nil;
}

@end
