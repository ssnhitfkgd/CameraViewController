//
//  DoImagePickerController.m
//  DoImagePickerController
//
//  Created by Donobono on 2014. 1. 23..
//

#import "DoImagePickerController.h"
#import "AssetHelper.h"

#import "DoAlbumCell.h"
#import "DoPhotoCell.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@import Photos;
#endif


@implementation NSIndexSet (Convenience)
- (NSArray *)aapl_indexPathsFromIndexesWithSection:(NSUInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}
@end

@implementation DoImagePickerController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)reloadData
{
    [self.cvPhotoList reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self initBottomMenu];
    [self initControls];
    UINib *nib = [UINib nibWithNibName:@"DoPhotoCell" bundle:nil];
    [_cvPhotoList registerNib:nib forCellWithReuseIdentifier:@"DoPhotoCell"];
    
    [self.cvPhotoList setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, 50, 0)];

    _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    _tvAlbumList.alpha = 0.0;

    [self readAlbumList:YES];

    // new photo is located at the first of array
    ASSETHELPER.bReverse = YES;
    ASSETHELPER.iCloudPhoto = NO;
	
	if (_nMaxCount != 1)
	{
		// init gesture for multiple selection with panning
		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanForSelection:)];
		[self.view addGestureRecognizer:pan];
	}

    // init gesture for preview
    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongTapForPreview:)];
    longTap.minimumPressDuration = 0.3;
    [self.view addGestureRecognizer:longTap];
    
//    // add observer for refresh asset data
//    [[NSNotificationCenter defaultCenter] addObserver: self
//                                             selector: @selector(handleEnterForeground:)
//                                                 name: UIApplicationWillEnterForegroundNotification
//                                               object: nil];
    
//    if(NO)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:(id)self];

#endif
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];

}

//- (void)viewDidDisappear:(BOOL)animated
//{
////    if (_nResultType == DO_PICKER_RESULT_UIIMAGE)
////        [ASSETHELPER clearData];
//    
////	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
//}

- (void)handleEnterForeground:(NSNotification*)notification
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    [self.cvPhotoList reloadData];
#else
    [ASSETHELPER changedPhotoLibrary:self.nCurrentGroupIndex result:^(NSArray *array) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }];
#endif
}


#pragma mark - for init
- (void)initControls
{
    // side buttons
    _btUp.backgroundColor = DO_SIDE_BUTTON_COLOR;
    _btDown.backgroundColor = DO_SIDE_BUTTON_COLOR;
    
    CALayer *layer1 = [_btDown layer];
	[layer1 setMasksToBounds:YES];
	[layer1 setCornerRadius:_btDown.frame.size.height / 2.0 - 1];
    
    CALayer *layer2 = [_btUp layer];
	[layer2 setMasksToBounds:YES];
	[layer2 setCornerRadius:_btUp.frame.size.height / 2.0 - 1];
    
    // table view
    UIImageView *ivHeader = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _tvAlbumList.frame.size.width, 0.5)];
    ivHeader.backgroundColor = DO_ALBUM_NAME_TEXT_COLOR;
    _tvAlbumList.tableHeaderView = ivHeader;
    
    UIImageView *ivFooter = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _tvAlbumList.frame.size.width, 0.5)];
    ivFooter.backgroundColor = DO_ALBUM_NAME_TEXT_COLOR;
    _tvAlbumList.tableFooterView = ivFooter;
    
    // dimmed view
    _vDimmed.alpha = 0.0;
    _vDimmed.frame = self.view.frame;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOnDimmedView:)];
    [_vDimmed addGestureRecognizer:tap];
}

- (void)readAlbumList:(BOOL)bFirst
{
    [ASSETHELPER getGroupList:^(NSArray *aGroups) {
        
        [_tvAlbumList reloadData];

        NSInteger nIndex = 0;
#ifdef DO_SAVE_SELECTED_ALBUM
        nIndex = [self getSelectedGroupIndex:aGroups];
        if (nIndex < 0)
            nIndex = 0;
#endif
        [_tvAlbumList selectRowAtIndexPath:[NSIndexPath indexPathForRow:nIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
        [_btSelectAlbum setTitle:[ASSETHELPER getGroupInfo:nIndex][@"name"] forState:UIControlStateNormal];
        
        [self showPhotosInGroup:nIndex];
        
        if (aGroups.count == 1)
            _btSelectAlbum.enabled = NO;
        
        // calculate tableview's height
        _tvAlbumList.frame = CGRectMake(_tvAlbumList.frame.origin.x, _tvAlbumList.frame.origin.y, _tvAlbumList.frame.size.width, MIN(aGroups.count * 50, 200));
    }];
}

#pragma mark - for bottom menu
- (void)initBottomMenu
{
    _vBottomMenu.backgroundColor = DO_MENU_BACK_COLOR;
    [_btSelectAlbum setTitleColor:DO_BOTTOM_TEXT_COLOR forState:UIControlStateNormal];
    [_btSelectAlbum setTitleColor:DO_BOTTOM_TEXT_COLOR forState:UIControlStateDisabled];
    
    _ivLine1.backgroundColor = [UIColor clearColor];//[UIColor colorWithPatternImage:[UIImage imageNamed:@"line.png"]];
    _ivLine2.backgroundColor = [UIColor whiteColor];//[UIColor colorWithPatternImage:[UIImage imageNamed:@"line.png"]];
    
    if (_nMaxCount == DO_NO_LIMIT_SELECT)
    {
        _lbSelectCount.text = @"(0)";
        _lbSelectCount.textColor = DO_BOTTOM_TEXT_COLOR;
    }
    else if (_nMaxCount <= 1)
    {
        // hide ok button
        _btOK.hidden = YES;
        _ivLine1.hidden = YES;
        
        CGRect rect = _btSelectAlbum.frame;
        rect.size.width = rect.size.width + 60;
        _btSelectAlbum.frame = rect;
        
        _lbSelectCount.hidden = YES;
    }
    else
    {
        _lbSelectCount.text = [NSString stringWithFormat:@"(0/%d)", (int)_nMaxCount];
        _lbSelectCount.textColor = DO_BOTTOM_TEXT_COLOR;
    }
}

- (IBAction)onSelectPhoto:(id)sender
{
    NSMutableArray *aResult = [[NSMutableArray alloc] initWithCapacity:_dSelected.count];
    NSArray *aKeys = [_dSelected keysSortedByValueUsingSelector:@selector(compare:)];

    if (_nResultType == DO_PICKER_RESULT_UIIMAGE)
    {
        for (int i = 0; i < _dSelected.count; i++)
        {
            UIImage *iSelected = [ASSETHELPER getImageAtIndex:[aKeys[i] integerValue] type:ASSET_PHOTO_SCREEN_SIZE];
            if (iSelected != nil)
                [aResult addObject:iSelected];
        }
    }
    else
    {
        for (int i = 0; i < _dSelected.count; i++)
            [aResult addObject:[ASSETHELPER getAssetAtIndex:[aKeys[i] integerValue]]];
    }

    if(_delegate && [_delegate respondsToSelector:@selector(didSelectPhotosFromDoImagePickerController: result:)])
    [_delegate didSelectPhotosFromDoImagePickerController:self result:aResult];
}

- (IBAction)onCancel:(id)sender
{
    if(_delegate && [_delegate respondsToSelector:@selector(didCancelDoImagePickerController)])
    [_delegate didCancelDoImagePickerController];
}

- (IBAction)onSelectAlbum:(id)sender
{
    if (_tvAlbumList.frame.origin.y == _vBottomMenu.frame.origin.y)
    {
        // show tableview
        [UIView animateWithDuration:0.2 animations:^(void) {

            _vDimmed.alpha = 0.7;

            _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y - _tvAlbumList.frame.size.height,
                                            _tvAlbumList.frame.size.width, _tvAlbumList.frame.size.height);
            _tvAlbumList.alpha = 1.0;
            
            _ivShowMark.transform = CGAffineTransformMakeRotation(M_PI);
        }];
    }
    else
    {
        // hide tableview
        [self hideBottomMenu];
    }
}

#pragma mark - for side buttons
- (void)onTapOnDimmedView:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded)
    {
        [self hideBottomMenu];
        
        if (_ivPreview != nil)
            [self hidePreview];
    }
}

- (IBAction)onUp:(id)sender
{
    [_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

- (IBAction)onDown:(id)sender
{
    [_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[ASSETHELPER getPhotoCountOfCurrentGroup] - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

#pragma mark - UITableViewDelegate for selecting album
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [ASSETHELPER getGroupCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DoAlbumCell *cell = (DoAlbumCell*)[tableView dequeueReusableCellWithIdentifier:@"DoAlbumCell"];
    
    if (cell == nil)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"DoAlbumCell" owner:nil options:nil] lastObject];
    }

    NSDictionary *d = [ASSETHELPER getGroupInfo:indexPath.row];
    cell.lbAlbumName.text   = d[@"name"];
    cell.lbCount.text       = [NSString stringWithFormat:@"%@", d[@"count"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showPhotosInGroup:indexPath.row];
    [_btSelectAlbum setTitle:[ASSETHELPER getGroupInfo:indexPath.row][@"name"] forState:UIControlStateNormal];

    [self hideBottomMenu];
}

- (void)hideBottomMenu
{
    [UIView animateWithDuration:0.2 animations:^(void) {
        
        _vDimmed.alpha = 0.0;
        
        _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y, _tvAlbumList.frame.size.width, _tvAlbumList.frame.size.height);
        _ivShowMark.transform = CGAffineTransformMakeRotation(0);
        
        [UIView setAnimationDelay:0.1];

        _tvAlbumList.alpha = 0.0;
    }];
}

#pragma mark - UICollectionViewDelegates for photos
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [ASSETHELPER getPhotoCountOfCurrentGroup];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DoPhotoCell *cell = (DoPhotoCell *)[_cvPhotoList dequeueReusableCellWithReuseIdentifier:@"DoPhotoCell" forIndexPath:indexPath];


//    [cell.ivPhoto setSize:CGSizeMake(n, n)];
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        PHAsset *aa = (PHAsset*)[ASSETHELPER getAssetAtIndex:indexPath.row];
        
        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            NSLog(@"%f", progress);
        };
        
        CGFloat scale = [UIScreen mainScreen].scale;
        int n = ((ScreenWidth - (_nColumnCount-1)*4) /_nColumnCount) * scale;
        
        CGSize tableCellThumbnailSize1 = CGSizeMake(n, n);
        [manager requestImageForAsset:aa
                           targetSize:tableCellThumbnailSize1
                          contentMode:PHImageContentModeAspectFill
                              options:options
                        resultHandler:^(UIImage *resultImage, NSDictionary *info)
         {
             cell.ivPhoto.image = resultImage;
         }];
#endif
    }
    else
    {
        ALAsset *aa = [ASSETHELPER getAssetAtIndex:indexPath.row];
        if([aa isKindOfClass:[ALAsset class]])
        {
            cell.ivPhoto.image = [ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_THUMBNAIL];
        }
    }
    
//        cell.ivPhoto.image = [ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_ASPECT_THUMBNAIL];
    

    

	if (_dSelected[@(indexPath.row)] == nil)
		[cell setSelectMode:NO];
    else
		[cell setSelectMode:YES];
	
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DoPhotoCell *cell = (DoPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];

    if (_nMaxCount > 1 || _nMaxCount == DO_NO_LIMIT_SELECT)
    {
        
		if ((_dSelected[@(indexPath.row)] == nil) && (_nMaxCount > _dSelected.count))
		{
			// select
            
			_dSelected[@(indexPath.row)] = @(_dSelected.count);
			[cell setSelectMode:YES];
		}
		else
		{
			// unselect
			[_dSelected removeObjectForKey:@(indexPath.row)];
			[cell setSelectMode:NO];
		}
        
        if (_nMaxCount == DO_NO_LIMIT_SELECT)
            _lbSelectCount.text = [NSString stringWithFormat:@"(%d)", (int)_dSelected.count];
        else
            _lbSelectCount.text = [NSString stringWithFormat:@"(%d/%d)", (int)_dSelected.count, (int)_nMaxCount];
    }
    else
    {
        if(_delegate && [_delegate respondsToSelector:@selector(didSelectPhotosFromDoImagePickerController:result:)])
        {
            if (_nResultType == DO_PICKER_RESULT_UIIMAGE)
            {
                if(self.iCloudPhoto)
                {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                [_delegate didSelectPhotosFromDoImagePickerController:self result:@[[ASSETHELPER getAssetAtIndex:indexPath.row],cell.ivPhoto.image]];
                return;
#endif
                }
                
                [_delegate didSelectPhotosFromDoImagePickerController:self result:@[[ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_SCREEN_SIZE]]];
            }
            else
            {
                [_delegate didSelectPhotosFromDoImagePickerController:self result:@[[ASSETHELPER getAssetAtIndex:indexPath.row]]];
            }
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int n = ((ScreenWidth - (_nColumnCount-1)*4) /_nColumnCount);
    if(_nColumnCount>1){
        return CGSizeMake(n,n);
    }
//    if (_nColumnCount == 2)
//        return CGSizeMake(158, 158);
//    else if (_nColumnCount == 3)
//        return CGSizeMake(104, 104);
//    else if (_nColumnCount == 4)
//    {
//        return CGSizeMake(77, 77);
//    }
//
    return CGSizeZero;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _cvPhotoList)
    {
        [UIView animateWithDuration:0.2 animations:^(void) {
            if (scrollView.contentOffset.y <= 50)
                _btUp.alpha = 0.0;
            else
                _btUp.alpha = 1.0;
            
            if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height)
                _btDown.alpha = 0.0;
            else
                _btDown.alpha = 1.0;
        }];
    }
}

// for multiple selection with panning
- (void)onPanForSelection:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (_ivPreview != nil)
        return;
    
    double fX = [gestureRecognizer locationInView:_cvPhotoList].x;
    double fY = [gestureRecognizer locationInView:_cvPhotoList].y;
	
    for (UICollectionViewCell *cell in _cvPhotoList.visibleCells)
	{
        float fSX = cell.frame.origin.x;
        float fEX = cell.frame.origin.x + cell.frame.size.width;
        float fSY = cell.frame.origin.y;
        float fEY = cell.frame.origin.y + cell.frame.size.height;
        
        if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY)
        {
            NSIndexPath *indexPath = [_cvPhotoList indexPathForCell:cell];
            
            if (_lastAccessed != indexPath)
            {
				[self collectionView:_cvPhotoList didSelectItemAtIndexPath:indexPath];
            }
            
            _lastAccessed = indexPath;
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        _lastAccessed = nil;
        _cvPhotoList.scrollEnabled = YES;
    }
}

// for preview
- (void)onLongTapForPreview:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    return;
#endif
    }
    
    if (_ivPreview != nil)
        return;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        double fX = [gestureRecognizer locationInView:_cvPhotoList].x;
        double fY = [gestureRecognizer locationInView:_cvPhotoList].y;

        // check boundary of controls
        CGPoint pt = [gestureRecognizer locationInView:self.view];
        if (CGRectContainsPoint(_vBottomMenu.frame, pt))
            return;
        if (_btDown.alpha == 1.0 && CGRectContainsPoint(_btDown.frame, pt))
            return;
        if (_btUp.alpha == 1.0 && CGRectContainsPoint(_btUp.frame, pt))
            return;
        
        NSIndexPath *indexPath = nil;
        for (UICollectionViewCell *cell in _cvPhotoList.visibleCells)
        {
            float fSX = cell.frame.origin.x;
            float fEX = cell.frame.origin.x + cell.frame.size.width;
            float fSY = cell.frame.origin.y;
            float fEY = cell.frame.origin.y + cell.frame.size.height;
            
            if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY)
            {
                indexPath = [_cvPhotoList indexPathForCell:cell];
                break;
            }
        }
        
        if (indexPath != nil)
            [self showPreview:indexPath.row];
    }
}

#pragma mark - for photos
- (void)showPhotosInGroup:(NSInteger)nIndex
{
    if (_nMaxCount == DO_NO_LIMIT_SELECT)
    {
        _dSelected = [[NSMutableDictionary alloc] init];
        _lbSelectCount.text = @"(0)";
    }
    else if (_nMaxCount > 1)
    {
        _dSelected = [[NSMutableDictionary alloc] initWithCapacity:_nMaxCount];
        _lbSelectCount.text = [NSString stringWithFormat:@"(0/%d)", (int)_nMaxCount];
    }
    
    [ASSETHELPER getPhotoListOfGroupByIndex:nIndex result:^(NSArray *aPhotos) {
        
        [_cvPhotoList reloadData];
        
        _cvPhotoList.alpha = 0.3;
        [UIView animateWithDuration:0.2 animations:^(void) {
            [UIView setAnimationDelay:0.1];
            _cvPhotoList.alpha = 1.0;
        }];
//        
//        [UIView animateWithDuration:0.2 delay:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            
//        } completion:^(BOOL finished) {
//            
//        }];
		
        if (aPhotos.count > 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
//                [_cvPhotoList setContentOffset:CGPointMake(0, ([aPhotos count]-1)*74)];
                [_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[aPhotos count]-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                
            });
        }
        _btUp.alpha = 0.0;

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (_cvPhotoList.contentSize.height < _cvPhotoList.frame.size.height)
                _btDown.alpha = 0.0;
            else
                _btDown.alpha = 1.0;
        });
        
    }];
    
#ifdef DO_SAVE_SELECTED_ALBUM
    // save selected album
    [self saveSelectedGroup:nIndex];
#endif
    
}



- (void)showPreview:(NSInteger)nIndex
{
    [self.view bringSubviewToFront:_vDimmed];
    
    _ivPreview = [[UIImageView alloc] initWithFrame:_vDimmed.frame];
    _ivPreview.contentMode = UIViewContentModeScaleAspectFit;
    _ivPreview.autoresizingMask = _vDimmed.autoresizingMask;
    [_vDimmed addSubview:_ivPreview];
    
    _ivPreview.image = [ASSETHELPER getImageAtIndex:nIndex type:ASSET_PHOTO_SCREEN_SIZE];
    
    // add gesture for close preview
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanToClosePreview:)];
    [_vDimmed addGestureRecognizer:pan];
    
    [UIView animateWithDuration:0.2 animations:^(void) {
        _vDimmed.alpha = 1.0;
    }];
}

- (void)hidePreview
{
    [self.view bringSubviewToFront:_tvAlbumList];
    [self.view bringSubviewToFront:_vBottomMenu];
    
    [_ivPreview removeFromSuperview];
    _ivPreview = nil;

    _vDimmed.alpha = 0.0;
    [_vDimmed removeGestureRecognizer:[_vDimmed.gestureRecognizers lastObject]];
}

- (void)onPanToClosePreview:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint translation = [gestureRecognizer translationInView:self.view];

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [UIView animateWithDuration:0.2 animations:^(void) {
            
            if (_vDimmed.alpha < 0.7)   // close preview
            {
                CGPoint pt = _ivPreview.center;
                if (_ivPreview.center.y > _vDimmed.center.y)
                    pt.y = self.view.frame.size.height * 1.5;
                else if (_ivPreview.center.y < _vDimmed.center.y)
                    pt.y = -self.view.frame.size.height * 1.5;

                _ivPreview.center = pt;

                [self hidePreview];
            }
            else
            {
                _vDimmed.alpha = 1.0;
                _ivPreview.center = _vDimmed.center;
            }
        }];
    }
    else
    {
		_ivPreview.center = CGPointMake(_ivPreview.center.x, _ivPreview.center.y + translation.y);
		[gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
        
        _vDimmed.alpha = 1 - ABS(_ivPreview.center.y - _vDimmed.center.y) / (self.view.frame.size.height / 2.0);
    }
}

#pragma mark - save selected album
- (void)saveSelectedGroup:(NSInteger)nIndex
{
    self.nCurrentGroupIndex = nIndex;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    PHCollection *collection = (PHCollection*)[ASSETHELPER getGroupAtIndex:nIndex];
//    PHFetchResult *assetsFetchResult = (PHFetchResult*)[PHAsset fetchAssetsInAssetCollection:(PHAssetCollection*)collection options:nil];
    [defaults setObject:collection.localizedTitle forKey:@"DO_SELECTED_ALBUM"];
    [defaults synchronize];
    return;
#endif
    }
	[defaults setObject:[[ASSETHELPER getGroupAtIndex:nIndex] valueForProperty:ALAssetsGroupPropertyName] forKey:@"DO_SELECTED_ALBUM"];
	[defaults synchronize];
    
}

- (NSString *)loadSelectedGroup
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    NSLog(@"---------> %@", [defaults objectForKey:@"DO_SELECTED_ALBUM"]);
    
    return [defaults objectForKey:@"DO_SELECTED_ALBUM"];
}

- (NSInteger)getSelectedGroupIndex:(NSArray *)aGroups
{
    NSString *strOldAlbumName = [self loadSelectedGroup];
    for (int i = 0; i < aGroups.count; i++)
    {
        NSDictionary *d = [ASSETHELPER getGroupInfo:i];
        if ([d[@"name"] isEqualToString:strOldAlbumName])
            return i;
    }
    
    return -1;
}

#pragma mark - Others
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
//    if(self.iCloudPhoto)
    {
        [ASSETHELPER changedPhotoLibrary:self.nCurrentGroupIndex result:^(NSArray *array) {
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadData];
                });
        }];
        
        return;
    }
    
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{

        // check if there are changes to the assets (insertions, deletions, updates)
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:ASSETHELPER.assetsFetchResults];
        if (collectionChanges) {
            
            ASSETHELPER.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
            
            UICollectionView *collectionView = self.cvPhotoList;
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // we need to reload all if the incremental diffs are not available
                [collectionView reloadData];
                
            } else {

                // if we have incremental diffs, tell the collection view to animate insertions and deletions
                [collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                } completion:NULL];
            }
            
        }
    });
    
}
#endif

- (void)resetCachedAssets
{
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
//    PHCachingImageManager *manager = (PHCachingImageManager*)[PHCachingImageManager defaultManager];
//    [manager stopCachingImagesForAllAssets];
//#endif
 
}

- (void)dealloc
{
    
//    if (_nResultType == DO_PICKER_RESULT_UIIMAGE)
//        [ASSETHELPER clearData];
    
    [_cvPhotoList setDelegate:nil];
    [_cvPhotoList setDataSource:nil];
    self.cvPhotoList = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];

//    if(self.iCloudPhoto)
//    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:(id)self];
#endif
//    }

}
@end
