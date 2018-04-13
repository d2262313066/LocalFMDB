//
//  NetViewController.m
//  FMDB实现语音
//
//  Created by Dahao Jiang on 2018/4/13.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import "NetViewController.h"
#import "ChatDataBase.h"
#import "SimuChatModel.h"
#import <objc/runtime.h>
#import "AFNetworking.h"
#import "HttpRequest.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+MD5.h"
#define myuserid @"myuserid"
@interface NetViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation NetViewController
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
    
    dispatch_queue_t queue = dispatch_queue_create("com.addDataBase", NULL);
    
    NSArray *dataArr = [self addSimulateData];
    //模拟网络延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (SimuChatModel *model in dataArr) {
            //异步串行执行
            dispatch_async(queue, ^{
                [[ChatDataBase sharedInstance] insertVoiceRecordByUserId:myuserid RecordModel:model];
            });
            [self downloadVoiceByModel:model];
            [self.dataSource addObject:model];
        }
        [self.tableView reloadData];
    });
    
    
}

- (void)downloadVoiceByModel:(SimuChatModel *)model {
    
    BOOL exist = [[ChatDataBase sharedInstance] queryFileIfExistInSandBox:[self getSavePath:model]];
    if (exist) {
        NSLog(@"已经存在该文件 fileUrl: %@",model.fileUrl);
        return ;
    }
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
    
    NSString *path = model.fileUrl;
    NSURL *url = [NSURL URLWithString:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"File downloaded to: %@", filePath);
    }];
    [task resume];
    
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SimuChatModel *model = self.dataSource[indexPath.row];
    NSURL *fileUrl = [NSURL URLWithString:[self getSavePath:model]];
    NSError *error;
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

/** 添加模拟数据 */
- (NSArray *)addSimulateData {
    NSArray *mp3Arr = @[@"http://hao.haolingsheng.com/ring/000/993/d915a1c149bb3076a32dfdab923f8c21.mp3",
                        @"http://hao.haolingsheng.com/ring/000/995/5daafc2ad36c4abcb1101492265b06f2.mp3",
                        @"http://hao.haolingsheng.com/ring/000/967/fa7f5deba40cd42bee007fe4c7e2abdf.mp3",
                        @"http://hao.haolingsheng.com/ring/000/982/3dac89285d5412642006598c09c907af.mp3",
                        @"http://hao.haolingsheng.com/ring/000/995/ea4f450884af56ca42e3cf5c3b9db63d.mp3",
                        @"http://hao.haolingsheng.com/ring/000/995/fbc33cda344ba43992d3e1b809054280.mp3",
                        ];
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 6; i ++) {
        SimuChatModel *model = [[SimuChatModel alloc] init];
        model.avatarURL = @"123213";
        model.created = nil;
        model.timeString = @"2018-4-4 10:10:10";
        model.fileId = @10086;
        model.fileUrl = mp3Arr[i];
        model.identityID = [NSUUID UUID].UUIDString;
        model.isRead = @(YES);
        model.duration = @60;
        model.serialNumber = @"7474747";
        model.sourceType = @1;
        model.UserId =  i%2 == 1 ? @"you" : @"me";
        [arr addObject:model];
    }
    return [arr copy];
}

@end

