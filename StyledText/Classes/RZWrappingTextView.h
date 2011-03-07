//
//  RZTextLayout.h
//
//  Created by jkaufman on 2/28/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class RZWrappingTextView
 @abstract An RZWrappingTextView object displays a range of an NSAttributedString within an irregular shape,
 breaking and wrapping text to fit the geometry.
 @discussion An RZStyledTextView object displays a range of an NSAttributedString, with support for layout settings
 and runtime soft-hyphenation.
 */
@interface RZWrappingTextView : UIView {
	/**
	 The attributed string to be displayed.
	 */
	NSAttributedString *_string;

	/**
	The insets within which the the attributed string is rendered.
	*/
	UIEdgeInsets _insets;
	
	/**
	 The starting index of the substring to be displayed.
	 */
	NSInteger _location;
	
	/**
	  A collection of rectangles in which no text should be drawn.
	 */
	NSSet *_exclusionFrames;
	
	/**
	  The range of the substring that fits within the shape defined by the exclusion frames and view frame.
	 */
	NSRange _displayRange;
	
	/**
	  The minimum bounding box that completely contains the rendered text.
	 */
	CGRect _displayRect;
}

// Settable properties
@property (nonatomic, retain) NSAttributedString *string;
@property (nonatomic, retain) NSSet *exclusionFrames;

// Derived properties
@property (readonly) NSRange displayRange;
@property (readonly) CGRect displayRect;

/**
 Initialize a new RZWrappingTextView object
 @param aFrame The view frame.
 @param aString The attributed string to be displayed.
 @param aLocation The starting index of the substring to be displayed.
 @param someInsets The insets within which the attributed string is rendered.
 @param someExclusionFrames A collection of rectangles in which no text should be drawn.  Expects CGRect objects using
 CGRectCreateDictionaryRepresentation
 @returns A newly initialized object.
 */
- (id)initWithFrame:(CGRect)aFrame
			 string:(NSAttributedString *)aString
		   location:(NSInteger)aLocation 
		 edgeInsets:(UIEdgeInsets)someInsets
	exclusionFrames:(NSSet *)someExclusionFrames;

@end