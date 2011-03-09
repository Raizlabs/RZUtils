//
//  RZStyledTextContainer.m
//
//  Created by jkaufman on 3/9/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//

#import "RZStyledTextContainer.h"


@implementation RZStyledTextContainer

@synthesize string			= _string;
@synthesize location		= _location;
@synthesize insets			= _insets;
@synthesize displayRange	= _displayRange;
@synthesize displayFrame	= _displayFrame;

- (void)dealloc {
	[_string release];

    [super dealloc];
}

- (NSRange)displayRange {
	NSAssert(0, @"Subclasses of RZStyledTextContainer must override -displayRange.");
	return NSMakeRange(0, 0);
}

- (CGRect)displayFrame {
	return UIEdgeInsetsInsetRect(self.bounds, _insets);
}

@end
