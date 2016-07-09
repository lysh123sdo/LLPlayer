//
//  ViewController.m
//  LLPlayer
//
//  Created by Lyson on 16/4/24.
//  Copyright © 2016年 LLPlayer. All rights reserved.
//

#import "ViewController.h"
#import "LLPlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float width = [[UIScreen mainScreen] bounds].size.width;
    float height = [[UIScreen mainScreen] bounds].size.height;
////
    LLPlayerView *view = [[LLPlayerView alloc] initWithFrame:CGRectMake(0, 0, width, height) Url:@"http://127.0.0.1/111.mp4"];
//    https://mvvideo5.meitudata.com/5678f6d2adf115463.mp4
    [self.view addSubview:view];
//
}


-(void)dealloc{

    NSLog(@" @@@@@@@@@@@@@@@@@@@  释放了 :  %@",NSStringFromClass([self class]));

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
