//
//  RZTween.m
//  Raizlabs
//
//  Created by Nick D on 1/3/14.

// Copyright 2014 Raizlabs and other contributors
// http://raizlabs.com/
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "RZTween.h"

static float RZTweenClampFloat(float value, float min, float max)
{
    return MIN(max, MAX(value, min));
}

static float RZTweenMapFloat(float value, float inMin, float inMax, float outMin, float outMax, BOOL clamp)
{
    float result = ((value - inMin)/(inMax - inMin)) * (outMax - outMin) + outMin;
    if (clamp)
    {
        result = RZTweenClampFloat(result, MIN(outMin,outMax), MAX(outMin,outMax));
    }
    return result;
}

// -----------------------------

@interface RZTweenKeyFrame : NSObject

+ (instancetype)keyFrameWithTime:(NSTimeInterval)time value:(NSValue *)value;

@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, strong) NSValue *value;

@end

@implementation RZTweenKeyFrame

+ (instancetype)keyFrameWithTime:(NSTimeInterval)time value:(NSValue *)value
{
    RZTweenKeyFrame *kf = [RZTweenKeyFrame new];
    kf.time = time;
    kf.value = value;
    return kf;
}

@end

// -----------------------------


@interface RZTween ()

@property (nonatomic, strong) NSMutableArray *sortedKeyFrames;
- (void)addKeyFrame:(RZTweenKeyFrame *)keyFrame;

- (NSArray *)nearestKeyFramesForTime:(NSTimeInterval)time;

@end

@implementation RZTween

- (id)init
{
    self = [super init];
    if (self)
    {
        self.sortedKeyFrames = [NSMutableArray array];
    }
    return self;
}

- (NSValue *)valueAtTime:(NSTimeInterval)time
{
    return @0;
}

- (void)addKeyFrame:(RZTweenKeyFrame *)keyFrame
{
    if (self.sortedKeyFrames.count == 0)
    {
        [self.sortedKeyFrames addObject:keyFrame];
    }
    else
    {
        NSUInteger newIndex = [self.sortedKeyFrames indexOfObject:keyFrame
                                                    inSortedRange:NSMakeRange(0, self.sortedKeyFrames.count)
                                                          options:NSBinarySearchingInsertionIndex
                                                  usingComparator:^NSComparisonResult(RZTweenKeyFrame *kf1, RZTweenKeyFrame *kf2) {
                                                      return [@(kf1.time) compare:@(kf2.time)];
                                                  }];
        [self.sortedKeyFrames insertObject:keyFrame atIndex:newIndex];
    }
}

- (NSArray *)nearestKeyFramesForTime:(NSTimeInterval)time
{
    NSArray *kframes = nil;
    if (self.sortedKeyFrames.count > 0)
    {
        RZTweenKeyFrame *searchFrame = [RZTweenKeyFrame keyFrameWithTime:time value:nil];
        NSUInteger insertIndex = [self.sortedKeyFrames indexOfObject:searchFrame
                                                       inSortedRange:NSMakeRange(0, self.sortedKeyFrames.count)
                                                             options:NSBinarySearchingInsertionIndex
                                                     usingComparator:^NSComparisonResult(RZTweenKeyFrame *kf1, RZTweenKeyFrame *kf2) {
                                                         return [@(kf1.time) compare:@(kf2.time)];
                                                     }];
        
        if (insertIndex == 0)
        {
            kframes = @[[self.sortedKeyFrames firstObject]];
        }
        else if (insertIndex == self.sortedKeyFrames.count)
        {
            kframes = @[[self.sortedKeyFrames lastObject]];
        }
        else
        {
            kframes = @[[self.sortedKeyFrames objectAtIndex:insertIndex-1],
                        [self.sortedKeyFrames objectAtIndex:insertIndex]];
        }
    }
    return kframes;
}

- (id)copyWithZone:(NSZone *)zone {
  RZTween *copy = [[[self class] allocWithZone:zone] init];

  if (copy != nil) {
    copy.sortedKeyFrames = [self.sortedKeyFrames copy];
  }

  return copy;
}

- (BOOL)isEqual:(id)other {
  if (other == self)
    return YES;
  if (!other || ![[other class] isEqual:[self class]])
    return NO;

  return [self isEqualToTween:other];
}

- (BOOL)isEqualToTween:(RZTween *)tween {
  if (self == tween)
    return YES;
  if (tween == nil)
    return NO;
  if (self.sortedKeyFrames != tween.sortedKeyFrames && ![self.sortedKeyFrames isEqualToArray:tween.sortedKeyFrames])
    return NO;
  return YES;
}

- (NSUInteger)hash {
  return [self.sortedKeyFrames hash];
}

@end

// -----------------------------

@implementation RZFloatTween

- (void)addKeyFloat:(CGFloat)keyFloat atTime:(NSTimeInterval)time
{
    [self addKeyFrame:[RZTweenKeyFrame keyFrameWithTime:time value:@(keyFloat)]];
}


- (NSValue*)valueAtTime:(NSTimeInterval)time
{
    NSNumber *value = @0;
    NSArray *nearestKeyFrames = [self nearestKeyFramesForTime:time];
    if (nearestKeyFrames.count > 0)
    {
        if (nearestKeyFrames.count == 1)
        {
            RZTweenKeyFrame *kf = [nearestKeyFrames firstObject];
            value = (NSNumber*)kf.value;
        }
        else
        {
            RZTweenKeyFrame *kf1 = [nearestKeyFrames firstObject];
            RZTweenKeyFrame *kf2 = [nearestKeyFrames lastObject];
            value = @(RZTweenMapFloat(time, kf1.time, kf2.time, [(NSNumber*)kf1.value floatValue], [(NSNumber*)kf2.value floatValue], YES));
        }
    }
    return value;
}

@end

// -----------------------------

@implementation RZBooleanTween

- (void)addKeyBool:(BOOL)keyBool atTime:(NSTimeInterval)time
{
    [self addKeyFrame:[RZTweenKeyFrame keyFrameWithTime:time value:@(keyBool)]];
}


- (NSValue*)valueAtTime:(NSTimeInterval)time
{
    NSNumber *value = @0;
    NSArray *nearestKeyFrames = [self nearestKeyFramesForTime:time];
    if (nearestKeyFrames.count > 0)
    {
        RZTweenKeyFrame *kf = [nearestKeyFrames firstObject];
        value = (NSNumber*)kf.value;
    }
    return value;
}

@end

// -----------------------------

@implementation RZTransformTween

- (void)addKeyTransform:(CGAffineTransform)transform atTime:(NSTimeInterval)time
{
    [self addKeyFrame:[RZTweenKeyFrame keyFrameWithTime:time value:[NSValue valueWithCGAffineTransform:transform]]];
}


- (NSValue*)valueAtTime:(NSTimeInterval)time
{
    NSValue *transformValue = [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
    NSArray *nearestKeyFrames = [self nearestKeyFramesForTime:time];
    if (nearestKeyFrames.count > 0)
    {
        if (nearestKeyFrames.count == 1)
        {
            RZTweenKeyFrame *kf = [nearestKeyFrames firstObject];
            transformValue = kf.value;
        }
        else
        {
            RZTweenKeyFrame *kf1 = [nearestKeyFrames firstObject];
            RZTweenKeyFrame *kf2 = [nearestKeyFrames lastObject];
            
            CGAffineTransform tf1 = [kf1.value CGAffineTransformValue];
            CGAffineTransform tf2 = [kf2.value CGAffineTransformValue];
            
            CGAffineTransform finalTf;
            finalTf.a = RZTweenMapFloat(time, kf1.time, kf2.time, tf1.a, tf2.a, YES);
            finalTf.b = RZTweenMapFloat(time, kf1.time, kf2.time, tf1.b, tf2.b, YES);
            finalTf.c = RZTweenMapFloat(time, kf1.time, kf2.time, tf1.c, tf2.c, YES);
            finalTf.d = RZTweenMapFloat(time, kf1.time, kf2.time, tf1.d, tf2.d, YES);
            finalTf.tx = RZTweenMapFloat(time, kf1.time, kf2.time, tf1.tx, tf2.tx, YES);
            finalTf.ty = RZTweenMapFloat(time, kf1.time, kf2.time, tf1.ty, tf2.ty, YES);
            
            transformValue = [NSValue valueWithCGAffineTransform:finalTf];
        }
    }
    return transformValue;
}

@end


