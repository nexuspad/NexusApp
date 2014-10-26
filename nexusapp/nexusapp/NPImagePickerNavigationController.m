//
//  NPImagePickerNavigationController.m
//  nexuspad
//
//  Created by Ren Liu on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPImagePickerNavigationController.h"
#import "ELCAlbumPickerController.h"
#import "ViewDisplayHelper.h"

@interface NPImagePickerNavigationController()
@property (nonatomic, strong) UIImagePickerController *photoPickerFromCamera;
@end

@implementation NPImagePickerNavigationController

@synthesize imagePickerDelegate = _imagePickerDelegate;

- (void)cancelImagePicker
{
	if([_imagePickerDelegate respondsToSelector:@selector(didCancelImagePicker)]) {
        [_imagePickerDelegate didCancelImagePicker];
	}
}

- (void)selectedAssets:(NSArray *)assets {
	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	
	for(ALAsset *asset in assets) {
		NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];

		[workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType] forKey:@"UIImagePickerControllerMediaType"];
        [workingDictionary setObject:[UIImage imageWithCGImage:[asset thumbnail]] forKey:@"UIImagePickerControllerThumbnailImage"];
        
		[workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs]
                                      valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]]
                              forKey:@"UIImagePickerControllerReferenceURL"];
		
		[returnArray addObject:workingDictionary];
    }

	if(_imagePickerDelegate != nil && [_imagePickerDelegate respondsToSelector:@selector(didFinishPickingMediaWithInfo:)]) {
        [_imagePickerDelegate didFinishPickingMediaWithInfo:returnArray];
        
	} else {
        [self popToRootViewControllerAnimated:NO];
    }
}

- (void)openCamera {
    if (self.photoPickerFromCamera == nil) {
        self.photoPickerFromCamera = [[UIImagePickerController alloc] init];
        self.photoPickerFromCamera.delegate = self;
        //self.photoPickerFromCamera.allowsEditing = YES;                                                       // ios 7 bug ****
        self.photoPickerFromCamera.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    // Bring up the camera
    [self presentViewController:self.photoPickerFromCamera animated:YES completion:nil];
}

#pragma mark - UIImagePickerDelegate

// Photo taken using camera
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:NO completion:nil];

    if(_imagePickerDelegate != nil && [_imagePickerDelegate respondsToSelector:@selector(didFinishTakingPhoto:metaData:)]) {
        [_imagePickerDelegate didFinishTakingPhoto:[info valueForKey:UIImagePickerControllerOriginalImage]      // Use original ****
                                        metaData:[info valueForKey:UIImagePickerControllerMediaMetadata]];
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    NSLog(@"ELC Image Picker received memory warning.");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

@end
