//
//  ZWEventHandler.m
//  ZWWebViewHandler
//
//  Created by zzw on 2018/7/17.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ZWEventHandler.h"
#if DEBUG
#define ZWLog(FORMAT, ...) fprintf(stderr,"\nfunction:%s line:%d content:%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define ZWLog(FORMAT, ...) nil
#endif
 NSString * const EventHandler = @"ZWEventHandler";

@interface ZWEventHandlerEmptyObject :NSObject

@end

@implementation ZWEventHandlerEmptyObject

@end

@implementation ZWEventHandler

+ (instancetype)instance{

    ZWEventHandler * handler  = [[self alloc] init];
    handler.handlerJS = [handler getJsString];
    return handler;

}
- (NSString *)getJsString{

    NSString *path =[[NSBundle bundleForClass:[self class]] pathForResource:@"ZWEventHandler" ofType:@"js"];
    NSString *handlerJS = [NSString stringWithContentsOfFile:path encoding:kCFStringEncodingUTF8 error:nil];
    handlerJS = [handlerJS stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return handlerJS;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    // NSLog(@"message :%@",message.body);
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wincompatible-pointer-types-discards-qualifiers"
    if ([message.name isEqualToString:EventHandler]) {
#pragma clang diagnostic pop
        NSString *methodName = message.body[@"methodName"];
        NSDictionary *params = message.body[@"params"];

        NSString *type = message.body[@"type"];
        if ([type isEqualToString:@"CallBackFunction"]) {
            NSString *successCallBackID = message.body[@"successCallBackID"];
            NSString *failureCallBackID = message.body[@"failureCallBackID"];
            __weak typeof(self) weakSelf = self;
            [self newInteractWitMethodName:methodName params:params success:^(id response) {
                [weakSelf _zwCallJSCallBackWithCallBackName:successCallBackID response:response];
            } failure:^(id response) {
                [weakSelf _zwCallJSCallBackWithCallBackName:failureCallBackID response:response];
            }];
        }else{

            NSString *callBackName = message.body[@"callBackID"];
            if (callBackName) {
                __weak typeof(self) weakSelf = self;
                [self interactWitMethodName:methodName params:params :^(id response) {

                    [weakSelf _zwCallJSCallBackWithCallBackName:callBackName response:response];
                }];
            }else{
                [self interactWitMethodName:methodName params:params :nil];
            }
        }

    }


}


- (void)interactWitMethodName:(NSString *)methodName params:(NSDictionary *)params :(void(^)(id response))callBack{

    if (params) {
        methodName = [NSString stringWithFormat:@"%@:",methodName];
        if (callBack) {
            methodName = [NSString stringWithFormat:@"%@:",methodName];
            SEL selector =NSSelectorFromString(methodName);
            NSArray *paramArray =@[params,callBack];
            if ([self.target respondsToSelector:selector]) {
                [self _zwPerformSelector:selector withObjects:paramArray];
            }
        }else{
            SEL selector =NSSelectorFromString(methodName);
            NSArray *paramArray =@[params];
            if ([self.target respondsToSelector:selector]) {
                NSLog(@"是否调用");
                [self _zwPerformSelector:selector withObjects:paramArray];

            }
        }
    }else{

        if (callBack) {
            methodName = [NSString stringWithFormat:@"%@:",methodName];
            SEL selector =NSSelectorFromString(methodName);
            NSArray *paramArray =@[callBack];
            if ([self.target respondsToSelector:selector]) {
                [self _zwPerformSelector:selector withObjects:paramArray];
            }
        }else{
            SEL selector =NSSelectorFromString(methodName);

            if ([self.target respondsToSelector:selector]) {

                [self _zwPerformSelector:selector withObjects:nil];

            }
        }
    }
}

- (void)newInteractWitMethodName:(NSString *)methodName params:(NSDictionary *)params success:(void(^)(id response))successCallBack failure:(void(^)(id response))failureCallBack{
    if (params) {
        methodName = [NSString stringWithFormat:@"%@:",methodName];

        methodName = [NSString stringWithFormat:@"%@::",methodName];
        SEL selector =NSSelectorFromString(methodName);
        id successBlock=nil;
        if (successCallBack) {
            successBlock = successCallBack;
        }else{
            successBlock = [ZWEventHandlerEmptyObject class];
        }

        id failureBlock=nil;
        if (failureCallBack) {
            failureBlock = failureCallBack;
        }else{
            failureBlock = [ZWEventHandlerEmptyObject class];
        }
        NSArray *paramArray =@[params,successBlock,failureBlock];
        if ([self.target respondsToSelector:selector]) {
            [self _zwPerformSelector:selector withObjects:paramArray];
        }


    }
}

- (id)_zwPerformSelector:(SEL)aSelector withObjects:(NSArray *)objects {

    if (self.target) {

        NSMethodSignature *signature = [self.target methodSignatureForSelector:aSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self.target];
        [invocation setSelector:aSelector];

        NSUInteger i = 1;

        for (id object in objects) {
            id tempObject = object;
            if (![tempObject isKindOfClass:[NSObject class]]) {
                if ([tempObject isSubclassOfClass:[ZWEventHandlerEmptyObject class]]) {
                    tempObject = nil;
                }
            }
            [invocation setArgument:&tempObject atIndex:++i];
        }
        [invocation invoke];

        if ([signature methodReturnLength]) {
            id data;
            [invocation getReturnValue:&data];
            return data;
        }
    }

    return nil;
}

- (void)_zwCallJSCallBackWithCallBackName:(NSString *)callBackName response:(id)response{
    __weak  WKWebView *weakWebView = _webView;
    NSString *js = [NSString stringWithFormat:@"ZWEventHandler.callBack('%@','%@');",callBackName,response];
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
            ZWLog(@"ZWEventHandler.callBack: %@\n response: %@",callBackName,response);
        }];
    });
}


@end
