//
//  HySideScrollingImagePicker.m
//  TestProject
//
//  Created by Apple on 15/6/25.
//  Copyright (c) 2015年 Apple. All rights reserved.
//

#import "HySideScrollingImagePicker.h"
#import "SideScrollingLayout.h"
#import "HCollectionViewCell.h"
#import "SideScrollingCheckCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AssetsLibraryD.h"

#define kImageSpacing 5.0f
#define kCollectionViewHeight 178.0f
#define kSubTitleHeight 65.0f
#define ItemHeight 50.0f
#define H [UIScreen mainScreen].bounds.size.height
#define W [UIScreen mainScreen].bounds.size.width
#define Color [UIColor colorWithRed:26/255.0f green:178.0/255.0f blue:10.0f/255.0f alpha:1]
#define Spacing 7.0f
#define KMaxSize CGSizeMake(W-20, 100)


@interface HySideScrollingImagePicker ()<UICollectionViewDataSource,UICollectionViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,copy)NSString *cancelStr;

@property (nonatomic,strong)NSArray *ButtonTitles;

@property (nonatomic,weak) UIView * BottomView;

@property (nonatomic,weak)UICollectionView *CollectionView;

@property (nonatomic, strong) NSMapTable *indexPathToCheckViewTable;

@property (nonatomic,strong) NSMutableArray *allArr;

@property (nonatomic, strong) NSMutableArray *selectedIndexes;

@property (nonatomic,strong)NSIndexPath	* lastIndexPath;

@property (nonatomic,strong)NSMutableArray *assetsGroups;

@property (nonatomic,retain)NSMutableArray *IndexPathArr;

@property (retain, nonatomic) AssetsLibraryD *assets;

@end

@interface Window : UIWindow

@property (nonatomic, weak)   UIView  *rootView;

@end

@implementation Window

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

@end

@implementation HySideScrollingImagePicker

-(instancetype) initWithCancelStr:(NSString *)str otherButtonTitles:(NSArray *)Titles{
    
    self = [super init];
    if (self) {
        _cancelStr = str;
        _ButtonTitles = Titles;
        [self loadData];
    }
    return self;
}

-(void)LoadUI{
    self.selectedIndexes = [NSMutableArray array];
    /*self*/
    [self setFrame:CGRectMake(0, 0, W, H)];
    [self setBackgroundColor:[UIColor clearColor]];
    /*end*/
    
    /*buttomView*/
    UIView *ButtomView;
    UIView *TopView;
    NSInteger Ids = 0;
    double version = [[UIDevice currentDevice].systemVersion doubleValue];//判定系统
    if (version >= 8.0f) {
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        ButtomView = [[UIVisualEffectView alloc] initWithEffect:blur];
        
    }else if(version >= 7.0f){
        
        ButtomView = [[UIToolbar alloc] init];
        
    }else{
        
        ButtomView = [[UIView alloc] init];
        Ids = true;
        
    }
    if (Ids == 1) {
        ButtomView.backgroundColor = [UIColor colorWithRed:223.0f/255.0f green:226.0f/255.f blue:236.0f/255.0f alpha:1];
    }
    CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_ButtonTitles.count * (ItemHeight+0.5f)) + kCollectionViewHeight;
    
    [ButtomView setFrame:CGRectMake(0, H, W, height)];
    _BottomView = ButtomView;
    [self addSubview:ButtomView];
    
    TopView = [[UIView alloc] init];
    TopView.backgroundColor = [UIColor clearColor];
    [TopView setTag:999];
    [TopView setFrame:CGRectMake(0, 0, W, H)];
    [self addSubview:TopView];
    /*end*/
    
    /*CanceBtn*/
    UIButton *Cancebtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [Cancebtn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7f]];
    [Cancebtn setFrame:CGRectMake(0, CGRectGetHeight(ButtomView.bounds) - ItemHeight, W, ItemHeight)];
    [Cancebtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [Cancebtn setTitle:_cancelStr forState:UIControlStateNormal];
    [Cancebtn addTarget:self action:@selector(SelectedButtons:) forControlEvents:UIControlEventTouchUpInside];
    [Cancebtn addTarget:self action:@selector(scaleToSmall:)
  forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [Cancebtn addTarget:self action:@selector(scaleAnimation:)
  forControlEvents:UIControlEventTouchUpInside];
    [Cancebtn addTarget:self action:@selector(scaleToDefault:)
  forControlEvents:UIControlEventTouchDragExit];
    [Cancebtn setTag:100];
    [_BottomView addSubview:Cancebtn];
    /*end*/
    
    /*Items*/
    for (NSString *Title in _ButtonTitles) {
        
        NSInteger index = [_ButtonTitles indexOfObject:Title];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7f]];
        
        CGFloat hei = (50 * _ButtonTitles.count)+Spacing;
        CGFloat y = (CGRectGetMinY(Cancebtn.frame) + (index * (ItemHeight))) - hei;
        
        [btn setFrame:CGRectMake(0, y, W, ItemHeight)];
        [btn setTag:(index + 100)+1];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitle:Title forState:UIControlStateNormal];
        [btn titleLabel].font = [UIFont systemFontOfSize:15.0f];
        [btn addTarget:self action:@selector(SelectedButtons:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(scaleToSmall:)
       forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [btn addTarget:self action:@selector(scaleAnimation:)
       forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(scaleToDefault:)
       forControlEvents:UIControlEventTouchDragExit];
        [_BottomView addSubview:btn];
        if ((index+1) == _ButtonTitles.count) {
            break;
        }
        UIView *lin = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetHeight(btn.bounds) - 0.5f, W, 0.5f)];
        lin.backgroundColor = [UIColor colorWithRed:228.0f/255 green:229.0f/255 blue:230.f/255 alpha:1];
        [btn addSubview:lin];
    }
    /*END*/
    
    /*CollectionView*/
    
    // Configure the flow layout
    SideScrollingLayout *flow = [[SideScrollingLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flow.minimumInteritemSpacing = kImageSpacing;
    
    // Configure the collection view
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flow];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.allowsMultipleSelection = YES;
    collectionView.allowsSelection = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.collectionViewLayout = flow;
    [collectionView registerClass:[HCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [collectionView registerClass:[SideScrollingCheckCell class] forSupplementaryViewOfKind:@"check" withReuseIdentifier:@"CheckCell"];
    collectionView.contentInset = UIEdgeInsetsMake(0, 6, 0, 6);
    
    [ButtomView addSubview:collectionView];
    self.CollectionView = collectionView;
    
    self.CollectionView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
    
    self.indexPathToCheckViewTable = [NSMapTable strongToWeakObjectsMapTable];
    
    [self.CollectionView setFrame:CGRectMake(0, 5, W, kCollectionViewHeight-10)];
    
    UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.CollectionView.bounds)/2 - 10 , CGRectGetHeight(self.CollectionView.bounds)/2 - 10, 20, 20)];
    act.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    [act setTag:10101];
    [act startAnimating];
    [self.CollectionView addSubview:act];
    
    /*enb*/
    typeof(self) __weak weak = self;
    __block BOOL stop = true;
    
    [_assets UpDataBlock:^(NSArray *ImgsData)
    {
        if (stop) {
            weak.allArr = [NSMutableArray arrayWithArray:ImgsData];
            [weak.CollectionView reloadData];
            [act stopAnimating];
            if (ImgsData.count != 0) {
                stop = FALSE;
            }
        }
    }];
    
    
    [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        
        [TopView setFrame:CGRectMake(0, 0, W, H - height)];
        [TopView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f]];
        [ButtomView setFrame:CGRectMake(0, H - height, W, height+10)];
        
    } completion:^(BOOL finished) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:weak action:@selector(dismiss:)];
        tap.delegate = self;
        [TopView addGestureRecognizer:tap];
        [ButtomView setFrame:CGRectMake(0, H - height, W, height)];
    }];
}

-(AssetsLibraryD *)assets
{
    if (!_assets) {
        _assets = [[AssetsLibraryD alloc] init];
    }
    return _assets;
}

-(void)loadData{

    typeof(self) __weak weak = self;
    _assets = [self assets];
    //UIActivityIndicatorView *act=  (UIActivityIndicatorView *)[self viewWithTag:10101];
    [_assets setUserIsOpen:^(BOOL is) {
        
        if (!is) {
            return ;
        }
        _IndexPathArr = [NSMutableArray array];
        [weak LoadUI];
        NSLog(@"end");
    }];
}

-(void)scaleToSmall:(UIButton *)btn{
    
    [UIView animateWithDuration:0.2 animations:^{
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.0f]];
    }];
    
}

- (void)scaleAnimation:(UIButton *)btn{

    [UIView animateWithDuration:0.2 animations:^{
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.0f]];
    }];
    
}

- (void)scaleToDefault:(UIButton *)btn{

    [UIView animateWithDuration:0.2 animations:^{
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7f]];
    }];
    
}

-(void)SelectedButtons:(UIButton *)btns{
    
    typeof(self) __weak weak = self;
    [self DismissBlock:^(BOOL Complete) {
        
        weak.SeletedImages(weak.selectedIndexes,btns.tag-100);
        
    }];
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return MIN(100, _allArr.count);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    HCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    ALAsset *asset = [_allArr objectAtIndex:indexPath.row];
    
    UIImage *image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
    
    cell.asset = asset;
    cell.imageView.image = image;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath;
{
    SideScrollingCheckCell *checkView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"CheckCell" forIndexPath:indexPath];
    [self.indexPathToCheckViewTable setObject:checkView forKey:indexPath];
    
    if ([self.IndexPathArr containsObject:indexPath]) {
        [checkView setChecked:YES];
    }else{
        [checkView setChecked:FALSE];
    }
    return checkView;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    //[collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionRight];
    [self toggleSelectionAtIndexPath:indexPath];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [self toggleSelectionAtIndexPath:indexPath];

}

- (void)toggleSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    UIButton *Ti = (UIButton *)[_BottomView viewWithTag:101];
    
    HCollectionViewCell *cell = (HCollectionViewCell *)[self.CollectionView cellForItemAtIndexPath:indexPath];
    SideScrollingCheckCell *checkmarkView = [self.indexPathToCheckViewTable objectForKey:indexPath];
    
    if (!_isMultipleSelection) {
        
        // Manage internal selection state
        if ([self.IndexPathArr containsObject:indexPath]) {

            [_selectedIndexes removeObject:cell.asset];
            [_IndexPathArr removeObject:indexPath];
            [cell setSelected:NO];
            [checkmarkView setChecked:NO];
            
        } else {
            
            [self.selectedIndexes addObject:cell.asset];
            [cell setSelected:YES];
            [checkmarkView setChecked:YES];
            [_IndexPathArr addObject:indexPath];
        }
        
    }else{
        
        [self.selectedIndexes addObject:cell.asset];
        [cell setSelected:YES];
        [checkmarkView setChecked:YES];
        typeof(self) __weak weak = self;
        [self DismissBlock:^(BOOL Complete) {
            weak.SeletedImages(self.selectedIndexes,MAXFLOAT);
        }];
        
    }
    if (self.selectedIndexes.count == 0) {
        
        [Ti setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [Ti setTitle:[_ButtonTitles objectAtIndex:Ti.tag-101] forState:UIControlStateNormal];
        
    }else{
        
        [Ti setTitle:[NSString stringWithFormat:@"选择(%ld张)",self.selectedIndexes.count] forState:UIControlStateNormal];
        [Ti setTitleColor:Color forState:UIControlStateNormal];
        
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    
    ALAsset *asset = [_allArr objectAtIndex:indexPath.row];
    
    UIImage *imageAtPath = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
    
    CGFloat imageHeight = imageAtPath.size.height;
    CGFloat viewHeight = collectionView.bounds.size.height;
    CGFloat scaleFactor = viewHeight/imageHeight;
    
    CGSize scaledSize = CGSizeApplyAffineTransform(imageAtPath.size, CGAffineTransformMakeScale(scaleFactor, scaleFactor));
    return scaledSize;
}

-(void)DismissBlock:(CompleteAnimationBlock)block{
    
    //typeof(self) __weak weak = self;
    CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_ButtonTitles.count * (ItemHeight+0.5f)) + kCollectionViewHeight;
    UIView *TopView = [self viewWithTag:999];
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        [TopView setFrame:CGRectMake(0, 0, W, H)];
        [TopView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0f]];
        [_BottomView setFrame:CGRectMake(0, H, W, height)];
        
    } completion:^(BOOL finished) {
        
        block(finished);
        [self removeFromSuperview];
        
    }];
    
}

-(void)SeletedImages:(SeletedImages)SeletedImage{

    _SeletedImages = SeletedImage;
}

-(void)dismiss:(UITapGestureRecognizer *)tap{
    
    if( CGRectContainsPoint(self.frame, [tap locationInView:_BottomView])) {
        NSLog(@"tap");
    } else{
        
        [self DismissBlock:^(BOOL Complete) {
            
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *TopView = [self viewWithTag:999];
    if (touch.view != TopView) {
        return NO;
    }
    
    return YES;
}

-(void)dealloc{

    NSLog(@"移除");
}

-(void)addSubview:(UIView *)view{

    [super addSubview:view];

}

-(UIViewController *)viewController:(UIView *)view{
    /// Finds the view's view controller.
    // Traverse responder chain. Return first found view controller, which will be the view's view controller.
    UIResponder *responder = view;
    while ((responder = [responder nextResponder]))
        if ([responder isKindOfClass: [UIViewController class]])
            return (UIViewController *)responder;
    // If the view controller isn't found, return nil.
    return nil;
}


@end

@class HyActionSheet;

@interface HyActionSheet ()<UIGestureRecognizerDelegate>

@property (nonatomic,copy)      NSString *CancelStr;

@property (nonatomic,strong)    NSArray *Titles;

@property (nonatomic,weak)      UIView *ButtomView;

@property (nonatomic,copy)      NSString *AttachTitle;

@end

@implementation HyActionSheet

-(instancetype) initWithCancelStr:(NSString *)str otherButtonTitles:(NSArray *)Titles AttachTitle:(NSString *)AttachTitle{
    
    self = [super init];
    
    if (self) {
        
        _AttachTitle = AttachTitle;
        _CancelStr = str;
        _Titles = Titles;
        [self loadUI];
        
    }
    
    return self;
}

-(void)loadUI{
    
    /*self*/
    [self setFrame:CGRectMake(0, 0, W, H)];
    [self setBackgroundColor:[UIColor clearColor]];
    /*end*/
    
    /*buttomView*/
    UIView *ButtomView;
    UIView *TopView;
    NSInteger Ids = 0;
    double version = [[UIDevice currentDevice].systemVersion doubleValue];//判定系统
    if (version >= 8.0f) {
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        ButtomView = [[UIVisualEffectView alloc] initWithEffect:blur];
        
    }else if(version >= 7.0f){
        
        ButtomView = [[UIToolbar alloc] init];
        
    }else{
        
        ButtomView = [[UIView alloc] init];
        Ids = true;
        
    }
    if (Ids == 1) {
        ButtomView.backgroundColor = [UIColor colorWithRed:223.0f/255.0f green:226.0f/255.f blue:236.0f/255.0f alpha:1];
    }
    CGFloat height;
    UIFont *font = [UIFont systemFontOfSize:12.0f];
    CGSize size = [self markGetAuthenticSize:_AttachTitle Font:font MaxSize:KMaxSize];
    
    if ([self isBlankString:_AttachTitle]) {
        height = ((ItemHeight)+Spacing) + (_Titles.count * (ItemHeight));
    }else{
        height  = ((ItemHeight)+Spacing) + (_Titles.count * (ItemHeight)) + (size.height+50);
    }
    
    [ButtomView setFrame:CGRectMake(0, H , W, height)];
    _ButtomView = ButtomView;
    [self addSubview:ButtomView];
    
    TopView = [[UIView alloc] init];
    TopView.backgroundColor = [UIColor clearColor];
    [TopView setTag:999];
    [TopView setFrame:CGRectMake(0, 0, W, H)];
    [self addSubview:TopView];
    /*end*/
    
    /*CanceBtn*/
    UIButton *Cancebtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [Cancebtn setFrame:CGRectMake(0, CGRectGetHeight(ButtomView.bounds) - ItemHeight, W, ItemHeight)];
    [Cancebtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [Cancebtn setTitle:_CancelStr forState:UIControlStateNormal];
    [Cancebtn addTarget:self action:@selector(SelectedButtons:) forControlEvents:UIControlEventTouchUpInside];
    [Cancebtn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.6f]];
    [Cancebtn addTarget:self action:@selector(scaleToSmall:)
       forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [Cancebtn addTarget:self action:@selector(scaleAnimation:)
       forControlEvents:UIControlEventTouchUpInside];
    [Cancebtn addTarget:self action:@selector(scaleToDefault:)
       forControlEvents:UIControlEventTouchDragExit];
    [Cancebtn setTag:100];
    [_ButtomView addSubview:Cancebtn];
    /*end*/
    
    /*Items*/
    for (NSString *Title in _Titles) {
        
        NSInteger index = [_Titles indexOfObject:Title];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setBackgroundColor:[UIColor whiteColor]];
        
        CGFloat hei = (50 * _Titles.count)+Spacing;
        CGFloat y = (CGRectGetMinY(Cancebtn.frame) + (index * (ItemHeight))) - hei;
        
        [btn setFrame:CGRectMake(0, y, W, ItemHeight)];
        [btn setTag:(index + 100)+1];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitle:Title forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(SelectedButtons:) forControlEvents:UIControlEventTouchUpInside];
        [btn titleLabel].font = [UIFont systemFontOfSize:15.0f];
        [btn addTarget:self action:@selector(SelectedButtons:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(scaleToSmall:)
      forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [btn addTarget:self action:@selector(scaleAnimation:)
      forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(scaleToDefault:)
      forControlEvents:UIControlEventTouchDragExit];
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.6f]];
        
        UIView *lin = [[UIView alloc]initWithFrame:CGRectMake(0, 0, W, 0.5f)];
        lin.backgroundColor = [UIColor colorWithRed:228.0f/255 green:229.0f/255 blue:230.f/255 alpha:1];
        [_ButtomView addSubview:btn];
        [btn addSubview:lin];
    }
    /*END*/
    
    if ([self isBlankString:_AttachTitle]) {
        
    }else{
        
        UIView *views = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, size.height+50)];
        views.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.6f];
        UILabel *AttachTitleView = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, W-20, size.height+50)];
        AttachTitleView.font = font;
        AttachTitleView.textColor = [UIColor grayColor];
        AttachTitleView.text = _AttachTitle;
        AttachTitleView.numberOfLines = 0;
        AttachTitleView.textAlignment = 1;
        [_ButtomView addSubview:views];
        [views addSubview:AttachTitleView];
        [self layoutIfNeeded];
    }
    
    typeof(self) __weak weak = self;
    [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        //[weak setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f]];
        [TopView setFrame:CGRectMake(0, 0, W, H - height)];
        [TopView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f]];
        [ButtomView setFrame:CGRectMake(0, H - height, W, height+10)];
        
    } completion:^(BOOL finished) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:weak action:@selector(dismiss:)];
        tap.delegate = self;
        [TopView addGestureRecognizer:tap];
        [ButtomView setFrame:CGRectMake(0, H - height, W, height)];
    }];
    
}

-(void)scaleToSmall:(UIButton *)btn{
    
    [UIView animateWithDuration:0.2 animations:^{
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.0f]];
    }];
    
}

- (void)scaleAnimation:(UIButton *)btn{
    
    [UIView animateWithDuration:0.2 animations:^{
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.0f]];
    }];
    
}

- (void)scaleToDefault:(UIButton *)btn{
    
    [UIView animateWithDuration:0.2 animations:^{
        [btn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.6f]];
    }];
    
}

-(void)SelectedButtons:(UIButton *)btns{
    
    typeof(self) __weak weak = self;
    [self DismissBlock:^(BOOL Complete) {
        
        if (!weak.ButtonIndex) {
            return ;
        }
        weak.ButtonIndex(btns.tag-100);
        
    }];
    
    
}

-(void) ChangeTitleColor:(UIColor *)color AndIndex:(NSInteger )index{
    
    UIButton *btn = (UIButton *)[_ButtomView viewWithTag:index + 100];
    [btn setTitleColor:color forState:UIControlStateNormal];
    
}

-(void)ButtonIndex:(SeletedButtonIndex)ButtonIndex{

    _ButtonIndex = ButtonIndex;
    
}

-(void)dismiss:(UITapGestureRecognizer *)tap{
    
    if( CGRectContainsPoint(self.frame, [tap locationInView:_ButtomView])) {
        NSLog(@"tap");
    } else{
        
        [self DismissBlock:^(BOOL Complete) {
            
        }];
    }
}

-(void)DismissBlock:(CompleteAnimationBlock)block{
    
    
    typeof(self) __weak weak = self;
    CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_Titles.count * (ItemHeight+0.5f)) + kCollectionViewHeight;
    UIView *TopView = [self viewWithTag:999];
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        
        [TopView setFrame:CGRectMake(0, 0, W, H)];
        [TopView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0f]];
        
        [_ButtomView setFrame:CGRectMake(0, H, W, height)];
        
    } completion:^(BOOL finished) {
        
        block(finished);
        [weak removeFromSuperview];
        
    }];
    
}

- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

-(CGSize)markGetAuthenticSize:(NSString *)text Font:(UIFont *)font MaxSize:(CGSize)size{
    
    //获取当前那本属性
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil];
    //实际尺寸
    CGSize actualSize = [text boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil].size;
    
    return actualSize;
    
}

@end
