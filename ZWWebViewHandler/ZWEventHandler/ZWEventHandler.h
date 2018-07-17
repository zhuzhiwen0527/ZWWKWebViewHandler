//
//  ZWEventHandler.h
//  ZWWebViewHandler
//
//  Created by zzw on 2018/7/17.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

extern NSString * const EventHandler;

@interface ZWEventHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) id target;
@property (nonatomic, strong) NSString  *handlerJS;

+ (instancetype)instance;

@end
