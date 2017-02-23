//
//  RWNWebImageManager.h
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RWNImageCache.h"
#import "RWNWebImageDownloader.h"
#import "RWNWebImageCompat.h"




typedef NS_OPTIONS(NSUInteger, RWNWebImageOptions) {
    /**
     * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
     * This flag disable this blacklisting.
     */
    RWNWebImageRetryFailed = 1 << 0,
    
    /**
     * By default, image downloads are started during UI interactions, this flags disable this feature,
     * leading to delayed download on UIScrollView deceleration for instance.
     */
    RWNWebImageLowPriority = 1 << 1,
    
    /**
     * This flag disables on-disk caching
     */
    RWNWebImageCacheMemoryOnly = 1 << 2,
    
    /**
     * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
     * By default, the image is only displayed once completely downloaded.
     */
    RWNWebImageProgressiveDownload = 1 << 3,
    
    /**
     * Even if the image is cached, respect the HTTP response cache control, and refresh the image from remote location if needed.
     * The disk caching will be handled by NSURLCache instead of RWNWebImage leading to slight performance degradation.
     * This option helps deal with images changing behind the same request URL, e.g. Facebook graph api profile pics.
     * If a cached image is refreshed, the completion block is called once with the cached image and again with the final image.
     *
     * Use this flag only if you can't make your URLs static with embedded cache busting parameter.
     */
    RWNWebImageRefreshCached = 1 << 4,
    
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    RWNWebImageContinueInBackground = 1 << 5,
    
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    RWNWebImageHandleCookies = 1 << 6,
    
    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    RWNWebImageAllowInvalidSSLCertificates = 1 << 7,
    
    /**
     * By default, images are loaded in the order in which they were queued. This flag moves them to
     * the front of the queue.
     */
    RWNWebImageHighPriority = 1 << 8,
    
    /**
     * By default, placeholder images are loaded while the image is loading. This flag will delay the loading
     * of the placeholder image until after the image has finished loading.
     */
    RWNWebImageDelayPlaceholder = 1 << 9,
    
    /**
     * We usually don't call transformDownloadedImage delegate method on animated images,
     * as most transformation code would mangle it.
     * Use this flag to transform them anyway.
     */
    RWNWebImageTransformAnimatedImage = 1 << 10,
    
    /**
     * By default, image is added to the imageView after download. But in some cases, we want to
     * have the hand before setting the image (apply a filter or add it with cross-fade animation for instance)
     * Use this flag if you want to manually set the image in the completion when success
     */
    RWNWebImageAvoidAutoSetImage = 1 << 11,
    
    /**
     * By default, images are decoded respecting their original size. On iOS, this flag will scale down the
     * images to a size compatible with the constrained memory of devices.
     * If `RWNWebImageProgressiveDownload` flag is set the scale down is deactivated.
     */
    RWNWebImageScaleDownLargeImages = 1 << 12
};

typedef void(^RWNInternalCompletionBlock)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, RWNImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL);



@class RWNWebImageManager;
@protocol RWNWebImageManagerDelegate <NSObject>

@optional;

//从缓存没有找到图片 去下载图片
-(BOOL)imageManager:(RWNWebImageManager *)manager shouldDownloadImageForUrl:(NSURL *)url;


@end



@interface RWNWebImageManager : NSObject

@property(nonatomic,weak)id<RWNWebImageManagerDelegate>delegate;

///图片的缓存类
@property(nonatomic,strong,readonly)RWNImageCache * imageCache;

@property(nonatomic,copy)RWNWebImageCacheKeyFilterBlock filterBlock;

///单例初始化
+(instancetype)shareManager;
///初始化缓存和下载类
-(instancetype)initWithRWNImageCache:(RWNImageCache *)imageCache RWNWebImageDownloader:(RWNWebImageDownloader *)downloader;

@end
