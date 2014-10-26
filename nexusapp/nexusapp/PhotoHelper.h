//
//  ProfilePhotoHelper.h
//  nexusapp
//
//  Created by Ren Liu on 12/4/13.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol PhotoHelperDelegate <NSObject>
- (void)didDeletedPhoto;
- (void)didSelectedPhoto:(UIImage*)selectedPhoto;
@end

/**
 * The helper class handles displaying of Profile photo and other UI activities.
 * Actual service calls to the backend are made through the controller delegate.
 */
@interface PhotoHelper : NSObject <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (id)initWithExistingPhoto:(id)photo isPlaceHolder:(BOOL)isPlaceHolder rect:(CGRect)rect;

- (void)updatePhoto:(id)photo;

@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, weak) id<PhotoHelperDelegate> photoUpdateDelegate;

- (void)setToDefaultPlaceholder;

@end
