//
//  TTPlayer.m
//  TTPlayerLib
//
//  Created by ClaudeLi on 2018/1/6.
//  Copyright © 2018年 ClaudeLi. All rights reserved.
//

#import "TTPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <CLProgressFPD/CLProgressFPD.h>
#import <CLTools/CLTools.h>
#import <TTAlertKit/TTAlert.h>
#import "TTPlayerItem.h"
#import "TTLocalServer.h"
#import "TTPlayerDefaults.h"

#define TTString(a)   NSLocalizedString(a, nil)

NSString *TTFormatedTcpSpeed(int64_t bytes){
    if (bytes <= 0) {
        return @"0.0 B/s";
    }
    float bytes_per_sec = ((float)bytes) * 1000.f /  1000.0;
    if (bytes_per_sec >= 1000 * 1000) {
        return [NSString stringWithFormat:@"%.2f MB/s", ((float)bytes_per_sec) / 1000.0 / 1000.0];
    } else if (bytes_per_sec >= 1000) {
        return [NSString stringWithFormat:@"%.1f KB/s", ((float)bytes_per_sec) / 1000.0];
    } else {
        return [NSString stringWithFormat:@"%ld B/s", (long)bytes_per_sec];
    }
}

@interface TTPlayer ()<UIGestureRecognizerDelegate>{
    NSTimer     *_timer;
    float       _cacheProgress;
    NSInteger   _tryReconnection;
}

@property (atomic, retain) IJKFFMoviePlayerController *player;
@property (nonatomic, strong) IJKFFOptions *options;

@property (nonatomic, assign) BOOL canPlay;
@property (nonatomic, assign) BOOL hasLoad;
@property (nonatomic, assign) BOOL isLive;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL shouldPlay;

@property (nonatomic, assign) NSTimeInterval maxPlayedTime;

@property (nonatomic, strong) CLProgressFPD *progressHUD;

@end

@implementation TTPlayer

- (instancetype)init{
    self = [super init];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (void)_setUp{
    _rate = 1;
    self.contentMode = UIViewContentModeScaleAspectFit;
}

- (BOOL)isLive{
    return _videoItem.isLive;
}

- (CLProgressFPD *)progressHUD{
    if (!_progressHUD) {
        _progressHUD = [[CLProgressFPD alloc] init];
        [self addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (IJKFFOptions *)options{
    if (!_options) {
        _options = [IJKFFOptions optionsByDefault];
        [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
//        [options setFormatOptionValue:@"tcp"      forKey:@"rtsp-tcp"];
//        [_options setPlayerOptionIntValue:0       forKey:@"start-on-prepared"]; // 自动播放
//        [_options setFormatOptionIntValue:1       forKey:@"reconnect"]; // 是否重连
        [_options setPlayerOptionIntValue:120               forKey:@"min-frames"];
        [_options setFormatOptionIntValue:10 * 1000 * 1000  forKey:@"timeout"];
        // drop frames when cpu is too slow (0, -1, 120)
        [_options setPlayerOptionIntValue:1                 forKey:@"framedrop"];   //跳帧开关
        if (_userAgent) {
            [_options setFormatOptionValue:_userAgent           forKey:@"user_agent"];
        }
        [_options setPlayerOptionIntValue:30                forKey:@"max-fps"]; // 最大fps
//        [_options setFormatOptionIntValue:1024*128          forKey:@"probesize"]; // 播放前的探测Size,默认1M
//        // 自动转屏开关
        [_options setFormatOptionIntValue:1         forKey:@"auto_convert"];

//        [_options setFormatOptionValue:@"tcp"       forKey:@"rtsp_transport"];// 如果使用rtsp协议,可以优先用tcp（默认udp）
//        [_options setCodecOptionIntValue:48         forKey:@"skip_loop_filter"];//开启环路滤波（0比48清楚，但解码开销大，48基本没有开启环路滤波，清晰度低，解码开销小）
//        [_options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_frame"];
//        [_options setFormatOptionIntValue:0          forKey:@"http-detect-range-support"];
        if (self.isLive) {
            [_options setPlayerOptionIntValue:3000       forKey:@"max_cached_duration"]; //最大缓存大小是3秒
            [_options setFormatOptionIntValue:0          forKey:@"packet-buffering"]; // 关闭播放器缓冲
            [_options setPlayerOptionIntValue:1          forKey:@"infbuf"];           // 无限读
            [_options setFormatOptionIntValue:1          forKey:@"no-time-adjust"];
            [_options setFormatOptionIntValue:1000       forKey:@"analyzeduration"];
            [_options setFormatOptionValue:@"nobuffer"   forKey:@"fflags"];
        }else{
            // 精确定位
            [_options setOptionIntValue:1   forKey:@"enable-accurate-seek" ofCategory:kIJKFFOptionCategoryPlayer];
//            [_options setPlayerOptionIntValue:15 * 1024 * 1024   forKey:@"max-buffer-size"];
            // 硬解码
            [_options setPlayerOptionIntValue:1         forKey:@"videotoolbox"];
            [_options setPlayerOptionIntValue:1920      forKey:@"videotoolbox-max-frame-width"];
//            [_options setPlayerOptionIntValue:0         forKey:@"max_cached_duration"];
//            [_options setPlayerOptionIntValue:0         forKey:@"infbuf"];
//            [_options setPlayerOptionIntValue:1         forKey:@"packet-buffering"]; // 打开播放器缓冲
            // 设置只播放视频, 不播放声音
            //    [options setPlayerOptionValue:@"1" forKey:@"an"];
            // 帧速率(fps)
            //    [_options setPlayerOptionIntValue:25    forKey:@"r"];
            // -vol——设置音量大小，256为标准音量。（要设置成两倍音量时则输入512，依此类推
            //    [options setPlayerOptionIntValue:512 forKey:@"vol"];
        }
    }
    return _options;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _player.view.frame = self.bounds;
    _player.view.center = self.center;
}

- (void)setRate:(CGFloat)rate{
    _rate = rate;
    if (_player) {
        _player.playbackRate = rate;
    }
}

- (void)playWithItem:(TTPlayerItem *)item autoPlay:(BOOL)autoPlay{
    if (!item) {
        return;
    }
    [self removeObservers:NO];
    self.videoItem = item;
    _shouldAutoPlay = autoPlay;
    [self load];
}

- (void)load{
    _canPlay = NO;
    _tryReconnection = 0;
    _videoItem = [self getVideoItem];
    _cacheProgress = 0;
    // 网络状态判断
    if ([self judgeNetworkCanPlay]) {
        [self reloadPlayerWithReconnection:NO];
    }
}

// 将要播放的item
- (TTPlayerItem *)getVideoItem{
    if (self.isLive) {
        _videoItem.playURL = [NSURL URLWithString:_videoItem.file];
        _videoItem.isNetVideo = YES;
        return _videoItem;
    }
    BOOL exist = exist = [[NSFileManager defaultManager] fileExistsAtPath:_videoItem.filePath];
    if (exist) {
        _videoItem.playURL = [NSURL fileURLWithPath:_videoItem.filePath];
    }else {
        if ([NSString isNilOrEmptyString:_videoItem.file]) {
            return _videoItem;
        }
//    async:
        if ([TTLocalServer isRunning]) {
            _videoItem.playURL = [NSURL URLWithString:[TTLocalServer getProxyUrl:_videoItem.file]];
            _videoItem.isLocalServer = YES;
        }else{
            [TTLocalServer startServer];
            _videoItem.playURL = [NSURL URLWithString:_videoItem.file];
        }
        _videoItem.isNetVideo = YES;
    }
    return _videoItem;
}

- (void)reloadPlayerWithReconnection:(BOOL)reconnection{
    if (self.playerDelayPlay) {
        self.playerDelayPlay(YES);
    }
    [self removeObservers:reconnection];
    if (![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayback]) {
        NSError *audioSessionError;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError];
        if (audioSessionError) {
            NSLog(@"%@", audioSessionError);
        }
    }
    if (_tryReconnection >= 2 && !self.isLive) {
        _player = (IJKFFMoviePlayerController *)[[IJKAVMoviePlayerController alloc] initWithContentURL:_videoItem.playURL];
        if (self.playerToChangedPlayer) {
            self.playerToChangedPlayer();
        }
    }else{
        _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:_videoItem.playURL withOptions:self.options];
    }
    _player.view.frame = self.bounds;
    [self addSubview:_player.view];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFit];
    if (_rate) {
        self.player.playbackRate = _rate;
    }
    [self installMovieNotificationObservers];
    _hasLoad = YES;
    if (self.playerReadyToPlay) {
        self.playerReadyToPlay();
    }
    // 设置自动播放()
//    _player.shouldAutoplay = _shouldAutoPlay;
    if (_shouldAutoPlay &&
        _player) {
        [self play];
    }
#ifdef DEBUG
    if (TTPlayerStandard.allowShowLog) {
        [IJKFFMoviePlayerController setLogReport:YES];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
        if ([_player isKindOfClass:[IJKFFMoviePlayerController class]]) {
            _player.shouldShowHudView = YES;
        }
    }else{
        [IJKFFMoviePlayerController setLogReport:NO];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_ERROR];
    }
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
}

- (void)play{
    if (![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayback]) {
        NSError *audioSessionError;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError];
        if (audioSessionError) {
            NSLog(@"%@", audioSessionError);
        }
    }
    if (_player) {
        if (![_player isPlaying]) {
            [_player prepareToPlay];
            [_player play];
        }
    }else{
        if (_videoItem &&
            [_videoItem isKindOfClass:[TTPlayerItem class]]) {
            [self playWithItem:_videoItem autoPlay:YES];
        }
    }
    if (self.playerToPlay) {
        self.playerToPlay();
    }
}
 
- (void)pause{
    if (_player) {
        [self removeTimer];
        [_player pause];
    }
    if (self.playerToPause) {
        self.playerToPause();
    }
}

- (void)stop{
    if ([[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayback]) {
        NSError *audioSessionError;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&audioSessionError];
        if (audioSessionError) {
            NSLog(@"%@", audioSessionError);
        }
    }
    [self removeObservers:NO];
}

- (CGFloat)currentTime {
    if (_player.currentPlaybackTime) {
        return self.player.currentPlaybackTime;
    }
    return 0.0f;
}

- (CGFloat)totalTime {
    if (_player.duration) {
        return _player.duration;
    }
    return 0.0f;
}

- (BOOL)isPlaying{
    if (_player) {
        return _player.isPlaying;
    }
    return NO;
}

- (int64_t)tcpSpeed{
    if (_player &&
        [_player isKindOfClass:[IJKFFMoviePlayerController class]]) {
        return [_player tcpSpeed];
    }
    return 0;
}

- (void)seekToTime:(float)seconds{
    [self seekToTime:seconds completionHandler:nil];
}

- (void)seekToTime:(float)seconds completionHandler:(void (^)(BOOL finished))completionHandler{
    if (_canPlay && !self.isLive) {
        if (seconds >= (_player.duration-0.2)) {
            seconds = _player.duration-0.2;
        }else if (seconds <= 0){
            seconds = 0;
        }
        if (TTPlayerStandard.currentNetworkStatus == 0) {
            [TTLocalServer setProxyUrl:_videoItem.file newCache:NO];
        }
        _player.currentPlaybackTime = seconds;
        if (completionHandler) {
            completionHandler(YES);
        }
    }
}

- (void)setLayerTransform:(CATransform3D)layerTransform{
    _layerTransform = layerTransform;
    __weak __typeof(&*self)weak_self = self;
    [UIView animateWithDuration:0.4 animations:^{
        weak_self.layer.transform = layerTransform;
    }];
}

- (void)setLayerTransform:(CATransform3D)layerTransform animation:(BOOL)animation{
    if (animation) {
        self.layerTransform = layerTransform;
    }else{
        self.layer.transform = layerTransform;
    }
}

#pragma mark -
#pragma mark -- installMovieNotificationObservers --
- (void)installMovieNotificationObservers{
    // 前后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignActiveNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    // IJK
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    if (!self.isLive) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                     name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                   object:_player];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayRotionChanged:)
                                                     name:IJKMPMoviePlayerVideoRotionChangedNotification
                                                   object:_player];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(movieNaturalSize:)
                                                     name:IJKMPMovieNaturalSizeAvailableNotification
                                                   object:_player];
        if (_videoItem.isLocalServer) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaCacheDidChanged:) name:CacheStatusNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaCacheDidError:) name:CacheErrorNotification object:nil];
        }
    }
}
#pragma mark -
#pragma mark -- Notifications function --
- (void)enterForegroundNotification{
    if (_shouldPlay) {
        [self play];
    }else{
        [self pause];
    }
}

- (void)resignActiveNotification{
    if (_timer) {
        _shouldPlay = YES;
        [self pause];
    }else{
        _shouldPlay = NO;
    }
}

- (void)mediaCacheDidError:(NSNotification *)notification{
    NSLog(@"%@", notification);
}

- (void)mediaCacheDidChanged:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if ([[userInfo[CacheURLKey] lastPathComponent] isEqualToString:[_videoItem.file lastPathComponent]]) {
        NSArray<NSValue *> *cachedFragments = userInfo[CacheFragmentsKey];
        long long contentLength = [userInfo[CacheContentLengthKey] longLongValue];
        if (cachedFragments == nil ||
            cachedFragments.count <= 0 ||
            contentLength <= 0)
            return;
        long long cacheLength = cachedFragments[0].rangeValue.length;
        _cacheProgress = (float)cacheLength / (float)contentLength;
    }
}

- (void)movieNaturalSize:(NSNotification*)notification{
    NSLog(@"player videoSize : %@", NSStringFromCGSize(_player.naturalSize));
}

- (void)moviePlayRotionChanged:(NSNotification*)notification{
    NSLog(@"player videoTheta : %d", [[[notification userInfo] valueForKey:IJKMPMoviePlayerVideoRotionChangedKey] intValue]);
}

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        if (self.playerDelayPlay) {
            self.playerDelayPlay(NO);
        }
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        [self removeTimer];
        if (self.playerDelayPlay) {
            self.playerDelayPlay(YES);
        }
    } else {
        NSLog(@"加载状态: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
        {
            if (self.playerPlayEndBlock) {
                self.playerPlayEndBlock();
            }
            if (_shouldLoopPlay) {
                [self play];
            }
        }
            break;
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
        {
            if (!_player || !self) {
                return;
            }
            if (_videoItem.isNetVideo &&
                !self.isLive &&
                [_player isKindOfClass:[IJKFFMoviePlayerController class]]) {
                if (_player.monitor.remoteIp) {
                    if (TTPlayerStandard.currentNetworkStatus == 0) {
                        [self stop];
                        [self.progressHUD showText:TTString(@"Network Error,Please check the network")];
                    }else{
                        _tryReconnection++;
                        if (_tryReconnection == 1) {
                            _videoItem.playURL = [NSURL URLWithString:_videoItem.file];
                            _videoItem.isLocalServer = NO;
                            [self reloadPlayerWithReconnection:YES];
#ifdef DEBUG
                            [self.progressHUD showText:@"尝试第一次重连~"];
#endif
                        }else if (_tryReconnection == 2){
                            _videoItem.playURL = [NSURL URLWithString:_videoItem.file];
                            _videoItem.isLocalServer = NO;
                            [self reloadPlayerWithReconnection:YES];
                        }else{
                            [self stop];
                            [self.progressHUD showText:TTString(@"Playback failed,Please try again")];
                        }
                    }
                }else{
                    if (_tryReconnection < 2){
                        _tryReconnection = 2;
                        _videoItem.playURL = [NSURL URLWithString:_videoItem.file];
                        _videoItem.isLocalServer = NO;
                        [self reloadPlayerWithReconnection:YES];
                    }else{
                        if (self) {
                            [self stop];
                            [self.progressHUD showText:TTString(@"Playback failed,Please try again")];
                        }
                    }
                }
            }else{
                if (_tryReconnection>=2) {
                    [self.progressHUD showText:TTString(@"Playback failed,Please try again")];
                    return;
                }
                _tryReconnection++;
                if (!self.isLive) {
                    if ([TTLocalServer isRunning]) {
                        _videoItem.isLocalServer = YES;
                    }
                    _videoItem.playURL = [NSURL URLWithString:_videoItem.file];
                    _videoItem.isLocalServer = NO;
                }
                _videoItem.isNetVideo = YES;
                [self reloadPlayerWithReconnection:YES];
            }
        }
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    if (_player.isPreparedToPlay) {
        _canPlay = YES;
        if (self.playerTotalTimeBlock) {
            self.playerTotalTimeBlock([self totalTime]);
        }
        if (_videoItem.seekTime > 0 && _videoItem.seekTime < _player.duration) {
            [self seekToTime:_videoItem.seekTime];
            _videoItem.seekTime = 0;
        }
        if (_shouldAutoPlay && !_player.isPlaying) {
            [self play];
        }
    }else{
        NSLog(@"不能播放");
    }
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    switch (_player.playbackState) {
        case IJKMPMoviePlaybackStateStopped:
        {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            [self removeObservers:NO];
        }
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
        {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            _tryReconnection = 0;
            [self removeTimer];
            if (self.playerToPlay) {
                self.playerToPlay();
            }
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(update) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        }
            break;
            
        case IJKMPMoviePlaybackStatePaused:
        {
            [self removeTimer];
            if (self.playerToPause) {
                self.playerToPause();
            }
            if ([[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayback]) {
                NSError *audioSessionError;
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&audioSessionError];
                if (audioSessionError) {
                    NSLog(@"%@", audioSessionError);
                }
            }
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
        }
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            [self removeTimer];
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma mark -
#pragma mark -- update --
- (void)update{
    if (_player) {
        if (![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayback]) {
            NSError *audioSessionError;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError];
            if (audioSessionError) {
                NSLog(@"%@", audioSessionError);
            }
        }
        if (![UIApplication sharedApplication].idleTimerDisabled) {
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        }
        if (_maxPlayedTime < _player.currentPlaybackTime) {
            _maxPlayedTime = _player.currentPlaybackTime;
        }
        [self judgeNetworkCanPlay];
        if (self.playerCurrentTimeBlock) {
            self.playerCurrentTimeBlock(_player.currentPlaybackTime);
        }
        if (_player.duration) {
            if (self.playerLoadedTimeBlock) {
                if (_videoItem.isNetVideo) {
                    if (_videoItem.isLocalServer) {
                        self.playerLoadedTimeBlock(_cacheProgress);
                    }else{
                        self.playerLoadedTimeBlock((CGFloat)_player.playableDuration/(_player.duration * 1.0));
                    }
                }else{
                    self.playerLoadedTimeBlock(1);
                }
            }
        }
    }
}

- (BOOL)judgeNetworkCanPlay{
    if (!_videoItem.isNetVideo) {
        return YES;
    }
    if (TTPlayerStandard.allowToPlay) {
        return YES;
    }
    if (_previewing) {
        return YES;
    }
    if (TTPlayerStandard.currentNetworkStatus != 1) {
        return YES;
    }
    [self pause];
    __weak __typeof(&*self)weak_self = self;
    [TTAlert alertInView:self
                   title:TTString(@"Tip")
                 message:TTString(@"You are currently not WiFi network,sure to continue to play?")
          completeHelper:^(NSInteger clickIndex) {
              if (clickIndex) {
                  TTPlayerStandard.allowToPlay = YES;
                  if (weak_self.player) {
                      [weak_self play];
                  }else{
                      [weak_self reloadPlayerWithReconnection:NO];
                  }
              }else{
                  if (TTPlayerStandard.currentNetworkStatus == 1) {
                      [weak_self stop];
                  }
              }
          } cancelTitle:TTString(@"Cancel")
             otherTitles:TTString(@"Continue"), nil];
    return NO;
}

#pragma mark -
#pragma mark -- removeMovieNotificationObservers --
- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerVideoRotionChangedNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMovieNaturalSizeAvailableNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CacheStatusNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CacheErrorNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark -- removePlayerObserver --
- (void)removeObservers:(BOOL)reconnection{
    if (_player) {
        if (self.playerToStop) {
            self.playerToStop();
        }
        [self clear];
    }
}

- (void)clear{
    [self removeMovieNotificationObservers];
    [self removeTimer];
    [self.player stop];
    [self.player.view removeFromSuperview];
    [self.player shutdown];
    _canPlay = NO;
    _hasLoad = NO;
    _cacheProgress = 0;
    _player = nil;
    _options = nil;
}

- (void)removeTimer{
    if ([UIApplication sharedApplication].idleTimerDisabled) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)dealloc{
    if (_player) {
        [self clear];
    }
}

@end
