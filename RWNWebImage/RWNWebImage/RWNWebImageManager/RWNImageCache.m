//
//  RWNImageCache.m
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import "RWNImageCache.h"
#import "AppDelegate.h"
#import <CommonCrypto/CommonDigest.h>

@interface AutoPureCache : NSCache

@end
@implementation AutoPureCache

-(instancetype)init{

    if (self=[super init]) {
        //收到内存警告删除所有的缓存
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

-(void)dealloc{

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end



@interface RWNImageCache ()

///
@property(nonatomic,strong)NSCache * memCache;

///串行组
@property(nonatomic,strong)dispatch_queue_t ioQueue;

///硬盘的存储路径
@property(nonatomic,copy)NSString * diskPath;

@end


@implementation RWNImageCache{

    NSFileManager * _fileManger;

}


+(instancetype)shareCache{

    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance=[self new];
    });
    return instance;
}


-(instancetype)init{

    return [self initWithNameSpac:@"#defaltCache"];
}


-(instancetype)initWithNameSpac:(NSString *)name{

    NSString *path =[self getCachePathWithName:name];
    
    return [self initWithNameSpace:name diskCachePathDirectory:path];
    
}

///获取缓存的路径
-(NSString *)getCachePathWithName:(NSString *)name{

    NSArray<NSString *> *paths=NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    return [paths[0] stringByAppendingPathComponent:name];

}

-(instancetype)initWithNameSpace:(NSString *)name diskCachePathDirectory:(NSString*)directory{

    if (self=[super init]) {
        
        NSString *fullNamespace = [@"com.RWN.RWNWebImageCache." stringByAppendingString:name];
        
       // 生成一个串行队列
        _ioQueue = dispatch_queue_create("com.RWN.RWNWebImageCache.", DISPATCH_QUEUE_SERIAL);
        
        _config=[RWNImageCacheConfig new];
        
        _memCache=[[AutoPureCache alloc] init];
        _memCache.name=fullNamespace;
        
        if (directory!=nil) {
            _diskPath=[directory stringByAppendingPathComponent:fullNamespace];
        }else{
        
           NSString *path = [self getCachePathWithName:name];
            _diskPath=path;
        }
        
        dispatch_async(_ioQueue, ^{
            _fileManger=[NSFileManager new];
        });
        
        ///省略了接到内存警告 进入后台等 清除缓存的方法
        
    }
    return self;
}

//获取内存缓存
-(nullable UIImage *)getMemeryCacheByKey:(NSString *)key{

   return  [self.memCache objectForKey:key];
    
}
//获取内存缓存
-(void)getMemeryCacheByKey:(NSString *)key completeBloc:(RWNWebImageCheckCacheCompleteBlock)complte{
    
   BOOL isInMemeryCache =  ([self.memCache objectForKey:key]!=nil);
    complte(isInMemeryCache);
}
//获取硬盘缓存
-(void)getDiskCacheByKey:(NSString *)key completeBloc:(RWNWebImageCheckCacheCompleteBlock)complte{
   
    dispatch_async(_ioQueue, ^{
        //获取全路径的
      BOOL exist = [_fileManger fileExistsAtPath:[self defaultCachePathForKey:key]];
       // 截取最后一个/后面的内容  eg:@"/Users/LJH/Desktop/Lion.txt"改变之后就是 @"/Users/LJH/Desktop"
        if (!exist) {
          exist = [_fileManger fileExistsAtPath:[self defaultCachePathForKey:key].stringByDeletingPathExtension];
        }
        
        if (complte) {
      
            dispatch_async(dispatch_get_main_queue(), ^{
                
                complte(exist);
                
            });
            
        }
    });
   
}

//名称通过MD5进行加密 生成一个地址 缓存这个图片
- (nullable NSString *)defaultCachePathForKey:(nullable NSString *)key {
    return [self cachePathForKey:key inPath:self.diskPath];
}
- (nullable NSString *)cachePathForKey:(nullable NSString *)key inPath:(nonnull NSString *)path {
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}
- (nullable NSString *)cachedFileNameForKey:(nullable NSString *)key {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [key.pathExtension isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", key.pathExtension]];
    
    return filename;
}

-(NSOperation *)searchImageInCacheWithKey:(NSString *)key RWNSearchBloc:(RWNWebImageCacheSearchBlock)searchBlock{

    if (!key) {
        if (searchBlock) {
            searchBlock(nil,nil,RWNImageCacheTypeNone);
        }
        return nil;
    }
    
    
    UIImage *image=[self getMemeryCacheByKey:key];
    if (image) {
        
        NSData *diskData=nil;
        searchBlock(image,diskData,RWNImageCacheTypeMemory);
        return nil;
        
    }
    
    NSOperation *operation=[NSOperation new];
    dispatch_async(_ioQueue, ^{
       
        if (operation.cancelled) {
            return ;
        }
        
        NSData  * diskData  =  [self getDiskDataByKey:key];
        UIImage * diskImage     =  [self getDiskImageByKey:key];
        //进行内存缓存
        if (diskImage && self.config.shouldCacheImagesInMemory ) {

            [self.memCache setObject:diskImage forKey:key];

        }
        
        if (searchBlock) {
         searchBlock(image,diskData,RWNImageCacheTypeDisk);
        }

       
    });
    
    return operation;
}

-(NSData *)getDiskDataByKey:(NSString *)key{

    NSString *path =  [self defaultCachePathForKey:key];
    NSData *data =[NSData dataWithContentsOfFile:path];
    
    if (!data) {
        
       NSString *deltePath = [self defaultCachePathForKey:key].stringByDeletingLastPathComponent;
       data =[NSData dataWithContentsOfFile:deltePath];
        
    }
    
    //还有一个去自定义路径查询的
    return data;

}

-(UIImage *)getDiskImageByKey:(NSString *)key{

    NSData *data = [self getDiskDataByKey:key];
    //通过data 获取不同类型的图片 然后不同类型的加载 然后进行压缩
    UIImage * image=[UIImage imageWithData:data];
    
    return image;
    
}






@end
