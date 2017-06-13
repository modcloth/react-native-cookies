#import "RNCookieManagerIOS.h"
#if __has_include("RCTConvert.h")
#import "RCTConvert.h"
#else
#import <React/RCTConvert.h>
#endif

@implementation RNCookieManagerIOS

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(set,
    props:(NSDictionary *)props,
    resolver:(RCTPromiseResolveBlock)resolve,
    rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *name = [RCTConvert NSString:props[@"name"]];
    NSString *value = [RCTConvert NSString:props[@"value"]];
    NSString *domain = [RCTConvert NSString:props[@"domain"]];
    NSString *origin = [RCTConvert NSString:props[@"origin"]];
    NSString *path = [RCTConvert NSString:props[@"path"]];
    NSString *version = [RCTConvert NSString:props[@"version"]];
    NSDate *expiration = [RCTConvert NSDate:props[@"expiration"]];

    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:name forKey:NSHTTPCookieName];
    [cookieProperties setObject:value forKey:NSHTTPCookieValue];
    [cookieProperties setObject:domain forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:origin forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:path forKey:NSHTTPCookiePath];
    [cookieProperties setObject:version forKey:NSHTTPCookieVersion];
    [cookieProperties setObject:expiration forKey:NSHTTPCookieExpires];

    NSLog(@"SETTING COOKIE");
    NSLog(@"%@", cookieProperties);

    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

    resolve();
}

RCT_REMAP_METHOD(setFromResponse,
    url:(NSURL *)url,
    value:(NSDictionary *)value,
    resolver:(RCTPromiseResolveBlock)resolve,
    rejecter:(RCTPromiseRejectBlock)reject) {
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:value forURL:url];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:NULL];
    resolve();
}

RCT_REMAP_METHOD(getFromResponse,
    url:(NSURL *)url,
    resolver:(RCTPromiseResolveBlock)resolve,
    rejecter:(RCTPromiseRejectBlock)reject) {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request  queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:httpResponse.allHeaderFields forURL:response.URL];
        NSMutableDictionary *dics = [NSMutableDictionary dictionary];

        for (int i = 0; i < cookies.count; i++) {
            NSHTTPCookie *cookie = [cookies objectAtIndex:i];
            [dics setObject:cookie.value forKey:cookie.name];
            NSLog(@"cookie: name=%@, value=%@", cookie.name, cookie.value);
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
        resolve(dics);
    }];
}

RCT_REMAP_METHOD(get,
    url:(NSURL *) url,
    resolver:(RCTPromiseResolveBlock)resolve,
    rejecter:(RCTPromiseRejectBlock)reject) {
    NSMutableDictionary *cookies = [NSMutableDictionary dictionary];
    for (NSHTTPCookie *c in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url]) {
        [cookies setObject:c.value forKey:c.name];
    }
    resolve(cookies);
}

RCT_REMAP_METHOD(clearAll,
    resolver:(RCTPromiseResolveBlock)resolve,
    rejecter:(RCTPromiseRejectBlock)reject) {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *c in cookieStorage.cookies) {
        [cookieStorage deleteCookie:c];
    }
    resolve();
}

RCT_REMAP_METHOD(clearByName,
    name:(NSString *) name,
    resolver:(RCTPromiseResolveBlock)resolve,
    rejecter:(RCTPromiseRejectBlock)reject) {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *c in cookieStorage.cookies) {
      if ([[c name] isEqualToString:name]) {
        [cookieStorage deleteCookie:c];
      }
    }
    resolve();
}

// TODO: return a better formatted list of cookies per domain
RCT_REMAP_METHOD(getAll,
    resolver:(RCTPromiseResolveBlock)resolve,
    rejecter:(RCTPromiseRejectBlock)reject) {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableDictionary *cookies = [NSMutableDictionary dictionary];
    for (NSHTTPCookie *c in cookieStorage.cookies) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setObject:c.value forKey:@"value"];
        [d setObject:c.name forKey:@"name"];
        [d setObject:c.domain forKey:@"domain"];
        [d setObject:c.path forKey:@"path"];
        [cookies setObject:d forKey:c.name];
    }
    resolve(cookies);
}

@end
