/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <ImageIO/ImageIO.h>
#import <React/RCTAnimatedImage.h>

@interface RCTGIFCoderFrame : NSObject

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSTimeInterval duration;

@end

@implementation RCTGIFCoderFrame
@end

@implementation RCTAnimatedImage {
  CGImageSourceRef _imageSource;
  CGFloat _scale;
  NSUInteger _loopCount;
  NSUInteger _frameCount;
  NSArray<RCTGIFCoderFrame *> *_frames;
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale
{
  if (self = [super init]) {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!imageSource) {
      return nil;
    }

    BOOL framesValid = [self scanAndCheckFramesValidWithSource:imageSource];
    if (!framesValid) {
      CFRelease(imageSource);
      return nil;
    }

    _imageSource = imageSource;

#if TARGET_OS_OSX // [TODO(macOS GH#774)
    self = [super initWithData:data];
#else // ]TODO(macOS GH#774)
    // grab image at the first index
    UIImage *image = [self animatedImageFrameAtIndex:0];
    if (!image) {
      return nil;
    }
    self = [super initWithCGImage:image.CGImage scale:MAX(scale, 1) orientation:image.imageOrientation];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif // TODO(macOS GH#774)
  }

  return self;
}

- (BOOL)scanAndCheckFramesValidWithSource:(CGImageSourceRef)imageSource
{
  if (!imageSource) {
    return NO;
  }
  NSUInteger frameCount = CGImageSourceGetCount(imageSource);
  NSUInteger loopCount = [self imageLoopCountWithSource:imageSource];
  NSMutableArray<RCTGIFCoderFrame *> *frames = [NSMutableArray array];

  for (size_t i = 0; i < frameCount; i++) {
    RCTGIFCoderFrame *frame = [[RCTGIFCoderFrame alloc] init];
    frame.index = i;
    frame.duration = [self frameDurationAtIndex:i source:imageSource];
    [frames addObject:frame];
  }

  _frameCount = frameCount;
  _loopCount = loopCount;
  _frames = [frames copy];

  return YES;
}

- (NSUInteger)imageLoopCountWithSource:(CGImageSourceRef)source
{
  NSUInteger loopCount = 1;
  NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
  NSDictionary *gifProperties = imageProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary];
  if (gifProperties) {
    NSNumber *gifLoopCount = gifProperties[(__bridge NSString *)kCGImagePropertyGIFLoopCount];
    if (gifLoopCount != nil) {
      loopCount = gifLoopCount.unsignedIntegerValue;
      // A loop count of 1 means it should repeat twice, 2 means, thrice, etc.
      if (loopCount != 0) {
        loopCount++;
      }
    }
  }
  return loopCount;
}

- (float)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
  float frameDuration = 0.1f;
  CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
  if (!cfFrameProperties) {
    return frameDuration;
  }
  NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
  NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];

  NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
  if (delayTimeUnclampedProp != nil && [delayTimeUnclampedProp floatValue] != 0.0f) {
    frameDuration = [delayTimeUnclampedProp floatValue];
  } else {
    NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
    if (delayTimeProp != nil) {
      frameDuration = [delayTimeProp floatValue];
    }
  }

  CFRelease(cfFrameProperties);
  return frameDuration;
}

- (NSUInteger)animatedImageLoopCount
{
  return _loopCount;
}

- (NSUInteger)animatedImageFrameCount
{
  return _frameCount;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index
{
  if (index >= _frameCount) {
    return 0;
  }
  return _frames[index].duration;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index
{
  CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, index, NULL);
  if (!imageRef) {
    return nil;
  }
#if TARGET_OS_OSX // [TODO(macOS GH#774)
  UIImage *image = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef))];
#else // ]TODO(macOS GH#774)
  UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:UIImageOrientationUp];
#endif // TODO(macOS GH#774)
  CGImageRelease(imageRef);
  return image;
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
  if (_imageSource) {
    for (size_t i = 0; i < _frameCount; i++) {
      CGImageSourceRemoveCacheAtIndex(_imageSource, i);
    }
  }
}

- (void)dealloc
{
  if (_imageSource) {
    CFRelease(_imageSource);
    _imageSource = NULL;
  }
#if !TARGET_OS_OSX // TODO(macOS GH#774)
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif // TODO(macOS GH#774)
}

@end
