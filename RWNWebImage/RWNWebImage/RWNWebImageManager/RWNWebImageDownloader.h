//
//  RWNWebImageDownloader.h
//  RWNWebImage
//
//  Created by RWN on 17/2/22.
//  Copyright © 2017年 RWN. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SDWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);


@interface RWNWebImageDownloadToken : NSObject

@property (nonatomic, strong, nullable) NSURL *url;
@property (nonatomic, strong, nullable) id downloadOperationCancelToken;

@end



@interface RWNWebImageDownloader : NSObject

+(nullable instancetype)shareDownloader;

@end
