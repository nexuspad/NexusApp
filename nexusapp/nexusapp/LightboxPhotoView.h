//
//  LightboxPhotoView.h
//  nexusapp
//
//  Created by Ren Liu on 8/18/13.
//
//

#import <UIKit/UIKit.h>
#import "NPScrollView.h"
#import "NPUpload.h"

@interface LightboxPhotoView : UIScrollView <UIScrollViewDelegate>

- (id)initWithFrameAndUrl:(CGRect)frame imageUpload:(NPUpload*)imageUpload;

- (void)setPhotoUrl:(NPUpload*)imageUpload;

- (void)cleanup;

@end
