//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "ATArrayView.h"


@interface ATArrayView () <UIScrollViewDelegate>

- (void)updateItemViews:(BOOL)updateExisting;
- (void)configureItem:(UIView *)item forIndex:(NSInteger)index;

@end



@implementation ATArrayView

@synthesize delegate=_delegate;
@synthesize itemSize=_itemSize;
@synthesize contentInsets=_contentInsets;
@synthesize minimumColumnGap=_minimumColumnGap;
@synthesize itemCount=_itemCount;


#pragma mark -
#pragma mark init/dealloc

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_visibleItems = [[NSMutableSet alloc] init];
		_recycledItems = [[NSMutableSet alloc] init];

		_itemSize = CGSizeMake(70, 70);
		_contentInsets = UIEdgeInsetsMake(8, 8, 8, 8);
		_minimumColumnGap = 5;

		_scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
		_scrollView.showsVerticalScrollIndicator = YES;
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.bounces = YES;
		_scrollView.delegate = self;
		[self addSubview:_scrollView];
	}
	return self;
}

- (void)dealloc {
	[_scrollView release], _scrollView = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Data Changes

- (void)reloadItems {
	_itemCount = [_delegate numberOfItemsInArrayView:self];

	// recycle all items
	for (UIView *view in _visibleItems) {
		[_recycledItems addObject:view];
		[view removeFromSuperview];
	}
	[_visibleItems removeAllObjects];

	[self updateItemViews:NO];
}


#pragma mark -
#pragma mark Item View Management

- (UIView *)viewForItemAtIndex:(NSUInteger)index {
    for (UIView *item in _visibleItems)
        if (item.tag == index)
            return item;
    return nil;
}

- (void)configureItem:(UIView *)item forIndex:(NSInteger)index {
    item.tag = index;
    item.frame = [self rectForItemAtIndex:index];
	[item setNeedsDisplay]; // just in case
}

- (void)updateItemViews:(BOOL)reconfigure {
	// update content size if needed
	CGSize contentSize = CGSizeMake(self.bounds.size.width,
									_itemSize.height * _rowCount + _rowGap * (_rowCount - 1) + _contentInsets.top + _contentInsets.bottom);
	if (_scrollView.contentSize.width != contentSize.width || _scrollView.contentSize.height != contentSize.height) {
		_scrollView.contentSize = contentSize;
	}

    // calculate which items are visible
    int firstItem = self.firstVisibleItemIndex;
    int lastItem  = self.lastVisibleItemIndex;

    // recycle items that are no longer visible
    for (UIView *item in _visibleItems) {
        if (item.tag < firstItem || item.tag > lastItem) {
            [_recycledItems addObject:item];
            [item removeFromSuperview];
        }
    }
    [_visibleItems minusSet:_recycledItems];

    // add missing items
    for (int index = firstItem; index <= lastItem; index++) {
		UIView *item = [self viewForItemAtIndex:index];
		if (item == nil) {
			item = [_delegate viewForItemInArrayView:self atIndex:index];
            [_scrollView addSubview:item];
            [_visibleItems addObject:item];
		} else if (!reconfigure) {
			continue;
		}
		[self configureItem:item forIndex:index];
    }
}


#pragma mark -
#pragma mark Layouting

- (void)layoutSubviews {
	BOOL boundsChanged = !CGRectEqualToRect(_scrollView.frame, self.bounds);
	if (boundsChanged)
		_scrollView.frame = self.bounds;

	_colCount = floorf((self.bounds.size.width - _contentInsets.left - _contentInsets.right) / _itemSize.width);

	while (1) {
		_colGap = (self.bounds.size.width - _contentInsets.left - _contentInsets.right - _itemSize.width * _colCount) / (_colCount - 1);
		if (_colGap >= _minimumColumnGap)
			break;
		--_colCount;
	};

	_rowCount = (_itemCount + _colCount - 1) / _colCount;
	_rowGap = _colGap;

	[self updateItemViews:boundsChanged];
}

- (NSInteger)firstVisibleItemIndex {
    int firstRow = MAX(floorf((CGRectGetMinY(_scrollView.bounds) - _contentInsets.top) / (_itemSize.height + _rowGap)), 0);
	return MIN(firstRow * _colCount, _itemCount - 1);
}

- (NSInteger)lastVisibleItemIndex {
    int lastRow = MIN( ceilf((CGRectGetMaxY(_scrollView.bounds) - _contentInsets.top) / (_itemSize.height + _rowGap)), _rowCount - 1);
	return MIN((lastRow + 1) * _colCount - 1, _itemCount - 1);
}

- (CGRect)rectForItemAtIndex:(NSUInteger)index {
	NSInteger row = index / _colCount;
	NSInteger col = index % _colCount;

    return CGRectMake(_contentInsets.left + (_itemSize.width  + _colGap) * col,
					  _contentInsets.top  + (_itemSize.height + _rowGap) * row,
					  _itemSize.width, _itemSize.height);
}


#pragma mark -
#pragma mark Recycling

- (UIView *)dequeueReusableItem {
	UIView *result = [_recycledItems anyObject];
	if (result) {
		[_recycledItems removeObject:[[result retain] autorelease]];
	}
	return result;
}


#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self updateItemViews:NO];
}

@end



#pragma mark -

@implementation ATArrayViewController


#pragma mark -
#pragma mark init/dealloc

- (void)dealloc {
	[super dealloc];
}


#pragma mark -
#pragma mark View Loading

- (void)loadView {
	self.view = [[[ATArrayView alloc] init] autorelease];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (self.arrayView.delegate == nil)
		self.arrayView.delegate = self;
}


#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
	if (self.arrayView.itemCount == 0)
		[self.arrayView reloadItems];
}


#pragma mark -
#pragma mark View Access

- (ATArrayView *)arrayView {
	return (ATArrayView *)self.view;
}


#pragma mark -
#pragma mark ATArrayViewDelegate methods

- (NSInteger)numberOfItemsInArrayView:(ATArrayView *)arrayView {
	return 0;
}

- (UIView *)viewForItemInArrayView:(ATArrayView *)arrayView atIndex:(NSInteger)index {
	return nil;
}

@end