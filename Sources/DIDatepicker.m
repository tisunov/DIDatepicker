//
//  Created by Dmitry Ivanenko on 14.04.14.
//  Copyright (c) 2014 Dmitry Ivanenko. All rights reserved.
//

#import "DIDatepicker.h"
#import "DIDatepickerDateView.h"

const CGFloat kDIDatepickerHeight = 60.;
const CGFloat kDIDatepickerSpaceBetweenItems = 6.;
NSString * const kDIDatepickerCellIndentifier = @"kDIDatepickerCellIndentifier";

@interface DIDatepicker (){
    NSIndexPath *selectedIndexPath;
}

@property (strong, nonatomic) UICollectionView *datesCollectionView;
@property (strong, nonatomic, readwrite) NSDate *selectedDate;

@end


@implementation DIDatepicker

- (void)awakeFromNib
{
    [self setupViews];
}

- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]){
        [self setupViews];
    }
    
    return self;
}

- (void)setupViews
{
//    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor whiteColor];
    self.bottomLineColor = [UIColor colorWithWhite:0.816 alpha:1.000];
    self.selectedDateBottomLineColor = [UIColor colorWithRed:242./255. green:93./255. blue:28./255. alpha:1.];
}

#pragma mark Setters | Getters

- (void)setDates:(NSArray *)dates
{
    _dates = dates;
    
    [self.datesCollectionView reloadData];
    
    self.selectedDate = nil;
}

- (void)setSelectedDate:(NSDate *)selectedDate
{
    _selectedDate = selectedDate;
    
    NSIndexPath *selectedCellIndexPath = [NSIndexPath indexPathForItem:[self.dates indexOfObject:selectedDate] inSection:0];
    [self.datesCollectionView performBatchUpdates:^{
        [self.datesCollectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
        [self.datesCollectionView selectItemAtIndexPath:selectedCellIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    } completion:nil];
    selectedIndexPath = selectedCellIndexPath;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.datesCollectionView.collectionViewLayout;
    [collectionViewLayout setItemSize:CGSizeMake(CGRectGetWidth(self.bounds) / 7.0f - kDIDatepickerSpaceBetweenItems, CGRectGetHeight(self.bounds))];
    self.datesCollectionView.frame = CGRectMake(self.datesCollectionView.frame.origin.x, self.datesCollectionView.frame.origin.y, self.bounds.size.width, self.datesCollectionView.frame.size.height);
}

- (UICollectionView *)datesCollectionView
{
    if (!_datesCollectionView) {
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        // Make space for 7 days
        [collectionViewLayout setItemSize:CGSizeMake(CGRectGetWidth(self.bounds) / 7.0f - kDIDatepickerSpaceBetweenItems, CGRectGetHeight(self.bounds))];
        [collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        [collectionViewLayout setSectionInset:UIEdgeInsetsMake(0, kDIDatepickerSpaceBetweenItems / 2, 0, kDIDatepickerSpaceBetweenItems / 2)];
        [collectionViewLayout setMinimumLineSpacing:kDIDatepickerSpaceBetweenItems];
        
        _datesCollectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:collectionViewLayout];
        _datesCollectionView.pagingEnabled = YES;
        [_datesCollectionView registerClass:[DIDatepickerCell class] forCellWithReuseIdentifier:kDIDatepickerCellIndentifier];
        [_datesCollectionView setBackgroundColor:[UIColor clearColor]];
        [_datesCollectionView setShowsHorizontalScrollIndicator:NO];
        [_datesCollectionView setAllowsMultipleSelection:NO];
        _datesCollectionView.dataSource = self;
        _datesCollectionView.delegate = self;
        [self addSubview:_datesCollectionView];
    }
    return _datesCollectionView;
}

- (void)setSelectedDateBottomLineColor:(UIColor *)selectedDateBottomLineColor
{
    _selectedDateBottomLineColor = selectedDateBottomLineColor;
    
    [self.datesCollectionView.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DIDatepickerCell *selectedCell = (DIDatepickerCell *)[self.datesCollectionView cellForItemAtIndexPath:obj];
        selectedCell.itemSelectionColor = _selectedDateBottomLineColor;
    }];
}

#pragma mark Public methods

- (void)selectDate:(NSDate *)date
{
    [[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit startDate:&date interval:NULL forDate:date];
    
    NSAssert([self.dates indexOfObject:date] != NSNotFound, @"Date not found in dates array");
    
    self.selectedDate = date;
}

- (void)selectDateAtIndex:(NSUInteger)index
{
    NSAssert(index < self.dates.count, @"Index too big");
    
    self.selectedDate = self.dates[index];
}

// -

- (void)fillDatesFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSAssert([fromDate compare:toDate] == NSOrderedAscending, @"toDate must be after fromDate");
    
    NSMutableArray *dates = [[NSMutableArray alloc] init];
    NSDateComponents *days = [[NSDateComponents alloc] init];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSInteger dayCount = 0;
    while(YES){
        [days setDay:dayCount++];
        NSDate *date = [calendar dateByAddingComponents:days toDate:fromDate options:0];
        
        if([date compare:toDate] == NSOrderedDescending) break;
        [dates addObject:date];
    }
    
    self.dates = dates;
}

- (void)fillDatesFromDate:(NSDate *)fromDate numberOfDays:(NSInteger)numberOfDays
{
    NSDateComponents *days = [[NSDateComponents alloc] init];
    [days setDay:numberOfDays];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [self fillDatesFromDate:fromDate toDate:[calendar dateByAddingComponents:days toDate:fromDate options:0]];
}

- (NSDate *)beginningOfWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                    fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:components];
    
    NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:today];
    
    NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
    [componentsToSubtract setDay: - ((([weekdayComponents weekday] - [calendar firstWeekday]) + 7 ) % 7)];
    
    return [calendar dateByAddingComponents:componentsToSubtract toDate:today options:0];
}

- (void)fillCurrentWeek
{
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:today];
    
    NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
    [componentsToSubtract setDay: - ((([weekdayComponents weekday] - [calendar firstWeekday]) + 7 ) % 7)];
    NSDate *beginningOfWeek = [calendar dateByAddingComponents:componentsToSubtract toDate:today options:0];
    
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    [componentsToAdd setDay:6];
    NSDate *endOfWeek = [calendar dateByAddingComponents:componentsToAdd toDate:beginningOfWeek options:0];
    
    [self fillDatesFromDate:beginningOfWeek toDate:endOfWeek];
}

- (void)selectNextDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    [componentsToAdd setDay:1];
    [self selectDate:[calendar dateByAddingComponents:componentsToAdd toDate:_selectedDate options:0]];
}

- (void)selectPreviousDate {
    if ([_selectedDate isEqualToDate:[self beginningOfWeek]]) return;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    [componentsToAdd setDay:-1];
    
    NSDate *previousDate = [calendar dateByAddingComponents:componentsToAdd toDate:_selectedDate options:0];
    
    [self selectDate:previousDate];
}

- (void)fillWeeksFromCurrent {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    // Override locale to make week start on Monday
    [calendar setFirstWeekday:2];
    
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    [componentsToAdd setDay:7 * 52];
    
    NSDate *beginningOfWeek = [self beginningOfWeek];
    NSDate *lastDayOfWeek52FromNow = [calendar dateByAddingComponents:componentsToAdd toDate:beginningOfWeek options:0];
    
    [self fillDatesFromDate:[self beginningOfWeek] toDate:lastDayOfWeek52FromNow];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSDateComponents *bofComponents = [calendar components:NSCalendarUnitWeekday fromDate:beginningOfWeek];
    
    [self selectDateAtIndex:components.weekday - bofComponents.weekday];
}

- (void)fillCurrentMonth
{
    [self fillDatesWithCalendarUnit:NSCalendarUnitMonth];
}

- (void)fillCurrentYear
{
    [self fillDatesWithCalendarUnit:NSCalendarUnitYear];
}

#pragma mark Private methods

- (void)fillDatesWithCalendarUnit:(NSCalendarUnit)unit
{
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *beginning;
    NSTimeInterval length;
    [calendar rangeOfUnit:unit startDate:&beginning interval:&length forDate:today];
    NSDate *end = [beginning dateByAddingTimeInterval:length-1];
    
    [self fillDatesFromDate:beginning toDate:end];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    // draw bottom line
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, self.bottomLineColor.CGColor);
    CGContextSetLineWidth(context, .5);
    CGContextMoveToPoint(context, 0, rect.size.height - .5);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height - .5);
    CGContextStrokePath(context);
}

#pragma mark - UICollectionView Delegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return  [self.dates count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DIDatepickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kDIDatepickerCellIndentifier forIndexPath:indexPath];
    cell.date = [self.dates objectAtIndex:indexPath.item];
    cell.itemSelectionColor = _selectedDateBottomLineColor;
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ![indexPath isEqual:selectedIndexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //    [self.datesCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    _selectedDate = [self.dates objectAtIndex:indexPath.item];
    
    [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
    selectedIndexPath = indexPath;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}


@end
