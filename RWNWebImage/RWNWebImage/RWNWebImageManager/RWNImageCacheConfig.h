//
//  RWNImageCacheConfig.h
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RWNImageCacheConfig : NSObject
/*
  下载和缓存图片的时候压缩图片会提高性能,但也会消耗大量内存
  默认为。如果你因内存消耗过大而崩溃，请将此设置为“否”
 */
@property (assign, nonatomic) BOOL shouldDecompressImages;
/**
 *  禁用iCloud备份 默认为 YES
 */
@property (assign, nonatomic) BOOL shouldDisableiCloud;
/**
 * 使用内存缓存 [默认为 YES]
 */
@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;
/**
 *  缓存的最大时间
 */
@property (assign, nonatomic) NSInteger maxCacheAge;

/**
 * 最大缓存量
 */
@property (assign, nonatomic) NSUInteger maxCacheSize;


@end
