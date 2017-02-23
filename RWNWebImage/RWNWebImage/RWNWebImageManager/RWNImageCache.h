//
//  RWNImageCache.h
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RWNImageCacheConfig.h"


typedef NS_ENUM(NSInteger ,RWNImageCacheType ) {

    RWNImageCacheTypeNone,
    RWNImageCacheTypeMemory,
    RWNImageCacheTypeDisk,

};


///判断某个图片是否在 内存 或者 硬盘 中缓存
typedef void(^RWNWebImageCheckCacheCompleteBlock)(BOOL isInCache);

typedef NSString *(^RWNWebImageCacheKeyFilterBlock)(NSURL * url);

typedef void(^RWNWebImageCacheSearchBlock)(UIImage *image,NSData *imageData,RWNImageCacheType cacheType) ;

@interface RWNImageCache : NSObject

@property(nonatomic,nullable,readonly)RWNImageCacheConfig * config;


+(nonnull instancetype)shareCache;
-(nonnull instancetype)initWithNameSpac:(nonnull NSString *)name;
-(nonnull instancetype)initWithNameSpace:(nonnull NSString *)name diskCachePathDirectory:(nonnull NSString*)directory;
//通过key来获取内存内的图片
-(nullable UIImage *)getMemeryCacheByKey:(nullable NSString *)key;
-(void)getMemeryCacheByKey:(nullable NSString *)key completeBloc:(RWNWebImageCheckCacheCompleteBlock)complte;

//通过key来获取硬盘缓存
-(void)getDiskCacheByKey:(NSString *)key completeBloc:(RWNWebImageCheckCacheCompleteBlock)complte;

//查看是否有缓存
-(NSOperation *)searchImageInCacheWithKey:(NSString *)key RWNSearchBloc:(RWNWebImageCacheSearchBlock)searchBlock;

//通过key来查询 这个图片的data
-(NSData *)getDiskDataByKey:(NSString *)key;
//通过key来查询 这个图片的data
-(UIImage *)getDiskImageByKey:(NSString *)key;


//-(void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk completion:(RWNWebImageNoParamsBlock)completion;


@end
