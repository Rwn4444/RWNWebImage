//
//  RWNImageCacheConfig.m
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import "RWNImageCacheConfig.h"

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

@implementation RWNImageCacheConfig

-(instancetype)init{

    if (self=[super init]) {
        
        _shouldDecompressImages=YES;
        _shouldDisableiCloud=YES;
        _shouldCacheImagesInMemory=YES;
        _maxCacheAge=kDefaultCacheMaxCacheAge;
        _maxCacheSize=0;
        
    }
    return self;
}



@end
