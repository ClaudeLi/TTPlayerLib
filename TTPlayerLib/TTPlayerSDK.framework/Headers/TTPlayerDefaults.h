//
//  TTPlayerDefaults.h
//  TTPlayerLib
//
//  Created by ClaudeLi on 2018/1/6.
//  Copyright © 2018年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TTPlayerStandard   [TTPlayerDefaults standardDefaults]

@interface TTPlayerDefaults : NSObject

/**
 当前网路状态=AFNetworkReachabilityStatus
 */
@property (nonatomic, assign) NSInteger currentNetworkStatus;

@property (nonatomic, assign) BOOL allowShowLog;
    
@property (nonatomic, assign) BOOL allowToPlay;
@property (nonatomic, assign) BOOL downloading;

@property (nonatomic, assign) BOOL allowMirror;
@property (nonatomic, assign) BOOL allowItemsLoop;
@property (nonatomic, assign) BOOL allowOnceLoop;
    
+ (TTPlayerDefaults *)standardDefaults;

@end
