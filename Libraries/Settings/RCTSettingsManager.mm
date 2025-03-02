/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTSettingsManager.h>

#import <FBReactNativeSpec/FBReactNativeSpec.h>
#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcherProtocol.h>
#import <React/RCTUtils.h>

#import "RCTSettingsPlugins.h"

@interface RCTSettingsManager() <NativeSettingsManagerSpec>
@end

@implementation RCTSettingsManager
{
  BOOL _ignoringUpdates;
  NSUserDefaults *_defaults;
  
#if TARGET_OS_OSX // [TODO(macOS GH#774)
  BOOL _isListeningForUpdates;
#endif // ]TODO(macOS GH#774)
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (instancetype)init
{
  return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults
{
  if ((self = [super init])) {
    _defaults = defaults;

#if !TARGET_OS_OSX // TODO(macOS GH#774)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:_defaults];
#endif // TODO(macOS GH#774)
  }
  return self;
}

- (facebook::react::ModuleConstants<JS::NativeSettingsManager::Constants>)constantsToExport
{
  return (facebook::react::ModuleConstants<JS::NativeSettingsManager::Constants>)[self getConstants];
}

- (facebook::react::ModuleConstants<JS::NativeSettingsManager::Constants>)getConstants
{
  return facebook::react::typedConstants<JS::NativeSettingsManager::Constants>({
    .settings = RCTJSONClean([_defaults dictionaryRepresentation])
  });
}

- (void)userDefaultsDidChange:(NSNotification *)note
{
  if (_ignoringUpdates) {
    return;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [_bridge.eventDispatcher
   sendDeviceEventWithName:@"settingsUpdated"
   body:RCTJSONClean([_defaults dictionaryRepresentation])];
#pragma clang diagnostic pop
}

/**
 * Set one or more values in the settings.
 * TODO: would it be useful to have a callback for when this has completed?
 */
RCT_EXPORT_METHOD(setValues:(NSDictionary *)values)
{
  _ignoringUpdates = YES;
  [values enumerateKeysAndObjectsUsingBlock:^(NSString *key, id json, BOOL *stop) {
    id plist = [RCTConvert NSPropertyList:json];
    if (plist) {
      [self->_defaults setObject:plist forKey:key];
    } else {
      [self->_defaults removeObjectForKey:key];
    }
  }];

  [_defaults synchronize];
  _ignoringUpdates = NO;
}

/**
 * Remove some values from the settings.
 */
RCT_EXPORT_METHOD(deleteValues:(NSArray<NSString *> *)keys)
{
  _ignoringUpdates = YES;
  for (NSString *key in keys) {
    [_defaults removeObjectForKey:key];
  }

  [_defaults synchronize];
  _ignoringUpdates = NO;
}

#if TARGET_OS_OSX // [TODO(macOS GH#774)
/**
 * Enable or disable monitoring of changes to NSUserDefaults
 */
RCT_EXPORT_METHOD(setIsMonitoringEnabled:(BOOL)isEnabled)
{
  if (isEnabled) {
    if (!_isListeningForUpdates) {
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(userDefaultsDidChange:)
                                                   name:NSUserDefaultsDidChangeNotification
                                                 object:_defaults];
      _isListeningForUpdates = YES;
    }
  }
  else
  {
    if (_isListeningForUpdates) {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      _isListeningForUpdates = NO;
    }
  }
}
#endif // ]TODO(macOS GH#774)

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeSettingsManagerSpecJSI>(params);
}

@end

Class RCTSettingsManagerCls(void)
{
  return RCTSettingsManager.class;
}
