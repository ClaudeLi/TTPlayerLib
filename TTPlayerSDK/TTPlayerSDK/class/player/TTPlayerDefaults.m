//
//  TTPlayerDefaults.m
//  TTPlayerLib
//
//  Created by ClaudeLi on 2018/1/6.
//  Copyright © 2018年 ClaudeLi. All rights reserved.
//

#import "TTPlayerDefaults.h"
#import "TTPlayerServer.h"

static TTPlayerDefaults *manager;
@implementation TTPlayerDefaults

+ (TTPlayerDefaults *)standardDefaults {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TTPlayerDefaults alloc] init];
        manager.currentNetworkStatus = -1;
    });
    return manager;
}

@end
