/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTDeviceInfo.h"

#import <FBReactNativeSpec/FBReactNativeSpec.h>
#import <React/RCTAccessibilityManager.h>
#import <React/RCTAssert.h>
#import <React/RCTConstants.h>
#import <React/RCTEventDispatcherProtocol.h>
#import <React/RCTUIKit.h> // TODO(macOS GH#774)
#import <React/RCTUIUtils.h>
#import <React/RCTUtils.h>
#import "UIView+React.h" // TODO(macOS GH#774)

#import "CoreModulesPlugins.h"

using namespace facebook::react;

@interface RCTDeviceInfo () <NativeDeviceInfoSpec>
@end

@implementation RCTDeviceInfo {
#if !TARGET_OS_OSX // TODO(macOS GH#774)
  UIInterfaceOrientation _currentInterfaceOrientation;
  NSDictionary *_currentInterfaceDimensions;
#endif
}

@synthesize bridge = _bridge;
@synthesize turboModuleRegistry = _turboModuleRegistry;

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;

#if !TARGET_OS_OSX // TODO(macOS GH#774)
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didReceiveNewContentSizeMultiplier)
                                               name:RCTAccessibilityManagerDidUpdateMultiplierNotification
                                             object:_bridge.accessibilityManager];

  _currentInterfaceOrientation = [RCTSharedApplication() statusBarOrientation];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(interfaceOrientationDidChange)
                                               name:UIApplicationDidChangeStatusBarOrientationNotification
                                             object:nil];

  _currentInterfaceDimensions = RCTExportedDimensions(_bridge, _turboModuleRegistry);

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(interfaceFrameDidChange)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(interfaceFrameDidChange)
                                               name:RCTUserInterfaceStyleDidChangeNotification
                                             object:nil];
#endif // TODO(macOS GH#774)
}

static BOOL RCTIsIPhoneX()
{
  static BOOL isIPhoneX = NO;
#if !TARGET_OS_OSX // TODO(macOS GH#774)
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    RCTAssertMainQueue();

    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
    CGSize iPhoneXScreenSize = CGSizeMake(1125, 2436);
    CGSize iPhoneXMaxScreenSize = CGSizeMake(1242, 2688);
    CGSize iPhoneXRScreenSize = CGSizeMake(828, 1792);

    isIPhoneX = CGSizeEqualToSize(screenSize, iPhoneXScreenSize) ||
        CGSizeEqualToSize(screenSize, iPhoneXMaxScreenSize) || CGSizeEqualToSize(screenSize, iPhoneXRScreenSize);
  });
#endif // TODO(macOS GH#774)
  return isIPhoneX;
}

#if !TARGET_OS_OSX // [TODO(macOS GH#774)
static NSDictionary *RCTExportedDimensions(RCTBridge *bridge, id<RCTTurboModuleRegistry> turboModuleRegistry)
#else
NSDictionary *RCTExportedDimensions(RCTPlatformView *rootView)
#endif // ]TODO(macOS GH#774)
{
  RCTAssertMainQueue();

#if !TARGET_OS_OSX // TODO(macOS GH#774)
  RCTDimensions dimensions;
  if (bridge) {
    dimensions = RCTGetDimensions(bridge.accessibilityManager.multiplier ?: 1.0);
  } else if (turboModuleRegistry) {
    dimensions = RCTGetDimensions(
        ((RCTAccessibilityManager *)[turboModuleRegistry moduleForName:"RCTAccessibilityManager"]).multiplier ?: 1.0);
  } else {
    RCTAssert(false, @"Bridge or TurboModuleRegistry must be set to properly init dimensions.");
  }
#else // [TODO(macOS GH#774)
  RCTDimensions dimensions = RCTGetDimensions(rootView);
#endif // ]TODO(macOS GH#774)

  __typeof(dimensions.window) window = dimensions.window;
  NSDictionary<NSString *, NSNumber *> *dimsWindow = @{
    @"width" : @(window.width),
    @"height" : @(window.height),
    @"scale" : @(window.scale),
    @"fontScale" : @(window.fontScale)
  };
  __typeof(dimensions.screen) screen = dimensions.screen;
  NSDictionary<NSString *, NSNumber *> *dimsScreen = @{
    @"width" : @(screen.width),
    @"height" : @(screen.height),
    @"scale" : @(screen.scale),
    @"fontScale" : @(screen.fontScale)
  };
  return @{@"window" : dimsWindow, @"screen" : dimsScreen};
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  return [self getConstants];
}

- (NSDictionary<NSString *, id> *)getConstants
{
  __block NSDictionary<NSString *, id> *constants;
  RCTUnsafeExecuteOnMainQueueSync(^{
    constants = @{
#if !TARGET_OS_OSX // TODO(macOS GH#774)
      @"Dimensions" : RCTExportedDimensions(self->_bridge, self->_turboModuleRegistry),
#else // [TODO(macOS GH#774)
      @"Dimensions": RCTExportedDimensions(nil),
#endif // ]TODO(macOS GH#774)
      // Note:
      // This prop is deprecated and will be removed in a future release.
      // Please use this only for a quick and temporary solution.
      // Use <SafeAreaView> instead.
      @"isIPhoneX_deprecated" : @(RCTIsIPhoneX()),
    };
  });

  return constants;
}

- (void)didReceiveNewContentSizeMultiplier
{
  RCTBridge *bridge = _bridge;
  RCTExecuteOnMainQueue(^{
  // Report the event across the bridge.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [bridge.eventDispatcher sendDeviceEventWithName:@"didUpdateDimensions"
#if !TARGET_OS_OSX // TODO(macOS GH#774)
                                               body:RCTExportedDimensions(bridge, self->_turboModuleRegistry)];
#else // [TODO(macOS GH#774)
                                               body:RCTExportedDimensions(nil)];
#endif // ]TODO(macOS GH#774)
#pragma clang diagnostic pop
  });
}

#if !TARGET_OS_OSX // TODO(macOS GH#774)

- (void)interfaceOrientationDidChange
{
  __weak __typeof(self) weakSelf = self;
  RCTExecuteOnMainQueue(^{
    [weakSelf _interfaceOrientationDidChange];
  });
}

- (void)_interfaceOrientationDidChange
{
  UIInterfaceOrientation nextOrientation = [RCTSharedApplication() statusBarOrientation];

  // Update when we go from portrait to landscape, or landscape to portrait
  if ((UIInterfaceOrientationIsPortrait(_currentInterfaceOrientation) &&
       !UIInterfaceOrientationIsPortrait(nextOrientation)) ||
      (UIInterfaceOrientationIsLandscape(_currentInterfaceOrientation) &&
       !UIInterfaceOrientationIsLandscape(nextOrientation))) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_bridge.eventDispatcher sendDeviceEventWithName:@"didUpdateDimensions"
                                                body:RCTExportedDimensions(_bridge, _turboModuleRegistry)];
#pragma clang diagnostic pop
  }

  _currentInterfaceOrientation = nextOrientation;
}

- (void)interfaceFrameDidChange
{
  __weak __typeof(self) weakSelf = self;
  RCTExecuteOnMainQueue(^{
    [weakSelf _interfaceFrameDidChange];
  });
}

- (void)_interfaceFrameDidChange
{
  NSDictionary *nextInterfaceDimensions = RCTExportedDimensions(_bridge, _turboModuleRegistry);

  if (!([nextInterfaceDimensions isEqual:_currentInterfaceDimensions])) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_bridge.eventDispatcher sendDeviceEventWithName:@"didUpdateDimensions" body:nextInterfaceDimensions];
#pragma clang diagnostic pop
  }

  _currentInterfaceDimensions = nextInterfaceDimensions;
}
#endif // TODO(macOS GH#774)

- (std::shared_ptr<TurboModule>)getTurboModule:(const ObjCTurboModule::InitParams &)params
{
  return std::make_shared<NativeDeviceInfoSpecJSI>(params);
}

@end

Class RCTDeviceInfoCls(void)
{
  return RCTDeviceInfo.class;
}
