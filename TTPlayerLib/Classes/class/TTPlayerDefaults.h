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

@property (nonatomic, assign) BOOL      allowShowLog;
@property (nonatomic, assign) NSInteger currentNetworkStatus;

@property (nonatomic, assign) BOOL allowToPlay;
@property (nonatomic, assign) BOOL downloading;

+ (TTPlayerDefaults *)standardDefaults;

@end
