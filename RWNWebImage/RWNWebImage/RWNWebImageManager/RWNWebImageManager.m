//
//  RWNWebImageManager.m
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import "RWNWebImageManager.h"
#import "RWNWebImageOperation.h"

@interface RWNWebImageCombinedOperation : NSObject <RWNWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (copy, nonatomic, nullable)RWNWebImageNoParamsBlock cancelBlock;
@property (strong, nonatomic, nullable) NSOperation *cacheOperation;

@end


@interface RWNWebImageManager ()

///图片的缓存类
@property(nonatomic,strong,readwrite)RWNImageCache * imageCache;
///图片的下载类
@property(nonatomic,strong)RWNWebImageDownloader * downloader;
///失败的Url集合
@property(nonatomic,strong)NSMutableSet <NSURL *> * failedUrls;
///正在运行的线程
@property(nonatomic,strong)NSMutableArray<RWNWebImageCombinedOperation *> *runningOperations;


@end


@implementation RWNWebImageManager

+(instancetype)shareManager{

    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance=[self new];
    });
    return instance;
}

-(instancetype)init{

    RWNImageCache *imageCache=[RWNImageCache shareCache];
    RWNWebImageDownloader *downloader=[RWNWebImageDownloader shareDownloader];
    return [self initWithRWNImageCache:imageCache RWNWebImageDownloader:downloader];

}

-(instancetype)initWithRWNImageCache:(RWNImageCache *)imageCache RWNWebImageDownloader:(RWNWebImageDownloader *)downloader{

    if (self=[super init]) {
       
        _imageCache=imageCache;
        _downloader=downloader;
        _failedUrls=[NSMutableSet set];
        _runningOperations=[NSMutableArray array];
        
    }
    return self;
}

///通过Url获取一个缓存的key
-(NSString *)cacheKeyForUrl:(NSURL *)url{

    if (!url) { return @"" ;}

    //感觉这个block没用 不明白
    if (self.filterBlock) {
        return self.filterBlock(url);
    }else{
        return [url absoluteString];
    }
    
}
///主要返回 内存 和 硬盘 内是否有这个图片的缓存
-(void)cacheImageExistsForUrl:(NSURL *)url completeBlock:(RWNWebImageCheckCacheCompleteBlock)completeBlock{

    //获取缓存的key
    NSString *cacheKey=[self cacheKeyForUrl:url];
    //查看内存里是否有这个图片
    /*
    BOOL isInMemeryCache=([self.imageCache getMemeryCacheByKey:cacheKey]!=nil);
    
    if (isInMemeryCache) {
        //如果有 返回Yes
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(YES);
        });
        return;
    }
    */
    //自己改成返回为block的方法
    [self.imageCache getMemeryCacheByKey:cacheKey completeBloc:^(BOOL isInCache) {
        
       
        if (isInCache) {
          
            if (completeBlock) {
                //如果有 返回Yes
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock(YES);
                });
                return;
            }
            
        }
       
        
        
     
        
    }];
    
    //内存里面没有 看硬盘里是否有这个图片
    [self.imageCache getDiskCacheByKey:cacheKey completeBloc:^(BOOL isInCache) {
       
        if (isInCache) {
            
            if (completeBlock) {
             
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock(YES);
                });
                
            }
            
            
        }
        
        
    }];

}

//在硬盘上 是否有这个图片
-(void)diskImageExistsForURl:(NSURL *)url complter:(RWNWebImageCheckCacheCompleteBlock)complte{

    NSString *key =[self cacheKeyForUrl:url];
    [self.imageCache getDiskCacheByKey:key completeBloc:^(BOOL isInCache) {
       
        if (complte) {
            
            complte(isInCache);
        }
    }];

}

-(id<RWNWebImageOperation>)downloaderImageWithUrl:(NSURL *)url
                                          options:(RWNWebImageOptions)options
                                          progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                          completion:(RWNInternalCompletionBlock)completion
                                         {

    
    if ([url isKindOfClass:[NSString class]]) {
        url=[NSURL URLWithString:(NSString *)url];
    }

    if (![url isKindOfClass:[NSURL class]]) {
        url=nil;
    }
    
    __block RWNWebImageCombinedOperation *operation=[RWNWebImageCombinedOperation new];
    __weak RWNWebImageCombinedOperation *weakOperation=operation;
    
    BOOL isFailedUrl=NO;
    
    if (url) {
        
        @synchronized (self.failedUrls) {
            isFailedUrl=[self.failedUrls containsObject:url];
        }
        
    }
    
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];
    }
    
    NSString *key =[self cacheKeyForUrl:url];
    
    operation.cacheOperation=[self.imageCache searchImageInCacheWithKey:key RWNSearchBloc:^(UIImage *image, NSData *imageData, RWNImageCacheType cacheType) {
       
        if (operation.isCancelled) {
            //如果线程被取消 移除保存的线程
            [self safeRemoveFromRunningOperation:operation];
            return ;
        }
        
        
        //如果没有 图片  或者是刷新缓存类型的 就得重新下载 
        if (((!image || options & RWNWebImageRefreshCached)&&[self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForUrl:)]) ||[self.delegate imageManager:self shouldDownloadImageForUrl:url]) {
            
            //如果有图片 并且为刷新缓存的策略 先返回图片
            if (image && options&RWNWebImageRefreshCached ) {
                
                [self callCompletionBlockForOperation:operation completion:completion image:image data:imageData error:nil cacheTye:cacheType  finished:YES url:url];
            }
            
        }
        
        
        
    }];
    
    
    return nil;
}

-(void)safeRemoveFromRunningOperation:(RWNWebImageCombinedOperation *)combinedOperation{

    @synchronized (self.runningOperations) {
        
        if (combinedOperation) {
            [self.runningOperations removeObject:combinedOperation];
        }
    }

}


-(void)callCompletionBlockForOperation:(RWNWebImageCombinedOperation *)operation completion:(RWNInternalCompletionBlock)completion image:(UIImage *)image data:(NSData *)data  error:(NSError*)error cacheTye:(RWNImageCacheType)cacheType finished:(BOOL)finish url:(NSURL *)url{

    if (operation && !operation.isCancelled && completion ) {
        completion(image,data,error,cacheType,YES,url);
    }
    

}



-(void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url{

    if (image&&url) {
        NSString *key=[self cacheKeyForUrl:url];
//        [self.imageCache ]
    }
    
}





@end
