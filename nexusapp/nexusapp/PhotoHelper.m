//
//  ProfilePhotoHelper.m
//  nexusapp
//
//  Created by Ren Liu on 12/4/13.
//
//

#import "PhotoHelper.h"
#import "UIImage+Resize.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+NPUtil.h"
#import "NPWebApiService.h"

#define SHRINK_TO_WIDTH 100.0

@interface PhotoHelper()
@property BOOL isPlaceHolder;
@property (nonatomic, strong) NSString *photoImageUrl;
@property (nonatomic, strong) UIImagePickerController *photoPicker;
@end

@implementation PhotoHelper

- (id)initWithExistingPhoto:(id)photo isPlaceHolder:(BOOL)isPlaceHolder rect:(CGRect)rect {
    self = [super init];
    
    self.isPlaceHolder = isPlaceHolder;

    self.photoImageView = [[UIImageView alloc] initWithFrame:rect];

    [self.photoImageView setUserInteractionEnabled:YES];
    
    if (photo == nil) {
        [self setToDefaultPlaceholder];

    } else {
        if ([photo isKindOfClass:[UIImage class]]) {
            [self.photoImageView setImage:(UIImage*)photo];

        } else if ([photo isKindOfClass:[NSString class]]) {
            self.photoImageUrl = [NPWebApiService appendAuthParams:photo];

            __weak PhotoHelper *weakSelf = self;

            [self.photoImageView sd_setImageWithURL:[NSURL URLWithString:self.photoImageUrl]
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (error != nil) {
                    weakSelf.isPlaceHolder = YES;
                }
            }];
            
//            [self.photoImageView setImageWithURL:[NSURL URLWithString:self.photoImageUrl]
//                                placeholderImage:[UIImage imageNamed:@"avatar.png"]
//                                                             options:SDWebImageRefreshCached
//
//             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//                 if (error != nil) {
//                     weakSelf.isPlaceHolder = YES;
//                 }
//             }];
        }
    }

    // Tap gesture
    UITapGestureRecognizer *tapImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updateContactPhotoActions:)];
    [self.photoImageView addGestureRecognizer:tapImage];

    [UIImageView roundedCorner:self.photoImageView];
    
    return self;
}

- (void)updatePhoto:(id)photo {
    self.isPlaceHolder = NO;
    if ([photo isKindOfClass:[UIImage class]]) {
        [self.photoImageView setImage:(UIImage*)photo];
        
    } else if ([photo isKindOfClass:[NSString class]]) {
        self.photoImageUrl = [NPWebApiService appendAuthParams:photo];
        
        __weak PhotoHelper *weakSelf = self;
        
        [self.photoImageView sd_setImageWithURL:[NSURL URLWithString:self.photoImageUrl]
                            placeholderImage:[UIImage imageNamed:@"avatar.png"]
                                     options:SDWebImageRefreshCached
         
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                       if (error != nil) {
                                           weakSelf.isPlaceHolder = YES;
                                       }
                                   }];
    }
}

- (void)setToDefaultPlaceholder {
    self.isPlaceHolder = YES;
    [self.photoImageView setImage:[UIImage imageNamed:@"avatar.png"]];
}

- (void)updateContactPhotoActions:(id)sender {
    NSString *message = NSLocalizedString(@"Update contact photo",);
    
    UIActionSheet *actionSheet = nil;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
        if (!self.isPlaceHolder) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                        destructiveButtonTitle:NSLocalizedString(@"Delete",)
                                             otherButtonTitles:NSLocalizedString(@"Take a new photo",),
                           NSLocalizedString(@"Replace from photo library",), nil];
        } else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"Take a photo",),
                           NSLocalizedString(@"Select from photo library",), nil];
        }
        
    } else {
        if (!self.isPlaceHolder) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                        destructiveButtonTitle:NSLocalizedString(@"Delete",)
                                             otherButtonTitles:NSLocalizedString(@"Replace from photo library",), nil];
        } else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"Select from photo library",), nil];
        }
        
    }

    if (self.photoUpdateDelegate != nil) {
        UIViewController *parentViewController = (UIViewController*)self.photoUpdateDelegate;
        [actionSheet showInView:parentViewController.view];
    }

}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index {
    if (self.isPlaceHolder) {                                       // No destructive button
        if (index == sender.cancelButtonIndex) {
            [sender dismissWithClickedButtonIndex:index animated:YES];
            
        } else if (index == 0) {                                    // take a photo
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
                [self takeContactPhoto];
            } else {
                [self selectContactPhoto];
            }
            
        } else if (index == 1) {                                    // select a photo from library
            [self selectContactPhoto];
        }
        
    } else {
        if (index == sender.destructiveButtonIndex) {
            if (self.photoImageUrl.length > 0) {
                // Make sure the SDWeb cache is cleared.
                [[SDImageCache sharedImageCache] removeImageForKey:self.photoImageUrl fromDisk:YES];
            }

            [self.photoUpdateDelegate didDeletedPhoto];
            
            [self.photoImageView setImage:[UIImage imageNamed:@"avatar.png"]];
            self.photoImageView.clipsToBounds = YES;
            
        } else if (index == sender.cancelButtonIndex) {
            [sender dismissWithClickedButtonIndex:index animated:YES];
            
        } else if (index == 1) {                                    // take a photo
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
                [self takeContactPhoto];
            } else {
                [self selectContactPhoto];
            }
            
        } else if (index == 2) {                                    // select a photo from library
            [self selectContactPhoto];
        }
    }
}

- (void)selectContactPhoto {
    if (self.photoPicker == nil) {
        self.photoPicker = [[UIImagePickerController alloc] init];
        self.photoPicker.delegate = self;
        self.photoPicker.allowsEditing = YES;
        self.photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    if (self.photoUpdateDelegate != nil) {
        UIViewController *parentViewController = (UIViewController*)self.photoUpdateDelegate;
        [parentViewController.navigationController presentViewController:self.photoPicker animated:YES completion:nil];
    }
}

- (void)takeContactPhoto {
    if (self.photoPicker == nil) {
        self.photoPicker = [[UIImagePickerController alloc] init];
        self.photoPicker.delegate = self;
        self.photoPicker.allowsEditing = YES;
        self.photoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }

    if (self.photoUpdateDelegate != nil) {
        UIViewController *parentViewController = (UIViewController*)self.photoUpdateDelegate;
        [parentViewController.navigationController presentViewController:self.photoPicker animated:YES completion:nil];
    }
}

// Delegate method called from UIImagePickerController
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
	UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    // Create new size for profile photo
    float width = image.size.width;
    float height = image.size.height;
    
    if (width > SHRINK_TO_WIDTH) {
        height = SHRINK_TO_WIDTH/width * height;
    }
    CGSize newSize = CGSizeMake(SHRINK_TO_WIDTH, height);
    
    UIImage *smallerImage = [image resizedImage:newSize interpolationQuality:kCGInterpolationMedium];
    self.photoImageView.image = smallerImage;
    self.photoImageView.clipsToBounds = YES;
    
    self.isPlaceHolder = NO;

    [self.photoUpdateDelegate didSelectedPhoto:smallerImage];
}

@end
