//
//  RZCollectionViewAnimationAssistant.h
//  Raizlabs
//
//  Created by Nick Donaldson on 1/9/14.
//  Copyright (c) 2014 Raizlabs. 
//

/**
 *  A helper class for creating item appearance/disappearance animations
 *  in a UICollectionViewLayout without reimplementing common logic in each subclass.
 */

#import <Foundation/Foundation.h>

@class RZCollectionViewCellAttributeUpdateOptions;

/**
 *  Mutate the attributes to define the animation.
 *  @param attributes   Copy of attributes to mutate. No need to copy again.
 *  @param options      Options object defining status of cell update (initial/final, individual/section, etc)
 */
typedef void (^RZCollectionViewCellAttributesBlock)(UICollectionViewLayoutAttributes *attributes, RZCollectionViewCellAttributeUpdateOptions *options);

@interface RZCollectionViewAnimationAssistant : NSObject

// ===============================================
//              Registering Animations
// ===============================================

/**
 *  Register a block-based attribute mutation for the attributes of an appearing or disappearing cell.
 */
- (void)setAttributesBlockForAnimatedCellUpdate:(RZCollectionViewCellAttributesBlock)block;

// TODO: Supplementary Views

// ===============================================
//                  Layout Hooks
// ===============================================

/**
 *  Call from the layout's prepareForCollectionViewUpdates: method.
 */
- (void)prepareForUpdates:(NSArray *)updateItems;

/**
 *  Call from the layout's finalizeCollectionViewUpdates method.
 */
- (void)finalizeUpdates;

/**
 *  Call from the layout's prepareForAnimatedBoundsChange: method.
 */
- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds;

/**
 *  Call from the layout's finalizeAnimatedBoundsChange method.
 */
- (void)finalizeAnimatedBoundsChange;

/**
 *  Use to get initial attributes for an appearing cell.
 */
- (UICollectionViewLayoutAttributes *)initialAttributesForCellWithAttributes:(UICollectionViewLayoutAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath;

/**
 *  Use to get final attributes for a disappearing cell.
 */
- (UICollectionViewLayoutAttributes *)finalAttributesForCellWithAttributes:(UICollectionViewLayoutAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath;

@end


// -------------------

@interface RZCollectionViewCellAttributeUpdateOptions : NSObject

@property (nonatomic, assign) BOOL isFinalAttributes;   // initial or final (NO = initial)
@property (nonatomic, assign) BOOL isSectionUpdate;     // individual cell or whole section update (NO = individual)
@property (nonatomic, assign) BOOL isBoundsUpdate;      // YES if result of animated bounds change
@property (nonatomic, assign) CGRect previousBounds;    // previous bounds, only valid if isBoundsUpdate == YES

@end
