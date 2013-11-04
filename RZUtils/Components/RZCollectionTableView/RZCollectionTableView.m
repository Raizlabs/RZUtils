//
//  RZCollectionTableView.m
//
//  Created by Nick Donaldson on 9/13/13.
//  Copyright (c) 2013 RaizLabs. All rights reserved.
//

#import "RZCollectionTableView.h"
#import "RZCollectionTableView_Private.h"

#define RZCVTL_HEADER_ITEM 0
#define RZCVTL_FOOTER_ITEM 1

@interface RZCollectionTableView ()
{
    BOOL _inEditingConfirmationState;
}

- (void)commonInit;

- (void)enterConfirmationStateForCell:(RZCollectionTableViewCell*)cell;
- (void)endConfirmationState;

@end

@implementation RZCollectionTableView

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    
}

- (BOOL)_rz_inEditingConfirmationState
{
    return _inEditingConfirmationState;
}

#pragma mark - Editing State Management

- (void)_rz_editingStateChangedForCell:(RZCollectionTableViewCell *)cell
{
    // TODO: may want to show "edit circles" in the future, which is a different state from "confirmation"
    if (cell != nil && [self.visibleCells containsObject:cell])
    {
        if (cell.rzEditing)
        {
            switch (cell.rzEditingStyle)
            {
                case RZCollectionTableViewCellEditingStyleDelete:
                    [self enterConfirmationStateForCell:cell];
                    break;
                    
                case RZCollectionTableViewCellEditingStyleNone:
                default:
                    break;
            }
        }
    }
    
}

- (void)_rz_editingCommittedForCell:(RZCollectionTableViewCell *)cell
{
    if (cell != nil && [self.visibleCells containsObject:cell])
    {
        [self endConfirmationState];
        
        if ([self.collectionViewLayout isKindOfClass:[RZCollectionTableViewLayout class]])
        {
            [(RZCollectionTableViewLayout*)self.collectionViewLayout _rz_commitEditingStyle:cell.rzEditingStyle
                                                                          forRowAtIndexPath:[self indexPathForCell:cell]];
        }
    }
}

#pragma mark - Private

- (void)enterConfirmationStateForCell:(RZCollectionTableViewCell *)cell
{
    // Stop other cells from showing delete
    [self.visibleCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[RZCollectionTableViewCell class]] && obj != cell)
        {
            [(RZCollectionTableViewCell *)obj setRzEditing:NO animated:YES];
        }
        
    }];
    
    _inEditingConfirmationState = YES;
}

- (void)endConfirmationState
{
    [self.visibleCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[RZCollectionTableViewCell class]])
        {
            [(RZCollectionTableViewCell *)obj setRzEditing:NO animated:YES];
        }
        
    }];
    
    _inEditingConfirmationState = NO;
}

#pragma mark - Touch swallowing

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_inEditingConfirmationState)
    {
        // Any touch immediately kills the editing state
        // Designed to work just like a UITableView
        [self endConfirmationState];
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
    }
}

@end

// -----------------


NSString * const RZCollectionTableViewLayoutHeaderView = @"RZCollectionTableViewLayoutHeaderView";
NSString * const RZCollectionTableViewLayoutFooterView = @"RZCollectionTableViewLayoutHeaderView";


@interface RZCollectionTableViewLayout ()

// ===== Caches =====

// Computed value caches
@property (nonatomic, assign) CGSize cachedContentSize;
@property (nonatomic, assign) CGRect lastRequestedRect;
@property (nonatomic, strong) NSMutableDictionary *rowHeightCache;
@property (nonatomic, strong) NSMutableDictionary *sectionHeightCache;
@property (nonatomic, strong) NSMutableDictionary *headerHeightCache;
@property (nonatomic, strong) NSMutableDictionary *footerHeightCache;

// Attribute caches
@property (nonatomic, strong) NSArray * lastAttributesForRect;
@property (nonatomic, strong) NSMutableDictionary * itemAttributesCache;
@property (nonatomic, strong) NSMutableDictionary * supplementaryAttributesCache; // key: type value: dictionary by index path


// ===== Helpers ======

@property (nonatomic, readonly) NSInteger totalRows;
@property (nonatomic, readonly) id<RZCollectionTableViewLayoutDelegate> layoutDelegate;

- (BOOL)sectionHasHeader:(NSInteger)section;
- (BOOL)sectionHasFooter:(NSInteger)section;

// These account for the delegate's response - use these internally
- (UIEdgeInsets)insetsForSection:(NSInteger)section;
- (CGFloat)rowSpacingForSection:(NSInteger)section;
- (CGFloat)headerHeightForSection:(NSInteger)section;
- (CGFloat)footerHeightForSection:(NSInteger)section;

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (CGFloat)heightForSection:(NSInteger)section;

- (NSIndexPath *)indexPathForRawRowIndex:(NSInteger)rowIndex; // converts expanded index to sectioned index path
- (NSIndexPath *)indexPathOfFirstRowInRect:(CGRect)rect;

@end

@implementation RZCollectionTableViewLayout

+ (Class)layoutAttributesClass
{
    return [RZCollectionTableViewCellAttributes class];
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self)
    {
        _sectionInsets = UIEdgeInsetsZero;
        _rowSpacing = 0.f;
        _rowHeight = 44.f;
    }
    return self;
}

#pragma mark - Invalidation and Updates

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size);
}

- (void)invalidateLayout
{
    [super invalidateLayout];
    self.rowHeightCache               = [NSMutableDictionary dictionary];
    self.sectionHeightCache           = [NSMutableDictionary dictionary];
    self.headerHeightCache            = [NSMutableDictionary dictionary];
    self.footerHeightCache            = [NSMutableDictionary dictionary];
    self.itemAttributesCache          = [NSMutableDictionary dictionary];
    self.supplementaryAttributesCache = [NSMutableDictionary dictionary];
    self.cachedContentSize            = CGSizeZero;
    self.lastRequestedRect            = CGRectZero;
}

- (void)prepareLayout
{
    [super prepareLayout];
    
    // Anything to do here? maybe not...
}

#pragma mark - Size and Attributes

- (CGSize)collectionViewContentSize
{
    if (CGSizeEqualToSize(self.cachedContentSize, CGSizeZero))
    {
        CGSize contentSize = CGSizeMake(self.collectionView.bounds.size.width, 0);
        
        for (NSInteger s = 0; s < [self.collectionView numberOfSections]; s++)
        {
            contentSize.height += [self heightForSection:s];
        }
        
        contentSize.height = MAX(contentSize.height, self.collectionView.frame.size.height);
        
        self.cachedContentSize = contentSize;
    }
    
    return self.cachedContentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray * attributes = nil;
    if (!CGRectEqualToRect(rect, self.lastRequestedRect))
    {
        self.lastRequestedRect = rect;
        
        BOOL outOfBounds = NO;
        NSMutableArray *newAttributes = [NSMutableArray  array];
        NSIndexPath * firstRowIndexPath = [self indexPathOfFirstRowInRect:rect];
        if (firstRowIndexPath != nil)
        {
            NSInteger startRowIndex = firstRowIndexPath.item;
            for (NSInteger s = firstRowIndexPath.section; s < [self.collectionView numberOfSections] && !outOfBounds; s++)
            {
                for (NSInteger i = startRowIndex; i < [self.collectionView numberOfItemsInSection:s] && !outOfBounds; i++)
                {
                    RZCollectionTableViewCellAttributes * rowAttributes = (RZCollectionTableViewCellAttributes *)[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:s]];
                    outOfBounds = !CGRectIntersectsRect(rowAttributes.frame, rect);
                    if (!outOfBounds)
                    {
                        [newAttributes addObject:rowAttributes];
                    }
                }
                startRowIndex = 0;
            }
        }
        
        // --- Header/Footer views ----
        // Reverse-enumerate from first visible section to see if header/footer is visible.
        // Some sections may not have rows, but still have header/footer views
        if (firstRowIndexPath != nil)
        {
            outOfBounds = NO;
            for (NSInteger s = firstRowIndexPath.section; s >= 0 && !outOfBounds; s--)
            {
                if (CGRectIntersectsRect([self rectForSection:s], rect))
                {
                    // Header
                    BOOL headerVisible = NO;
                    CGRect headerFrame = [self rectForHeaderInSection:s];
                    if (!CGRectEqualToRect(headerFrame, CGRectZero))
                    {
                        if (CGRectIntersectsRect(headerFrame, rect))
                        {
                            headerVisible = YES;
                            [newAttributes addObject:[self layoutAttributesForSupplementaryViewOfKind:RZCollectionTableViewLayoutHeaderView
                                                                                          atIndexPath:[NSIndexPath indexPathForItem:RZCVTL_HEADER_ITEM inSection:s]]];
                        }
                    }
                    
                    // Footer
                    BOOL footerVisible = NO;
                    CGRect footerFrame = [self rectForFooterInSection:s];
                    if (!CGRectEqualToRect(footerFrame, CGRectZero))
                    {
                        if (CGRectIntersectsRect(footerFrame, rect))
                        {
                            footerVisible = YES;
                            [newAttributes addObject:[self layoutAttributesForSupplementaryViewOfKind:RZCollectionTableViewLayoutFooterView
                                                                                          atIndexPath:[NSIndexPath indexPathForItem:RZCVTL_FOOTER_ITEM inSection:s]]];
                        }
                    }
                    
                    outOfBounds = !(headerVisible || footerVisible);
                    
                }
                else
                {
                    outOfBounds = YES;
                }
            }
            
            // Forward enumerate and do the same thing
            outOfBounds = NO;
            for (NSInteger s = firstRowIndexPath.section+1; s < [self.collectionView numberOfSections] && !outOfBounds; s++)
            {
                if (CGRectIntersectsRect([self rectForSection:s], rect))
                {
                    // Header
                    BOOL headerVisible = NO;
                    CGRect headerFrame = [self rectForHeaderInSection:s];
                    if (!CGRectEqualToRect(headerFrame, CGRectZero))
                    {
                        if (CGRectIntersectsRect(headerFrame, rect))
                        {
                            headerVisible = YES;
                            [newAttributes addObject:[self layoutAttributesForSupplementaryViewOfKind:RZCollectionTableViewLayoutHeaderView
                                                                                          atIndexPath:[NSIndexPath indexPathForItem:RZCVTL_HEADER_ITEM inSection:s]]];
                        }
                    }
                    
                    // Footer
                    BOOL footerVisible = NO;
                    CGRect footerFrame = [self rectForFooterInSection:s];
                    if (!CGRectEqualToRect(footerFrame, CGRectZero))
                    {
                        if (CGRectIntersectsRect(footerFrame, rect))
                        {
                            footerVisible = YES;
                            [newAttributes addObject:[self layoutAttributesForSupplementaryViewOfKind:RZCollectionTableViewLayoutFooterView
                                                                                          atIndexPath:[NSIndexPath indexPathForItem:RZCVTL_FOOTER_ITEM inSection:s]]];
                        }
                    }
                    
                    outOfBounds = !(headerVisible || footerVisible);
                    
                }
                else
                {
                    outOfBounds = YES;
                }
            }
        }
        
        self.lastAttributesForRect = newAttributes;
        attributes = newAttributes;
    }
    else
    {
        attributes = self.lastAttributesForRect;
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RZCollectionTableViewCellAttributes * rowAttributes = [self.itemAttributesCache objectForKey:indexPath];
    if (rowAttributes == nil)
    {
        rowAttributes = [RZCollectionTableViewCellAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        rowAttributes.frame = [self rectForRowAtIndexPath:indexPath];

        [self.itemAttributesCache setObject:rowAttributes forKey:indexPath];
    }
    
    // Update row position
    
    NSInteger rowsInSection = [self.collectionView numberOfItemsInSection:indexPath.section];
    
    if (rowsInSection == 1)
    {
        rowAttributes.rowPosition = RZCollectionTableViewCellRowPositionSolo;
    }
    else if (indexPath.row == 0)
    {
        rowAttributes.rowPosition = RZCollectionTableViewCellRowPositionTop;
    }
    else if (indexPath.row == rowsInSection-1)
    {
        rowAttributes.rowPosition = RZCollectionTableViewCellRowPositionBottom;
    }
    else
    {
        rowAttributes.rowPosition = RZCollectionTableViewCellRowPositionMiddle;
    }
    
    // Update editing style
    if ([self.layoutDelegate respondsToSelector:@selector(collectionView:layout:editingStyleForRowAtIndexPath:)])
    {
        rowAttributes.editingStyle = [self.layoutDelegate collectionView:self.collectionView
                                                                  layout:self
                                           editingStyleForRowAtIndexPath:indexPath];
    }
    
    if ([self.collectionView isKindOfClass:[RZCollectionTableView class]])
    {
        rowAttributes._rz_parentCollectionTableView = (RZCollectionTableView*)self.collectionView;
    }
    
    return [rowAttributes copy];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary * supplementaryKindCache = [self.supplementaryAttributesCache objectForKey:kind];
    if (supplementaryKindCache == nil)
    {
        supplementaryKindCache = [NSMutableDictionary dictionary];
        [self.supplementaryAttributesCache setObject:supplementaryKindCache forKey:kind];
    }
    
    UICollectionViewLayoutAttributes * attributes = [supplementaryKindCache objectForKey:indexPath];
    if (attributes == nil)
    {
        attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
        [supplementaryKindCache setObject:attributes forKey:indexPath];
        
        if ([kind isEqualToString:RZCollectionTableViewLayoutHeaderView])
        {
            attributes.frame = [self rectForHeaderInSection:indexPath.section];
        }
        else if ([kind isEqualToString:RZCollectionTableViewLayoutFooterView])
        {
            attributes.frame = [self rectForFooterInSection:indexPath.section];
        }
    }
    
    return [attributes copy];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind
                                                                  atIndexPath:(NSIndexPath *)indexPath
{
    // Intentionally return nil for now - decoration views not supported yet
    return nil;
}

#pragma mark - Helpers

- (NSInteger)totalRows
{
    NSInteger rows = 0;
    for (NSInteger s=0; s<[self.collectionView numberOfSections]; s++)
    {
        rows += [self.collectionView numberOfItemsInSection:s];
    }
    return rows;
}

- (id<RZCollectionTableViewLayoutDelegate>)layoutDelegate
{
    // If the delegate conforms to our protocol, return it, otherwise nil
    return ([self.collectionView.delegate conformsToProtocol:@protocol(RZCollectionTableViewLayoutDelegate)]) ? (id<RZCollectionTableViewLayoutDelegate>)self.collectionView.delegate : nil;
}

- (BOOL)sectionHasHeader:(NSInteger)section
{
    return [self headerHeightForSection:section] != 0.f;
}

- (BOOL)sectionHasFooter:(NSInteger)section
{
    return [self footerHeightForSection:section] != 0.f;
}

- (UIEdgeInsets)insetsForSection:(NSInteger)section
{
    UIEdgeInsets insets = self.sectionInsets;
    if ([self.layoutDelegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)])
    {
        insets = [self.layoutDelegate collectionView:self.collectionView
                                              layout:self
                              insetForSectionAtIndex:section];
    }
    return insets;
}

- (CGFloat)rowSpacingForSection:(NSInteger)section
{
    CGFloat spacing = self.rowSpacing;
    if ([self.layoutDelegate respondsToSelector:@selector(collectionView:layout:rowSpacingForSection:)])
    {
        spacing = [self.layoutDelegate collectionView:self.collectionView
                                               layout:self
                                 rowSpacingForSection:section];
    }
    return spacing;
}

- (CGFloat)headerHeightForSection:(NSInteger)section
{
    CGFloat height = 0.f;
    if ([self.layoutDelegate respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)])
    {
        NSNumber *cachedHeight = [self.headerHeightCache objectForKey:@(section)];
        if (cachedHeight != nil)
        {
            height = [cachedHeight floatValue];
        }
        else
        {
            height = [self.layoutDelegate collectionView:self.collectionView
                                                  layout:self
                                heightForHeaderInSection:section];
            [self.headerHeightCache setObject:@(height) forKey:@(section)];
        }
    }
    return height;
}

- (CGFloat)footerHeightForSection:(NSInteger)section
{
    CGFloat height = 0.f;
    if ([self.layoutDelegate respondsToSelector:@selector(collectionView:layout:heightForFooterInSection:)])
    {
        NSNumber *cachedHeight = [self.footerHeightCache objectForKey:@(section)];
        if (cachedHeight != nil)
        {
            height = [cachedHeight floatValue];
        }
        else
        {
            height = [self.layoutDelegate collectionView:self.collectionView
                                                  layout:self
                                heightForFooterInSection:section];
            [self.footerHeightCache setObject:@(height) forKey:@(section)];
        }
    }
    return height;
}

- (CGFloat)heightForSection:(NSInteger)section
{
    CGFloat height = 0;
    
    NSNumber *cachedHeight = [self.sectionHeightCache objectForKey:@(section)];
    if (cachedHeight != nil)
    {
        height = [cachedHeight floatValue];
    }
    else
    {
        NSInteger rowsInSection = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger i = 0; i < rowsInSection; i++)
        {
            // go ahead and cache the attributes while we're doing this
            height += [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:section]].frame.size.height;
        }
        
        if (rowsInSection > 1)
        {
            height += [self rowSpacingForSection:section] * (rowsInSection-1);
        }
        
        // header and footer - will be zero if not set/implemented in delegate
        height += [self headerHeightForSection:section];
        height += [self footerHeightForSection:section];
        
        // Insets
        UIEdgeInsets insets = [self insetsForSection:section];
        height += insets.top + insets.bottom;
        
        [self.sectionHeightCache setObject:@(height) forKey:@(section)];
    }
    
    return height;
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.rowHeight;
    
    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:heightForRowAtIndexPath:)])
    {
        NSNumber *cachedHeight = [self.rowHeightCache objectForKey:indexPath];
        if (cachedHeight != nil)
        {
            height = [cachedHeight floatValue];
        }
        else
        {
            height = [(id <RZCollectionTableViewLayoutDelegate>)self.collectionView.delegate collectionView:self.collectionView
                                                                                                     layout:self
                                                                                    heightForRowAtIndexPath:indexPath];
            [self.rowHeightCache setObject:@(height) forKey:indexPath];
        }
        
    }
    
    return height;
}

- (CGRect)rectForSection:(NSInteger)section
{
    CGPoint origin = CGPointZero;
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, [self heightForSection:section]);
    
    for (NSInteger s = 0; s < section; s++)
    {
        origin.y += [self heightForSection:s];
    }
    
    return (CGRect){origin, size};
}

- (CGRect)rectForHeaderInSection:(NSInteger)section
{
    CGRect rect = CGRectZero;
    if ([self sectionHasHeader:section])
    {
        CGPoint origin = CGPointZero;
        CGSize size = CGSizeMake(self.collectionView.bounds.size.width, [self headerHeightForSection:section]);
        
        for (NSInteger s = 0; s < section; s++)
        {
            origin.y += [self heightForSection:s];
        }
        
        origin.y += [self insetsForSection:section].top;
        
        rect = (CGRect){origin, size};
    }
    return rect;
}

- (CGRect)rectForFooterInSection:(NSInteger)section
{
    CGRect rect = CGRectZero;
    if ([self sectionHasFooter:section])
    {
        CGFloat footerHeight = [self footerHeightForSection:section];
        CGPoint origin = CGPointZero;
        CGSize size = CGSizeMake(self.collectionView.bounds.size.width, footerHeight);
        
        // Include this section
        for (NSInteger s = 0; s <= section; s++)
        {
            origin.y += [self heightForSection:s];
        }
        
        // Back up by the footer height and the inset height
        origin.y -= (footerHeight + [self insetsForSection:section].bottom);
        
        rect = (CGRect){origin, size};
    }
    return rect;
}

- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIEdgeInsets insets = [self insetsForSection:indexPath.section];
    CGFloat spacing = [self rowSpacingForSection:indexPath.section];
    
    CGPoint origin = CGPointMake(insets.left, insets.top);
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width - insets.left - insets.right, [self heightForRowAtIndexPath:indexPath]);
    
    // Add offset from previous sections
    for (NSInteger s = 0; s < indexPath.section; s++)
    {
        origin.y += [self heightForSection:s];
    }
    
    // Add offset for header
    origin.y += [self headerHeightForSection:indexPath.section];
    
    // Add offset from previous rows
    for (NSInteger r = 0; r < indexPath.item; r++)
    {
        origin.y += [self heightForRowAtIndexPath:[NSIndexPath indexPathForItem:r inSection:indexPath.section]] + spacing;
    }
    
    return (CGRect){origin, size};
}

- (NSIndexPath *)indexPathForRawRowIndex:(NSInteger)rowIndex
{
    if (rowIndex >= self.totalRows)
    {
        return nil;
    }
    
    NSInteger item = 0;
    NSInteger section = 0;
    NSInteger cumulativeRowCount = 0;
    
    // Find the section index
    BOOL found = NO;
    while (!found)
    {
        cumulativeRowCount += [self.collectionView numberOfItemsInSection:section];
        if (cumulativeRowCount < rowIndex || section < [self.collectionView numberOfSections])
        {
            // found it
            found = YES;
        }
        else
        {
            section++;
        }
    }
    
    // Find the item index
    NSInteger previousCumulativeRows = 0; // number of rows in all previous sections
    if (section > 0)
    {
        previousCumulativeRows = cumulativeRowCount - [self.collectionView numberOfItemsInSection:section];
    }
    
    item = rowIndex - previousCumulativeRows;
    
    return [NSIndexPath indexPathForItem:item inSection:section];
}

- (NSIndexPath *)indexPathOfFirstRowInRect:(CGRect)rect
{
    NSIndexPath *resultPath = nil;
    
    NSInteger numRows = self.totalRows;
    NSInteger startRow = 0;
    NSInteger endRow = numRows - 1;
    
    if (numRows == 1)
    {
        resultPath = [NSIndexPath indexPathForItem:0 inSection:0];
    }
    else
    {
        // binary search - basic strategy is to start at overall "middle" item, binary search up or down until
        // we get inside the rect, then wind back down until we hit the first item in the rect
        BOOL found = NO;
        NSInteger currentRowIdx = endRow/2;
        while (!found)
        {
            NSIndexPath *currentIndexPath = [self indexPathForRawRowIndex:currentRowIdx];
            if (currentIndexPath == nil)
            {
                break;
            }
            
            // Go ahead and cache the layout attributes while we're doing this
            CGRect rowRect = [self layoutAttributesForItemAtIndexPath:currentIndexPath].frame;
            if (CGRectIntersectsRect(rowRect, rect))
            {
                if (currentRowIdx == 0 || rowRect.origin.y <= rect.origin.y)
                {
                    resultPath = currentIndexPath;
                    found = YES;
                }
                else
                {
                    // decrement and continue until we hit the first one
                    currentRowIdx--;
                }
            }
            else
            {
                if (CGRectGetMaxY(rowRect) <= rect.origin.y)
                {
                    // half of upwards remainder
                    NSInteger remainder = endRow - currentRowIdx;
                    if (remainder <= 0)
                    {
                        // Must be the last row
                        resultPath = [self indexPathForRawRowIndex:endRow];
                        found = YES;
                    }
                    else if (remainder == 1)
                    {
                        startRow = currentRowIdx;
                        currentRowIdx++;
                    }
                    else
                    {
                        startRow = currentRowIdx;
                        currentRowIdx += (remainder/2);
                    }
                }
                else
                {
                    // half of downwards remainder
                    NSInteger remainder = currentRowIdx - startRow;
                    if (remainder <= 0)
                    {
                        // Must be the first row
                        resultPath = [NSIndexPath indexPathForItem:0 inSection:0];
                        found = YES;
                    }
                    else if (remainder == 1)
                    {
                        endRow = currentRowIdx;
                        currentRowIdx--;
                    }
                    else
                    {
                        endRow = currentRowIdx;
                        currentRowIdx -= remainder/2;
                    }
                }
            }
        }
    }
    
    return resultPath;
}

#pragma mark - Very Private

- (void)_rz_commitEditingStyle:(RZCollectionTableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.layoutDelegate respondsToSelector:@selector(collectionView:layout:commitEditingStyle:forRowAtIndexPath:)])
    {
        [self.layoutDelegate collectionView:self.collectionView
                                     layout:self
                         commitEditingStyle:editingStyle
                          forRowAtIndexPath:indexPath];
    }
}

@end

@implementation RZCollectionTableViewCellAttributes

@synthesize _rz_parentCollectionTableView = __rz_parentCollectionTableView;

- (id)copyWithZone:(NSZone *)zone
{
    RZCollectionTableViewCellAttributes *copiedAttributes = [super copyWithZone:zone];
    copiedAttributes.rowPosition = self.rowPosition;
    copiedAttributes.editingStyle = self.editingStyle;
    copiedAttributes._rz_parentCollectionTableView = self._rz_parentCollectionTableView;
    return copiedAttributes;
}

@end