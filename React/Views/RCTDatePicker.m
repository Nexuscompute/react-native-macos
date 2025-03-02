/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTDatePicker.h"

#import <Availability.h>
#import <AvailabilityInternal.h>

#import "RCTUtils.h"
#import "UIView+React.h"

#ifndef __IPHONE_14_0
#define __IPHONE_14_0 140000
#endif // __IPHONE_14_0

#ifndef RCT_IOS_14_0_SDK_OR_LATER
#define RCT_IOS_14_0_SDK_OR_LATER (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0)
#endif // RCT_IOS_14_0_SDK_OR_LATER

@interface RCTDatePicker ()

@property (nonatomic, copy) RCTBubblingEventBlock onChange;
@property (nonatomic, assign) NSInteger reactMinuteInterval;

@end

@implementation RCTDatePicker

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
#if !TARGET_OS_OSX // TODO(macOS GH#774)
    [self addTarget:self action:@selector(didChange) forControlEvents:UIControlEventValueChanged];
#else // [TODO(macOS GH#774)
    self.target = self;
    self.action = @selector(didChange);
#endif // ]TODO(macOS GH#774)
    _reactMinuteInterval = 1;

#if !TARGET_OS_OSX // TODO(macOS GH#774)
#if RCT_IOS_14_0_SDK_OR_LATER
    if (@available(iOS 14, *)) {
      self.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
#endif // RCT_IOS_14_0_SDK_OR_LATER
#endif // ]TODO(macOS GH#774)
  }
  return self;
}

RCT_NOT_IMPLEMENTED(-(instancetype)initWithCoder : (NSCoder *)aDecoder)

- (void)didChange
{
  if (_onChange) {
    _onChange(@{ @"timestamp":
#if !TARGET_OS_OSX // TODO(macOS GH#774)
                   @(self.date.timeIntervalSince1970 * 1000.0)
#else // [TODO(macOS GH#774)
                   @(self.dateValue.timeIntervalSince1970 * 1000.0)
#endif // ]TODO(macOS GH#774)
                 });
  }
}

#if !TARGET_OS_OSX // TODO(macOS GH#774)
- (void)setDatePickerMode:(UIDatePickerMode)datePickerMode
{
  [super setDatePickerMode:datePickerMode];
  // We need to set minuteInterval after setting datePickerMode, otherwise minuteInterval is invalid in time mode.
  self.minuteInterval = _reactMinuteInterval;
}
#endif // TODO(macOS GH#774)


#if !TARGET_OS_OSX // TODO(macOS GH#774)
- (void)setMinuteInterval:(NSInteger)minuteInterval
{
  [super setMinuteInterval:minuteInterval];
  _reactMinuteInterval = minuteInterval;
}
#endif // TODO(macOS GH#774)

@end
