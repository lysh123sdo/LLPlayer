//
//  PlayerView.m
//  TestMedia
//
//  Created by Lyson on 16/3/22.
//  Copyright © 2016年 TestMedia. All rights reserved.
//

#import "PlayerView.h"
#import "LLPlayerPrivate.h"

@interface PlayerView()
{

}
@end
@implementation PlayerView

-(instancetype)initWithFrame:(CGRect)frame{

    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

-(void)dealloc{
    
    DLog(@" @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$################## %@",NSStringFromClass([self class]));
    
}

@end
