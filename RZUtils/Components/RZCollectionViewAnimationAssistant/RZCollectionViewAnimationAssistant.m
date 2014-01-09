//
//  RZCollectionViewAnimationAssistant.m
//  Raizlabs
//
//  Created by Nick Donaldson on 1/9/14.
//  Copyright (c) 2014 Raizlabs. All rights reserved.
//

#import "RZCollectionViewAnimationAssistant.h"

@interface RZCollectionViewAnimationAssistant ()

// Containers for keeping track of changing items
@property (nonatomic, strong) NSMutableArray *insertedIndexPaths;
@property (nonatomic, strong) NSMutableArray *removedIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertedSectionIndices;
@property (nonatomic, strong) NSMutableArray *removedSectionIndices;

@property (nonatomic, assign) BOOL boundsChanging;
@property (nonatomic, assign) CGRect previousBounds;

@property (nonatomic, copy) RZCollectionViewCellAttributesBlock cellAttributesBlock;

- (NSIndexPath*)previousIndexPathForIndexPath:(NSIndexPath *)indexPath accountForItems:(BOOL)checkItems;

@end

@implementation RZCollectionViewAnimationAssistant

#pragma mark - Set update blocks

- (void)setAttributesBlockForAnimatedCellUpdate:(RZCollectionViewCellAttributesBlock)block
{
    self.cellAttributesBlock = block;
}

#pragma mark - Update methods

- (void)prepareForUpdates:(NSArray *)updateItems
{
    // Keep track of updates to items and sections so we can use this information to create nifty animations
    self.insertedIndexPaths     = [NSMutableArray array];
    self.removedIndexPaths      = [NSMutableArray array];
    self.insertedSectionIndices = [NSMutableArray array];
    self.removedSectionIndices  = [NSMutableArray array];
    
    [updateItems enumerateObjectsUsingBlock:^(UICollectionViewUpdateItem *updateItem, NSUInteger idx, BOOL *stop) {
        if (updateItem.updateAction == UICollectionUpdateActionInsert)
        {
            // If the update item's index path has an "item" value of NSNotFound, it means it was a section update, not an individual item.
            // This is 100% undocumented but 100% reproducible.
            
            if (updateItem.indexPathAfterUpdate.item == NSNotFound)
            {
                [self.insertedSectionIndices addObject:@(updateItem.indexPathAfterUpdate.section)];
            }
            else
            {
                [self.insertedIndexPaths addObject:updateItem.indexPathAfterUpdate];
            }
        }
        else if (updateItem.updateAction == UICollectionUpdateActionDelete)
        {
            if (updateItem.indexPathBeforeUpdate.item == NSNotFound)
            {
                [self.removedSectionIndices addObject:@(updateItem.indexPathBeforeUpdate.section)];
                
            }
            else
            {
                [self.removedIndexPaths addObject:updateItem.indexPathBeforeUpdate];
            }
        }
    }];
}

- (void)finalizeUpdates
{    
    self.insertedIndexPaths     = nil;
    self.removedIndexPaths      = nil;
    self.insertedSectionIndices = nil;
    self.removedSectionIndices  = nil;
}

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
    self.boundsChanging = YES;
    self.previousBounds = oldBounds;
}

- (void)finalizeAnimatedBoundsChange
{
    self.boundsChanging = NO;
    self.previousBounds = CGRectZero;
}

- (UICollectionViewLayoutAttributes *)initialAttributesForCellWithAttributes:(UICollectionViewLayoutAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *initialAttributes = [attributes copy];
    if (initialAttributes && self.cellAttributesBlock)
    {
        BOOL shouldMutate = NO;
        BOOL isSectionUpdate = NO;
        
        if ([self.insertedIndexPaths containsObject:indexPath])
        {
            shouldMutate = YES;
        }
        else if ([self.insertedSectionIndices containsObject:@(indexPath.section)])
        {
            shouldMutate = YES;
            isSectionUpdate = YES;
        }
        
        if (shouldMutate)
        {
            
            RZCollectionViewCellAttributeUpdateOptions *opts = [RZCollectionViewCellAttributeUpdateOptions new];
            opts.isFinalAttributes = NO;
            opts.isBoundsUpdate = self.boundsChanging;
            opts.previousBounds = self.previousBounds;
            opts.isSectionUpdate = isSectionUpdate;
            self.cellAttributesBlock(initialAttributes, opts);
        }
    }
    return initialAttributes;
}

- (UICollectionViewLayoutAttributes *)finalAttributesForCellWithAttributes:(UICollectionViewLayoutAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *finalAttributes = [attributes copy];
    if (finalAttributes && self.cellAttributesBlock)
    {
        BOOL shouldMutate = NO;
        BOOL isSectionUpdate = NO;
        
        if ([self.removedIndexPaths containsObject:indexPath])
        {
            shouldMutate = YES;
        }
        else if ([self.removedSectionIndices containsObject:@(indexPath.section)])
        {
            shouldMutate = YES;
            isSectionUpdate = YES;
        }
        
        if (shouldMutate)
        {
            
            RZCollectionViewCellAttributeUpdateOptions *opts = [RZCollectionViewCellAttributeUpdateOptions new];
            opts.isFinalAttributes = YES;
            opts.isBoundsUpdate = self.boundsChanging;
            opts.previousBounds = self.previousBounds;
            opts.isSectionUpdate = isSectionUpdate;
            self.cellAttributesBlock(finalAttributes, opts);
        }
    }
    return finalAttributes;
}

#pragma mark - Private

- (NSIndexPath*)previousIndexPathForIndexPath:(NSIndexPath *)indexPath accountForItems:(BOOL)checkItems
{
    __block NSInteger section = indexPath.section;
    __block NSInteger item = indexPath.item;
    
    [self.removedSectionIndices enumerateObjectsUsingBlock:^(NSNumber *rmSectionIdx, NSUInteger idx, BOOL *stop) {
        if ([rmSectionIdx integerValue] <= section)
        {
            section++;
        }
    }];
    
    if (checkItems)
    {
        [self.removedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *rmIndexPath, NSUInteger idx, BOOL *stop) {
            if ([rmIndexPath section] == section && [rmIndexPath item] <= item)
            {
                item++;
            }
        }];
    }
    
    [self.insertedSectionIndices enumerateObjectsUsingBlock:^(NSNumber *insSectionIdx, NSUInteger idx, BOOL *stop) {
        if ([insSectionIdx integerValue] < [indexPath section])
        {
            section--;
        }
    }];
    
    if (checkItems)
    {
        [self.insertedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *insIndexPath, NSUInteger idx, BOOL *stop) {
            if ([insIndexPath section] == [indexPath section] && [insIndexPath item] < [indexPath item])
            {
                item--;
            }
        }];
    }
    
    return [NSIndexPath indexPathForItem:item inSection:section];
}

@end

@implementation RZCollectionViewCellAttributeUpdateOptions @end
