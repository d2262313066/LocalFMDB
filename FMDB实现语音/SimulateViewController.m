//
//  SimulateViewController.m
//  FMDB实现语音
//
//  Created by Dahao Jiang on 2018/4/13.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import "SimulateViewController.h"

#import "SimuChatModel.h"
#import "AFNetworking.h"
#import <objc/runtime.h>
#import "ChatDataBase.h"
#import <AVFoundation/AVFoundation.h>
#define myuserid @"myuserid"
@interface SimulateViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation SimulateViewController

-(NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

-(UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.tableFooterView = [UIView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    
    [[ChatDataBase sharedInstance] openDataBaseByUserID:myuserid];
    
   NSArray *arr = [[ChatDataBase sharedInstance] getVoiceRecordCountByUserId:myuserid location:0 count:6];
    [self.dataSource addObjectsFromArray:arr];
    [self.tableView reloadData];
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    SimuChatModel *model = self.dataSource[indexPath.row];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@",model.UserId?:@""];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SimuChatModel *model = self.dataSource[indexPath.row];
    /*删除数据库的 */
    [[ChatDataBase sharedInstance] removeVoiceRecordByUserId:myuserid RecordModel:model];
    /*删除数组的 */
    [self.dataSource removeObjectAtIndex: indexPath.row];
    
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SimuChatModel *model = self.dataSource[indexPath.row];
    NSURL *fileUrl = [NSURL URLWithString:[self getSavePath:model]];
    NSError *error;
    
    NSFileManager *manager =  [NSFileManager defaultManager];
    BOOL exist = [manager fileExistsAtPath:[self getSavePath:model]];
    if (!exist) {
        NSLog(@"文件不存在，无法播放");
    }
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    _player.numberOfLoops = 0;
    [_player prepareToPlay];
    if (error) {
        NSLog(@"创建播放器对象时发生错误，错误信息：%@",error.localizedDescription);
    }
    [_player play];
}

- (NSString *)getSavePath:(SimuChatModel *)model {
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    //模拟数据
    //    NSString *fileLocation = [document stringByAppendingPathComponent:model.fileUrl];
    //
    //    return fileLocation;
    
    /* 网络请求的时候,根据实际需求作判断 */
    NSRange range = [model.fileUrl rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        NSString *file = [model.fileUrl substringWithRange:NSMakeRange(range.location, model.fileUrl.length - range.location)];
        NSString *fileLocation = [document stringByAppendingString:file];
        return fileLocation;
    }
    return nil;
}


@end
