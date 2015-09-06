//
//  AssetHelper.m
//  DoImagePickerController
//
//  Created by Donobono on 2014. 1. 23..
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@import Photos;
#endif

#define ASSETHELPER    [AssetHelper sharedAssetHelper]

#define ASSET_PHOTO_THUMBNAIL           0
#define ASSET_PHOTO_ASPECT_THUMBNAIL    1
#define ASSET_PHOTO_SCREEN_SIZE         2
#define ASSET_PHOTO_FULL_RESOLUTION     3

typedef void(^Result_Block)(UIImage *image, NSDictionary *dict);

@interface AssetHelper : NSObject

- (void)initAsset;

@property (nonatomic, strong)   ALAssetsLibrary			*assetsLibrary;
@property (nonatomic, strong)   NSMutableArray          *assetPhotos;
@property (nonatomic, strong)   NSMutableArray          *assetGroups;
@property (nonatomic, strong)  NSMutableArray *iClondResultArray;
@property (readwrite)           BOOL                    bReverse;
@property (readwrite)           BOOL        iCloudPhoto;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@property (strong)  PHFetchResult *assetsFetchResults;
@property (strong) PHCachingImageManager *imageCacheManager;
#endif

- (void)changedPhotoLibrary:(NSInteger)index result:(void (^)(NSArray *))result;
+ (AssetHelper *)sharedAssetHelper;

// get album list from asset
- (void)getGroupList:(void (^)(NSArray *))result;
// get photos from specific album with ALAssetsGroup object
- (void)getPhotoListOfGroup:(id)alGroup result:(void (^)(NSArray *))result;
// get photos from specific album with index of album array
- (void)getPhotoListOfGroupByIndex:(NSInteger)nGroupIndex result:(void (^)(NSArray *))result;
// get photos from camera roll
- (void)getSavedPhotoList:(void (^)(NSArray *))result error:(void (^)(NSError *))error;

- (NSInteger)getGroupCount;
- (NSInteger)getPhotoCountOfCurrentGroup;
- (NSDictionary *)getGroupInfo:(NSInteger)nIndex;

- (void)clearData;

// utils
- (UIImage *)getCroppedImage:(NSURL *)urlImage;
- (UIImage *)getImageFromAsset:(ALAsset *)asset type:(NSInteger)nType;
- (UIImage *)getImageAtIndex:(NSInteger)nIndex type:(NSInteger)nType;
- (ALAsset *)getAssetAtIndex:(NSInteger)nIndex;
- (ALAssetsGroup *)getGroupAtIndex:(NSInteger)nIndex;

- (void)downloadImageFromAsset:(id)ass type:(NSInteger)nType progressHandler:(PHAssetImageProgressHandler)progressHandler image:(Result_Block)block;
@end

