//
//  TTPlayer.h
//  TTPlayerLib
//
//  Created by ClaudeLi on 2018/1/6.
//  Copyright © 2018年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXTERN NSString *TTFormatedTcpSpeed(int64_t bytes);

@class TTPlayerItem;
@interface TTPlayer : UIImageView

@property (nonatomic, strong) TTPlayerItem *videoItem;

@property (nonatomic, assign) CGFloat   rate;
@property (nonatomic, copy)   NSString  *userAgent;
@property (nonatomic, assign) BOOL      shouldAutoPlay;
@property (nonatomic, assign) BOOL      shouldLoopPlay;
@property (nonatomic, assign) BOOL      previewing;
@property (nonatomic, assign) CATransform3D layerTransform;

@property (nonatomic, assign, readonly) BOOL canPlay;
@property (nonatomic, assign, readonly) BOOL isPlaying;
@property (nonatomic, assign, readonly) BOOL hasLoad;
@property (nonatomic, assign, readonly) NSTimeInterval maxPlayedTime;

// 是否加载延迟
@property (nonatomic, copy) void (^playerDelayPlay)(BOOL flag);
// 准备播放
@property (nonatomic, copy) void (^playerReadyToPlay)(void);
// 加载进度
@property (nonatomic, copy) void (^playerLoadedTimeBlock)(CGFloat progress);
// 播放进度
@property (nonatomic, copy) void (^playerCurrentTimeBlock)(CGFloat seconds);
// 总时长
@property (nonatomic, copy) void (^playerTotalTimeBlock)(CGFloat seconds);
// 播放结束
@property (nonatomic, copy) void (^playerPlayEndBlock)(void);
// 开始播放
@property (nonatomic, copy) void (^playerToPlay)(void);
// 暂停播放
@property (nonatomic, copy) void (^playerToPause)(void);
// 停止播放
@property (nonatomic, copy) void (^playerToStop)(void);
// 更换播放器
@property (nonatomic, copy) void (^playerToChangedPlayer)(void);

- (void)load;
- (void)playWithItem:(TTPlayerItem *)item autoPlay:(BOOL)autoPlay;
- (void)play;
- (void)pause;
- (void)stop;

- (CGFloat)currentTime;
- (CGFloat)totalTime;

- (int64_t)tcpSpeed;
- (void)seekToTime:(float)seconds;
- (void)seekToTime:(float)seconds completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)setLayerTransform:(CATransform3D)layerTransform animation:(BOOL)animation;

@end
