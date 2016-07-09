 //
//  LLPlayerView.m
//  TestMedia
//
//  Created by Lyson on 16/4/6.
//  Copyright © 2016年 TestMedia. All rights reserved.
//

#import "LLPlayerView.h"
#import "PlayerView.h"
#import "LLPlayerPrivate.h"

#define FILESERVER @"https://mvvideo5.meitudata.com/"
#define LOCALSERVER @"http://127.0.0.1:80808/"

@interface LLPlayerView()
{
    NSString *_totalTime;
    NSDateFormatter *_dateFormatter;
 
    /**
     *  记录已经下载完的通知
     */
    NSMutableArray *downloadRangeNotificationArr;
    
    NSMutableDictionary *downloadRangeTimeDic;
    
    
    
}
@property (nonatomic , strong) AVPlayer *player;
@property (nonatomic , strong) PlayerView *playerView;
@property (nonatomic , strong) AVPlayerItem *playerItem;
@property (nonatomic , strong) UIButton *playButton;;
@property (nonatomic , strong) UISlider *videoSlider;
@property (nonatomic , strong) UIProgressView *videoProgress;
@property (nonatomic , strong) UILabel *timeLable;
@property (nonatomic , strong) AVAResourceLoaderManager *resourceManager;
@property (nonatomic , assign) BOOL isPlay;
@property (nonatomic , strong) NSString *localUrl;
@property (nonatomic , strong) NSString *serverUrl;
@property (nonatomic , strong) NSString *fileName;
@property (nonatomic , strong) NSString *cachePath;
@property (nonatomic , strong) id playbackTimeObserver;

@end

@implementation LLPlayerView



-(instancetype)initWithFrame:(CGRect)frame Url:(NSString*)url{

    
    if (self = [super initWithFrame:frame]) {

        downloadRangeNotificationArr = [[NSMutableArray alloc] init];
        downloadRangeTimeDic = [[NSMutableDictionary alloc] init];
   
        [self spliteUrl:url];
        
        [self initViews];

        [self addPlayerItem];

    }

    return self;
}


-(void)dealloc{

    DLog(@" @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$################## %@",NSStringFromClass([self class]));
    
}

-(void)stopAll{

    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [self.player removeTimeObserver:self.playbackTimeObserver];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
 
 
}

-(void)initViews{
    
    self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 50  , 50, 50)];
    [self.playButton addTarget:self action:@selector(playClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton setEnabled:NO];
    [self addSubview:self.playButton];
    [self.playButton setTitle:@"play" forState:UIControlStateNormal];
    
    self.playerView = [[PlayerView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - self.playButton.frame.size.height)];
    [self addSubview:self.playerView];

    self.timeLable = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 100 - 20, self.playButton.frame.origin.y, 100, 25)];
    self.timeLable.backgroundColor = [UIColor clearColor];
    self.timeLable.textAlignment = NSTextAlignmentRight;
    self.timeLable.font = [UIFont systemFontOfSize:12];
    [self addSubview:self.timeLable];
    
    float x = self.playButton.frame.origin.x + self.playButton.frame.size.width + 15;
    float right = 20;
    
    self.videoProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(x, 0, self.frame.size.width - x - right, 10)];
    [self addSubview:self.videoProgress];
    
    self.videoSlider = [[UISlider alloc] initWithFrame:CGRectMake(x - 5 , 0, self.frame.size.width - x - right + 10, 50)];
    [self.videoSlider addTarget:self action:@selector(videoSlierChangeValue:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.videoSlider];
    
    self.videoProgress.center = CGPointMake(self.videoProgress.center.x, self.playButton.center.y);
    self.videoSlider.center = CGPointMake(self.videoProgress.center.x, self.playButton.center.y);
//    self.timeLable.center = CGPointMake(self.timeLable.center.x, self.playButton.center.y);
    
    self.videoProgress.backgroundColor = [UIColor yellowColor];
    
    self.playButton.backgroundColor = [UIColor greenColor];
}


-(void)addPlayerItem{

    _resourceManager = [[AVAResourceLoaderManager alloc] initWithServerUrl:self.serverUrl cachePath:self.cachePath];
    
    NSURL *playUrl = [_resourceManager getSchemeVideoURL:[NSURL URLWithString:self.serverUrl]];
    
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:playUrl
                                               options:nil];
    
    [urlAsset.resourceLoader setDelegate:_resourceManager queue:dispatch_get_main_queue()];
    _playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        _playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
    }
    
    
    
    if (!self.player) {
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    } else {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    
    self.playerView.player = self.player;
   
    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    

}


#pragma mark - 监听播放状态

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            
            self.playButton.enabled = YES;
            // 获取视频总长度
            CMTime duration = self.playerItem.duration;
            // 转换成秒
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;
            // 转换成播放时间
            _totalTime = [self convertTime:totalSecond];
            // 自定义UISlider外观
            [self customVideoSlider:duration];
            // 监听播放状态
            [self monitoringPlayback:self.playerItem];

        }else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed %@",playerItem.error);
        }
        
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        
        CMTime duration = _playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        
        [self.videoProgress setProgress:timeInterval / totalDuration animated:YES];
    }
    
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    
    __weak typeof(self) weakSelf = self;
    
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.videoSlider setValue:0.0 animated:YES];
        [weakSelf.playButton setTitle:@"Play" forState:UIControlStateNormal];
    }];
}

#pragma mark - 播放进度处理

- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (void)customVideoSlider:(CMTime)duration {
    self.videoSlider.maximumValue = CMTimeGetSeconds(duration);
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.videoSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [self.videoSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf monitoringBack];
    }];
}

-(void)monitoringBack{
    CGFloat currentSecond = self.playerItem.currentTime.value/self.playerItem.currentTime.timescale;// 计算当前在第几秒
    [self.videoSlider setValue:currentSecond animated:YES];
    NSString *timeString = [self convertTime:currentSecond];
    self.timeLable.text = [NSString stringWithFormat:@"%@/%@",timeString,_totalTime];
}

#pragma mark - URL处理
-(void)spliteUrl:(NSString*)url{
    
    self.serverUrl = url;
    self.localUrl = [url stringByReplacingOccurrencesOfString:FILESERVER withString:LOCALSERVER];
    self.fileName = [[url componentsSeparatedByString:@"/"] lastObject];
    self.cachePath = [NSString stringWithFormat:@"%@/%@",[self getCacheDirectory],self.fileName];
    
}

-(NSString*)getCacheDirectory{

    return [NSString stringWithFormat:@"%@/Documents",NSHomeDirectory()];
}

#pragma mark - 时间点击区

/**
 *  开始播放
 */
-(void)playClick{

    if (!self.isPlay) {
        [self.player play];
        [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.player pause];
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
    self.isPlay = !self.isPlay;

}

-(void)videoSlierChangeValue:(UISlider*)slider{

    CGFloat value = slider.value;
    
    CMTime changedTime = CMTimeMakeWithSeconds(value , 1);
    __weak typeof(self) weakSel = self;

    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        
        [weakSel.player play];
    }];
}

@end
