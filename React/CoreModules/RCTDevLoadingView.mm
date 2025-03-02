/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTDevLoadingView.h>

#import <QuartzCore/QuartzCore.h>

#import <FBReactNativeSpec/FBReactNativeSpec.h>
#import <React/RCTAppearance.h>
#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTDefines.h>
#import <React/RCTDevSettings.h> // TODO(OSS Candidate ISS#2710739)
#import <React/RCTDevLoadingViewSetEnabled.h>
#if !TARGET_OS_OSX
#import <React/RCTModalHostViewController.h>
#endif // !TARGET_OS_OSX
#import <React/RCTUtils.h>
#import <React/RCTUIKit.h> // TODO(macOS GH#774)

#import "CoreModulesPlugins.h"

using namespace facebook::react;

@interface RCTDevLoadingView () <NativeDevLoadingViewSpec>
@end

#if RCT_DEV | RCT_ENABLE_LOADING_VIEW

@implementation RCTDevLoadingView {
#if !TARGET_OS_OSX // TODO(macOS GH#774)
  UIWindow *_window;
  UILabel *_label;
#else // [TODO(macOS GH#774)
  NSWindow *_window;
  NSTextField *_label;
#endif // ]TODO(macOS GH#774)
  NSDate *_showDate;
  BOOL _hiding;
  dispatch_block_t _initialMessageBlock;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (void)setEnabled:(BOOL)enabled
{
  RCTDevLoadingViewSetEnabled(enabled);
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hide)
                                               name:RCTJavaScriptDidLoadNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hide)
                                               name:RCTJavaScriptDidFailToLoadNotification
                                             object:nil];

  if (bridge.loading) {
    [self showWithURL:bridge.bundleURL];
  }
}

- (void)clearInitialMessageDelay
{
  if (self->_initialMessageBlock != nil) {
    dispatch_block_cancel(self->_initialMessageBlock);
    self->_initialMessageBlock = nil;
  }
}

- (void)showInitialMessageDelayed:(void (^)())initialMessage
{
  self->_initialMessageBlock = dispatch_block_create(static_cast<dispatch_block_flags_t>(0), initialMessage);

  // We delay the initial loading message to prevent flashing it
  // when loading progress starts quickly. To do that, we
  // schedule the message to be shown in a block, and cancel
  // the block later when the progress starts coming in.
  // If the progress beats this timer, this message is not shown.
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), self->_initialMessageBlock);
}

#if 0 // TODO(macOS GH#774)
// Blocked out because -[(NS|UI)Color getHue:saturation:brightness:alpha:] has
// different return values on macOS and iOS.
// The call to dimColor: was removed with f0dfd35108dd3f092d46b65e77560c35477bf6ba,
// and we don't use it anywhere else, so we should probably remove this upstream too.
- (RCTUIColor *)dimColor:(RCTUIColor *)c
{
  // Given a color, return a slightly lighter or darker color for dim effect.
  CGFloat h, s, b, a;
  if ([c getHue:&h saturation:&s brightness:&b alpha:&a])
    return [RCTUIColor colorWithHue:h saturation:s brightness:b < 0.5 ? b * 1.25 : b * 0.75 alpha:a];
  return nil;
}
#endif // TODO(macOS GH#774)

- (NSString *)getTextForHost
{
  if (self->_bridge.bundleURL == nil || self->_bridge.bundleURL.fileURL) {
    return @"React Native";
  }

  return [NSString stringWithFormat:@"%@:%@", self->_bridge.bundleURL.host, self->_bridge.bundleURL.port];
}

- (void)showMessage:(NSString *)message color:(RCTUIColor *)color backgroundColor:(RCTUIColor *)backgroundColor // TODO(OSS Candidate ISS#2710739)
{
  if (!RCTDevLoadingViewGetEnabled() || self->_hiding) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    self->_showDate = [NSDate date];
    if (!self->_window && !RCTRunningInTestEnvironment()) {
#if !TARGET_OS_OSX // TODO(macOS GH#774)
      CGSize screenSize = [UIScreen mainScreen].bounds.size;

      if (@available(iOS 11.0, *)) {
        UIWindow *window = RCTSharedApplication().keyWindow;
        self->_window =
            [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, window.safeAreaInsets.top + 10)];
        self->_label =
            [[UILabel alloc] initWithFrame:CGRectMake(0, window.safeAreaInsets.top - 10, screenSize.width, 20)];
      } else {
        self->_window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, 20)];
        self->_label = [[UILabel alloc] initWithFrame:self->_window.bounds];
      }
      [self->_window addSubview:self->_label];

      self->_window.windowLevel = UIWindowLevelStatusBar + 1;
      // set a root VC so rotation is supported
      self->_window.rootViewController = [UIViewController new];

      self->_label.font = [UIFont monospacedDigitSystemFontOfSize:12.0 weight:UIFontWeightRegular];
      self->_label.textAlignment = NSTextAlignmentCenter;
#elif TARGET_OS_OSX // [TODO(macOS GH#774)
      NSRect screenFrame = [NSScreen mainScreen].visibleFrame;
      self->_window = [[NSPanel alloc] initWithContentRect:NSMakeRect(screenFrame.origin.x + round((screenFrame.size.width - 375) / 2), screenFrame.size.height - 20, 375, 19)
                                                 styleMask:NSWindowStyleMaskBorderless
                                                   backing:NSBackingStoreBuffered
                                                     defer:YES];
      self->_window.releasedWhenClosed = NO;
      self->_window.backgroundColor = [NSColor clearColor];

      NSTextField *label = [[NSTextField alloc] initWithFrame:self->_window.contentView.bounds];
      label.alignment = NSTextAlignmentCenter;
      label.bezeled = NO;
      label.editable = NO;
      label.selectable = NO;
      label.wantsLayer = YES;
      label.layer.cornerRadius = label.frame.size.height / 3;
      self->_label = label;
      [[self->_window contentView] addSubview:label];
#endif // ]TODO(macOS GH#774)
    }

#if !TARGET_OS_OSX // TODO(macOS GH#774)
    self->_label.text = message;
    self->_label.textColor = color;

    self->_window.backgroundColor = backgroundColor;
    self->_window.hidden = NO;
#else // [TODO(macOS GH#774)
    self->_label.stringValue = message;
    self->_label.textColor = color;
    self->_label.backgroundColor = backgroundColor;
    [self->_window orderFront:nil];
#endif // ]TODO(macOS GH#774)

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && defined(__IPHONE_13_0) && \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
      UIWindowScene *scene = (UIWindowScene *)RCTSharedApplication().connectedScenes.anyObject;
      self->_window.windowScene = scene;
    }
#endif
  });
}

RCT_EXPORT_METHOD(showMessage
                  : (NSString *)message withColor
                  : (NSNumber *__nonnull)color withBackgroundColor
                  : (NSNumber *__nonnull)backgroundColor)
{
  [self showMessage:message color:[RCTConvert UIColor:color] backgroundColor:[RCTConvert UIColor:backgroundColor]];
}

RCT_EXPORT_METHOD(hide)
{
  if (!RCTDevLoadingViewGetEnabled()) {
    return;
  }

  // Cancel the initial message block so it doesn't display later and get stuck.
  [self clearInitialMessageDelay];

  dispatch_async(dispatch_get_main_queue(), ^{
    self->_hiding = true;
    const NSTimeInterval MIN_PRESENTED_TIME = 0.6;
    NSTimeInterval presentedTime = [[NSDate date] timeIntervalSinceDate:self->_showDate];
    NSTimeInterval delay = MAX(0, MIN_PRESENTED_TIME - presentedTime);
#if !TARGET_OS_OSX // TODO(macOS GH#774)
    CGRect windowFrame = self->_window.frame;
    [UIView animateWithDuration:0.25
        delay:delay
        options:0
        animations:^{
          self->_window.frame = CGRectOffset(windowFrame, 0, -windowFrame.size.height);
        }
        completion:^(__unused BOOL finished) {
          self->_window.frame = windowFrame;
          self->_window.hidden = YES;
          self->_window = nil;
          self->_hiding = false;
        }];
#elif TARGET_OS_OSX // [TODO(macOS GH#774)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [NSAnimationContext runAnimationGroup:^(__unused NSAnimationContext *context) {
        self->_window.animator.alphaValue = 0.0;
      } completionHandler:^{
        [self->_window orderFront:self];
        self->_window = nil;
      }];
    });
#endif // ]TODO(macOS GH#774)
  });
}

- (void)showProgressMessage:(NSString *)message
{
  if (self->_window != nil) {
    // This is an optimization. Since the progress can come in quickly,
    // we want to do the minimum amount of work to update the UI,
    // which is to only update the label text.
#if !TARGET_OS_OSX // TODO(macOS GH#774)
    self->_label.text = message;
#else // [TODO(macOS GH#774)
    self->_label.stringValue = message;
#endif // ]TODO(macOS GH#774)
    return;
  }

  RCTUIColor *color = [RCTUIColor whiteColor]; // TODO(macOS GH#774)
  RCTUIColor *backgroundColor = [RCTUIColor colorWithHue:105 saturation:0 brightness:.25 alpha:1]; // TODO(macOS GH#774)

  if ([self isDarkModeEnabled]) {
    color = [RCTUIColor colorWithHue:208 saturation:0.03 brightness:.14 alpha:1]; // TODO(macOS GH#774)
    backgroundColor = [RCTUIColor colorWithHue:0 saturation:0 brightness:0.98 alpha:1]; // TODO(macOS GH#774)
  }

  [self showMessage:message color:color backgroundColor:backgroundColor];
}

- (void)showOfflineMessage
{
  RCTUIColor *color = [RCTUIColor whiteColor]; // TODO(macOS GH#774)
  RCTUIColor *backgroundColor = [RCTUIColor blackColor]; // TODO(macOS GH#774)

  if ([self isDarkModeEnabled]) {
    color = [RCTUIColor blackColor]; // TODO(macOS GH#774)
    backgroundColor = [RCTUIColor whiteColor]; // TODO(macOS GH#774)
  }

  NSString *message = [NSString stringWithFormat:@"Connect to %@ to develop JavaScript.", RCT_PACKAGER_NAME];
  [self showMessage:message color:color backgroundColor:backgroundColor];
}

- (BOOL)isDarkModeEnabled
{
  // We pass nil here to match the behavior of the native module.
  // If we were to pass a view, then it's possible that this native
  // banner would have a different color than the JavaScript banner
  // (which always passes nil). This would result in an inconsistent UI.
  return [RCTColorSchemePreference(nil) isEqualToString:@"dark"];
}
- (void)showWithURL:(NSURL *)URL
{
  if (URL.fileURL) {
    // If dev mode is not enabled, we don't want to show this kind of notification.
#if !RCT_DEV
    return;
#endif
    [self showOfflineMessage];
  } else {
    [self showInitialMessageDelayed:^{
      NSString *message = [NSString stringWithFormat:@"Loading from %@\u2026", RCT_PACKAGER_NAME];
      [self showProgressMessage:message];
    }];
  }
}

- (void)updateProgress:(RCTLoadingProgress *)progress
{
  if (!progress) {
    return;
  }

  // Cancel the initial message block so it's not flashed before progress.
  [self clearInitialMessageDelay];

  dispatch_async(dispatch_get_main_queue(), ^{
    [self showProgressMessage:[progress description]];
  });
}

- (std::shared_ptr<TurboModule>)getTurboModule:(const ObjCTurboModule::InitParams &)params
{
  return std::make_shared<NativeDevLoadingViewSpecJSI>(params);
}

@end

#else

@implementation RCTDevLoadingView

+ (NSString *)moduleName
{
  return nil;
}
+ (void)setEnabled:(BOOL)enabled
{
}
- (void)showMessage:(NSString *)message color:(RCTUIColor *)color backgroundColor:(RCTUIColor *)backgroundColor // TODO(macOS GH#774) RCTUIColor
{
}
- (void)showMessage:(NSString *)message withColor:(NSNumber *)color withBackgroundColor:(NSNumber *)backgroundColor
{
}
- (void)showWithURL:(NSURL *)URL
{
}
- (void)updateProgress:(RCTLoadingProgress *)progress
{
}
- (void)hide
{
}
- (std::shared_ptr<TurboModule>)getTurboModule:(const ObjCTurboModule::InitParams &)params
{
  return std::make_shared<NativeDevLoadingViewSpecJSI>(params);
}

@end

#endif

Class RCTDevLoadingViewCls(void)
{
  return RCTDevLoadingView.class;
}
