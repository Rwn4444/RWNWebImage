//
//  RWNWebImageDownloader.m
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import "RWNWebImageDownloader.h"


@implementation RWNWebImageDownloadToken
@end


@implementation RWNWebImageDownloader

+(instancetype)shareDownloader{

    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance=[self new];
    });
    return instance;
}


@end
