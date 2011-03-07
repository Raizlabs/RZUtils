//
//  coreTextExViewController.h
//  coreTextEx
//
//  Created by Craig Spitzkoff on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FontViewController.h"

@class ColumnsView;
@class RZWrappingTextView;
@class RZStyledTextView;

@interface coreTextExViewController : UIViewController { //<FontViewControllerDelegate> {
	
	ColumnsView* _columnsView;
	
	UIScrollView* _scrollView;
	
	NSMutableArray* _pageViews;
	
	NSAttributedString* _text;
	
	NSInteger _selectedPointSizeAdjustment;
	
	UIPopoverController* popoverController;
	
	RZWrappingTextView *_textView;
	RZStyledTextView *_styledTextView;
}

@property (nonatomic, retain) IBOutlet ColumnsView* columnsView;
@property (nonatomic, retain) IBOutlet UIScrollView* scrollView;

@property (nonatomic, retain) NSAttributedString* text;
@property (nonatomic, retain) RZWrappingTextView* textView;
@property (nonatomic, retain) RZStyledTextView* styledTextView;
//@property (nonatomic, retain) UIPopoverController* popoverController;


-(IBAction) minusPressed:(id)sender;
-(IBAction) plusPressed:(id)sender;
-(IBAction) fontPressed:(id)sender;


@end

