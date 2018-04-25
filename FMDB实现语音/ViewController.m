//
//  ViewController.m
//  FMDB实现语音
//
//  Created by Dahao Jiang on 2018/4/10.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import "ViewController.h"
#import "NetViewController.h"
#import "SimulateViewController.h"
#import <objc/runtime.h>
#import "SimuChatModel.h"
@interface ViewController ()

@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)networkAction:(UIButton *)sender {
    [self presentViewController:[NetViewController new] animated:YES completion:nil];
}

- (IBAction)localAction:(UIButton *)sender {
    [self presentViewController:[SimulateViewController new] animated:YES completion:nil];
}

@end
