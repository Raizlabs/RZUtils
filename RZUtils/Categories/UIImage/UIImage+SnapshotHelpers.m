//
//  UIImage+SnapshotHelpers.m
//
//  Created by Stephen Barnes on 4/30/14.

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

#import "UIImage+SnapshotHelpers.h"

@implementation UIImage (SnapshotHelpers)

+ (UIImage *)imageByCapturingView:(UIView *)view afterScreenUpdate:(BOOL)waitForUpdate
{
    UIImage *outputImage = nil;
    CGRect imageRect = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0.0);
    
    // If afterScreenUpdates is set to YES, there is a super weird bug sometimes where all tap gestures (app-wide) will be delayed.
    // This definitely needs to be filed in a radar at some point.
    BOOL success = [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:waitForUpdate];
    if ( success ) {
        outputImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end
