//
//  UIView+RZAutoLayoutHelpers.m
//
//  Created by Nick Donaldson on 10/22/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "UIView+RZAutoLayoutHelpers.h"

@implementation UIView (RZAutoLayoutHelpers)

- (void)rz_pinWidthTo:(CGFloat)width
{
    NSLayoutConstraint *w = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.f
                                                          constant:width];
    [self addConstraint:w];
}

- (void)rz_pinHeightTo:(CGFloat)height
{
    NSLayoutConstraint *h = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.f
                                                          constant:height];
    [self addConstraint:h];
}

- (void)rz_pinSizeTo:(CGSize)size
{
    [self rz_pinWidthTo:size.width];
    [self rz_pinHeightTo:size.height];
}


- (void)rz_centerHorizontallyInContainer
{
    [self rz_centerHorizontallyInContainerWithOffset:0];
}

- (void)rz_centerHorizontallyInContainerWithOffset:(CGFloat)offset
{
    NSAssert(self.superview != nil, @"Must have superview");
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.f
                                                          constant:offset];
    [self.superview addConstraint:c];
}

- (void)rz_centerVerticallyInContainer
{
    [self rz_centerVerticallyInContainerWithOffset:0];
}

- (void)rz_centerVerticallyInContainerWithOffset:(CGFloat)offset
{
    NSAssert(self.superview != nil, @"Must have superview");
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.f
                                                          constant:offset];
    [self.superview addConstraint:c];
}

- (void)rz_fillContainerWithInsets:(UIEdgeInsets)insets
{
    NSAssert(self.superview != nil, @"Must have superview");

    NSArray *h = [NSLayoutConstraint constraintsWithVisualFormat:@"|-left-[self]-right-|"
                                                         options:0
                                                         metrics:@{@"left" : @(insets.left), @"right" : @(insets.right)}
                                                           views:@{@"self" : self}];
    
    NSArray *v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[self]-bottom-|"
                                                         options:0
                                                         metrics:@{@"top" : @(insets.top), @"bottom" : @(insets.bottom)}
                                                           views:@{@"self" : self}];
    
    [self.superview addConstraints:[h arrayByAddingObjectsFromArray:v]];
}

- (void)rz_fillContainerHorizontallyWithMinPadding:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");
    
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeLeft
                                                               relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeLeft
                                                              multiplier:1.0
                                                                constant:padding]];
    
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeRight
                                                               relatedBy:NSLayoutRelationLessThanOrEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeRight
                                                              multiplier:1.0
                                                                constant:padding]];
}

- (void)rz_fillContainerVerticallyWithMinPadding:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");

    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:padding]];
    
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationLessThanOrEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0
                                                                constant:padding]];
}

- (void)rz_insetFromContainerTopBy:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.f
                                                          constant:padding];
    [self.superview addConstraint:c];
}


- (void)rz_insetFromContainerLeftBy:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.f
                                                          constant:padding];
    [self.superview addConstraint:c];
}

- (void)rz_insetFromContainerBottomBy:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.f
                                                          constant:-padding];
    [self.superview addConstraint:c];
}

- (void)rz_insetFromContainerRightBy:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.f
                                                          constant:-padding];
    [self.superview addConstraint:c];
}

- (void)rz_spaceSubviews:(NSArray *)subviews vertically:(BOOL)vertically minimumItemSpacing:(CGFloat)itemSpacing
{
    NSAssert(subviews.count > 1, @"Must provide at least two items");
    
    NSMutableArray *constraints = [NSMutableArray array];

    NSLayoutAttribute a1 = vertically ? NSLayoutAttributeTop : NSLayoutAttributeLeft;
    NSLayoutAttribute a2 = vertically ? NSLayoutAttributeBottom : NSLayoutAttributeRight;
    
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop)
    {

        UIView *nextView = (idx == subviews.count - 1) ? nil : subviews[idx + 1];

        if (nextView)
        {
            NSLayoutConstraint *s = [NSLayoutConstraint constraintWithItem:nextView
                                                                 attribute:a1
                                                                 relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                    toItem:view
                                                                 attribute:a2
                                                                multiplier:1.f
                                                                  constant:itemSpacing];

            [constraints addObject:s];
        }

    }];
    
    [self addConstraints:constraints];
}

- (void)rz_alignSubviews:(NSArray *)subviews byAttribute:(NSLayoutAttribute)attribute
{
    NSAssert(subviews.count > 1, @"Must provide at least two items");

    NSMutableArray *constraints = [NSMutableArray array];
    
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop)
    {

        UIView *nextView = (idx == subviews.count - 1) ? nil : subviews[idx + 1];
        if (nextView)
        {
            NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:nextView
                                                                 attribute:attribute
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view
                                                                 attribute:attribute
                                                                multiplier:1.f
                                                                  constant:0.f];
            [constraints addObject:c];
        }

    }];
    
    [self addConstraints:constraints];
}

@end