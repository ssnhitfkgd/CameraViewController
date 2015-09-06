
//  AssetHelper.m
//  DoImagePickerController
//
//  Created by Donobono on 2014. 1. 23..
//

#import "AssetHelper.h"
#import "Global.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    @import Photos;
#endif
@implementation AssetHelper


+ (AssetHelper *)sharedAssetHelper
{
    static AssetHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[AssetHelper alloc] init];
        [_sharedInstance initAsset];
    });
    
    return _sharedInstance;
}

- (void)initAsset
{
    if (self.assetsLibrary == nil)
    {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        
        NSString *strVersion = [[UIDevice alloc] systemVersion];
        if ([strVersion compare:@"5"] >= 0)
            [_assetsLibrary writeImageToSavedPhotosAlbum:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            }];
    }
}

- (void)setCameraRollAtFirst
{
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    for(PHAssetCollection *group in _assetGroups)
    {
        if(group.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary)
        {
            // send to head
            [_assetGroups removeObject:group];
            [_assetGroups insertObject:group atIndex:0];
            
            return;
        }
        
    }
    return;
#endif
    }
    for (ALAssetsGroup *group in _assetGroups)
    {
        if ([[group valueForProperty:@"ALAssetsGroupPropertyType"] intValue] == ALAssetsGroupSavedPhotos)
        {
            // send to head
            [_assetGroups removeObject:group];
            [_assetGroups insertObject:group atIndex:0];
            
            return;
        }
    }
}

- (void)getGroupList:(void (^)(NSArray *))result
{
    [self initAsset];
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    _assetGroups = [[NSMutableArray alloc] init];

   
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    [smartAlbums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_assetGroups addObject:obj];
    }];

//
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    [topLevelUserCollections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([topLevelUserCollections count] -1  == idx)
        {
            [_assetGroups addObject:obj];
            
            if (_bReverse)
                _assetGroups = [[NSMutableArray alloc] initWithArray:[[_assetGroups reverseObjectEnumerator] allObjects]];
            
            [self setCameraRollAtFirst];
            result(_assetGroups);
            return;
            
        }
        [_assetGroups addObject:obj];

    }];
  
    return;
#endif
    }
    
    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
    {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];

        if (group == nil)
        {
            if (_bReverse)
                _assetGroups = [[NSMutableArray alloc] initWithArray:[[_assetGroups reverseObjectEnumerator] allObjects]];
            
            [self setCameraRollAtFirst];
            
            // end of enumeration
            result(_assetGroups);
            return;
        }
        
        [_assetGroups addObject:group];
    };
    
    void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error)
    {
        NSLog(@"Error : %@", [error description]);
    };
    
    _assetGroups = [[NSMutableArray alloc] init];
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                  usingBlock:assetGroupEnumerator
                                failureBlock:assetGroupEnumberatorFailure];
    
}

- (void)getPhotoListOfGroup:(id)alGroup result:(void (^)(NSArray *))result
{
    [self initAsset];
    
    
    _assetPhotos = [[NSMutableArray alloc] init];
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
            
            self.assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:alGroup options:options];
            [_assetsFetchResults enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
                
                if(_assetsFetchResults.count-1 == idx) {
                    [_assetPhotos addObject:asset];
                    result(_assetPhotos);
                }else{
                    [_assetPhotos addObject:asset];
                }
            }];
            
        }
        return;
#endif
    }
    
    
    [alGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    [alGroup enumerateAssetsUsingBlock:^(ALAsset *alPhoto, NSUInteger index, BOOL *stop) {
        
        if(alPhoto == nil)
        {
//            if (_bReverse){
//                _assetPhotos = [[NSMutableArray alloc] initWithArray:[[_assetPhotos reverseObjectEnumerator] allObjects]];
//            }
            

            result(_assetPhotos);
        }
        else{
            [_assetPhotos addObject:alPhoto];
        }
        
        
    }];
//    [_assetPhotos addObjectsFromArray:allFetchResultArray];

    //User albums:
//    NSMutableArray *userFetchResultArray = [[NSMutableArray alloc] init];
//    NSMutableArray *userFetchResultLabel = [[NSMutableArray alloc] init];
//    for(PHCollection *collection in topLevelUserCollections)
//    {
//        if ([collection isKindOfClass:[PHAssetCollection class]])
//        {
//            //PHFetchOptions *options = [[PHFetchOptions alloc] init];
//            //options.predicate = predicatePHAsset;
//            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
////            PHAssetCollectionType
//            //Albums collections are allways PHAssetCollectionType=1 & PHAssetCollectionSubtype=2
//            
//            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
//            [userFetchResultArray addObject:assetsFetchResult];
//            [userFetchResultLabel addObject:collection.localizedTitle];
//        }
//    }
//
//        
//    //Smart albums: Sorted by descending creation date.
//    NSMutableArray *smartFetchResultArray = [[NSMutableArray alloc] init];
//    NSMutableArray *smartFetchResultLabel = [[NSMutableArray alloc] init];
//    for(PHCollection *collection in smartAlbums)
//    {
//        if ([collection isKindOfClass:[PHAssetCollection class]])
//        {
//            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
//            
//            PHFetchOptions *options = [[PHFetchOptions alloc] init];
//            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
//            //options.predicate = predicatePHAsset;
//            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
//            if(assetsFetchResult.count>0)
//            {
//                [smartFetchResultArray addObject:assetsFetchResult];
//                [smartFetchResultLabel addObject:collection.localizedTitle];
//            }
//            
//        }
//    }
    
    
    
    

//    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
//    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
//    options.synchronous = YES;
//    options.networkAccessAllowed = YES;
//    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
//        NSLog(@"%f", progress);
//    };
//    //
//    [manager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *resultImage, NSDictionary *info)
//     {
//         UIImage *image = resultImage;
//         
//         
//     }];
    
    
}


- (void)changedPhotoLibrary:(NSInteger)index result:(void (^)(NSArray *))result
{
    self.assetPhotos = [NSMutableArray new];
    ALAssetsGroup *alGroup = [self getGroupAtIndex:index];
    [alGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
  
    
    [alGroup enumerateAssetsUsingBlock:^(ALAsset *alPhoto, NSUInteger index, BOOL *stop) {
        
        if(alPhoto == nil)
        {
            
            result(_assetPhotos);
        }
        else{
            [_assetPhotos addObject:alPhoto];
        }
        
    }];
}

- (void)getPhotoListOfGroupByIndex:(NSInteger)nGroupIndex result:(void (^)(NSArray *))result
{
    
    [self getPhotoListOfGroup:_assetGroups[nGroupIndex] result:^(NSArray *aResult) {

        result(_assetPhotos);
        
    }];
}

- (void)getSavedPhotoList:(void (^)(NSArray *))result error:(void (^)(NSError *))error
{
    [self initAsset];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
        {
            if ([[group valueForProperty:@"ALAssetsGroupPropertyType"] intValue] == ALAssetsGroupSavedPhotos)
            {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];

                [group enumerateAssetsUsingBlock:^(ALAsset *alPhoto, NSUInteger index, BOOL *stop) {
                    
                    if(alPhoto == nil)
                    {
                        if (_bReverse)
                            _assetPhotos = [[NSMutableArray alloc] initWithArray:[[_assetPhotos reverseObjectEnumerator] allObjects]];
                        
                        result(_assetPhotos);
                        return;
                    }
                    
                    [_assetPhotos addObject:alPhoto];
                }];
            }
        };
        
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *err)
        {
            NSLog(@"Error : %@", [err description]);
            error(err);
        };
        
        _assetPhotos = [[NSMutableArray alloc] init];
        [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                      usingBlock:assetGroupEnumerator
                                    failureBlock:assetGroupEnumberatorFailure];
    });
}

- (NSInteger)getGroupCount
{
    return _assetGroups.count;
}

- (NSInteger)getPhotoCountOfCurrentGroup
{
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    return [_assetsFetchResults count];
#endif
    }

    
    return _assetPhotos.count;
}

- (NSDictionary *)getGroupInfo:(NSInteger)nIndex
{
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    PHCollection *collection = _assetGroups[nIndex];
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection*)collection options:nil];

    return @{@"name" : collection.localizedTitle,
             @"count" : @([assetsFetchResult count])};
#endif
    }
    
    return @{@"name" : [_assetGroups[nIndex] valueForProperty:ALAssetsGroupPropertyName],
             @"count" : @([_assetGroups[nIndex] numberOfAssets])};
}

- (void)clearData
{
	_assetGroups = nil;
	_assetPhotos = nil;
}

#pragma mark - utils
- (UIImage *)getCroppedImage:(NSURL *)urlImage
{
    __block UIImage *iImage = nil;
    __block BOOL bBusy = YES;
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        NSString *strXMP = rep.metadata[@"AdjustmentXMP"];
        if (strXMP == nil || [strXMP isKindOfClass:[NSNull class]])
        {
            CGImageRef iref = [rep fullResolutionImage];
            if (iref)
                iImage = [UIImage imageWithCGImage:iref scale:1.0 orientation:(UIImageOrientation)rep.orientation];
            else
                iImage = nil;
        }
        else
        {
            // to get edited photo by photo app
            NSData *dXMP = [strXMP dataUsingEncoding:NSUTF8StringEncoding];
            
            CIImage *image = [CIImage imageWithCGImage:rep.fullResolutionImage];
            
            NSError *error = nil;
            NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:dXMP
                                                         inputImageExtent:image.extent
                                                                    error:&error];
            if (error) {
                NSLog(@"Error during CIFilter creation: %@", [error localizedDescription]);
            }
            
            for (CIFilter *filter in filterArray) {
                [filter setValue:image forKey:kCIInputImageKey];
                image = [filter outputImage];
            }
            
            iImage = [UIImage imageWithCIImage:image scale:1.0 orientation:(UIImageOrientation)rep.orientation];
        }
        
		bBusy = NO;
    };
    
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"booya, cant get image - %@",[myerror localizedDescription]);
    };
    
    [_assetsLibrary assetForURL:urlImage
                    resultBlock:resultblock
                   failureBlock:failureblock];
    
	while (bBusy)
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    
    return iImage;
}

- (void)downloadImageFromAsset:(id)ass type:(NSInteger)nType progressHandler:(PHAssetImageProgressHandler)progressHandler image:(Result_Block)block
{
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
   
    if(!self.imageCacheManager)
    {
        self.imageCacheManager = [[PHCachingImageManager alloc] init];
    }
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    options.synchronous = NO;
    options.networkAccessAllowed = YES;
    options.progressHandler = progressHandler;
    
    PHAsset *aa = (PHAsset*)ass;

    [manager requestImageForAsset:aa targetSize:CGSizeMake(ScreenWidth, ScreenHeight) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *resultImage, NSDictionary *info)
     {
         id obj = [info objectForKey:PHImageResultIsInCloudKey];
         
         if(block)
         {
             block(resultImage, info);
             
             if(obj && [obj integerValue] == 1)
             [self.imageCacheManager startCachingImagesForAssets:[NSArray arrayWithObject:aa] targetSize:CGSizeMake(aa.pixelWidth, aa.pixelHeight) contentMode:PHImageContentModeDefault options:nil];
         }
     }];
    
#endif
    }
}

- (UIImage *)getImageFromAsset:(id)ass type:(NSInteger)nType
{
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
 
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    options.synchronous = YES;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        NSLog(@"%f", progress);
    };
    //
    
    __block UIImage *image = nil;
    PHAsset *aa = (PHAsset*)ass;
    
    [manager requestImageForAsset:aa targetSize:CGSizeMake(aa.pixelWidth, aa.pixelHeight) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *resultImage, NSDictionary *info)
     {
         image = resultImage;
     }];
    
    return image;
    
#endif
    }
    
    ALAsset *asset = ass;
    CGImageRef iRef = nil;
    
    if (nType == ASSET_PHOTO_THUMBNAIL)
        iRef = [asset thumbnail];
    else if (nType == ASSET_PHOTO_ASPECT_THUMBNAIL)
        iRef = [asset aspectRatioThumbnail];
    else if (nType == ASSET_PHOTO_SCREEN_SIZE)
        iRef = [asset.defaultRepresentation fullScreenImage];
    else if (nType == ASSET_PHOTO_FULL_RESOLUTION)
    {
        NSString *strXMP = asset.defaultRepresentation.metadata[@"AdjustmentXMP"];
        if (strXMP == nil || [strXMP isKindOfClass:[NSNull class]])
        {
            iRef = [asset.defaultRepresentation fullResolutionImage];
            return [UIImage imageWithCGImage:iRef scale:1.0 orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        }
        else
        {
            NSData *dXMP = [strXMP dataUsingEncoding:NSUTF8StringEncoding];
            
            CIImage *image = [CIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage];
            
            NSError *error = nil;
            NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:dXMP
                                                         inputImageExtent:image.extent
                                                                    error:&error];
            if (error) {
                NSLog(@"Error during CIFilter creation: %@", [error localizedDescription]);
            }
            
            for (CIFilter *filter in filterArray) {
                [filter setValue:image forKey:kCIInputImageKey];
                image = [filter outputImage];
            }
            
            UIImage *iImage = [UIImage imageWithCIImage:image scale:1.0 orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
            return iImage;
        }
    }
    
    return [UIImage imageWithCGImage:iRef];
 
}


- (UIImage *)getImageAtIndex:(NSInteger)nIndex type:(NSInteger)nType
{
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    return   [self getImageFromAsset:self.assetsFetchResults[nIndex] type:nType];
#endif
    }
    return [self getImageFromAsset:_assetPhotos[nIndex] type:nType];
}

- (ALAsset *)getAssetAtIndex:(NSInteger)nIndex
{
    
    if(self.iCloudPhoto)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    return  self.assetsFetchResults[nIndex];
#endif
    }
    return _assetPhotos[nIndex];
}

- (ALAssetsGroup *)getGroupAtIndex:(NSInteger)nIndex
{
    if(_assetGroups && [_assetGroups count] >  nIndex)
    return _assetGroups[nIndex];
    
    return nil;
}

@end
