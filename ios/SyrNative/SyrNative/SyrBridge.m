//
//  SyrBridge.m
//  SyrNative
//
//  Created by Anderson,Derek on 10/5/17.
//  Copyright © 2017 Anderson,Derek. All rights reserved.
//

#import "SyrBridge.h"
#import "SyrEventHandler.h"
#import "SyrRaster.h"

@interface SyrBridge()
@property SyrEventHandler* eventHandler;
@property SyrRaster* raster;
@property WKWebView* bridgedBrowser;
@property SyrRootView* rootView;
@end

@implementation SyrBridge

- (id) init
{
  self = [super init];
  if (self!=nil) {
    // setup a 0,0,0,0 wkwebview to use the jsbridge
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    // create a js bridge
    [controller addScriptMessageHandler:self name:@"SyrNative"];
    configuration.userContentController = controller;
    _bridgedBrowser = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) configuration:configuration];
    _bridgedBrowser.navigationDelegate = self;
    _eventHandler = [[SyrEventHandler alloc] init];
    _raster = [SyrRaster sharedInstance];
    _raster.bridge = self;
  }
  return self;
}

- (id) initWithRootView: (SyrRootView*) rootView {
  self = [super init];
  if (self)
  {
    self.rootView = rootView;
    [self addView];
  }
  return self;
}
- (void) addView {
  // create a root view
  [_rootView addSubview:_bridgedBrowser];
}
- (void) loadBundle: (NSString*) withBundlePath withRootView: (SyrRootView*) rootView{
  NSLog(@"Loading Bundle");
  // pointing at the dev server for now
  NSURL *nsurl=[NSURL URLWithString:@"http://127.0.0.1:8080/?sds"];
  NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
  _rootView = rootView;
  [_bridgedBrowser loadRequest:nsrequest];
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
  NSDictionary* syrMessage = [message valueForKey:@"body"];
  NSString* messageType = [syrMessage valueForKey:@"type"];
  if([messageType containsString:@"event"]) {
    NSLog(@"Event Message Recieved, Handed to Event Handler");
  } else if([messageType containsString:@"gui"]) {
    [_raster parseAST:syrMessage withRootView:_rootView];
    NSLog(@"Render Message Recieved, Handed to Raster");
  }
}

- (void)webView:(WKWebView *)webView
didStartProvisionalNavigation:(WKNavigation *)navigation {
  NSLog(@"Loading Bundle");
  // bundle reloaded, remove all subviews from root view
 	[_rootView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
}

- (void) rasterRenderedComponent: (NSString*) withComponentId {
  [_bridgedBrowser evaluateJavaScript:@"var foo = 1; foo + 1;" completionHandler:^(id result, NSError *error) {
    if (error == nil)
    {
      if (result != nil)
      {
        NSInteger integerResult = [result integerValue]; // 2
        NSLog(@"result: %ld", (long)integerResult);
      }
    }
    else
    {
      NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
    }
  }];
}

@end
