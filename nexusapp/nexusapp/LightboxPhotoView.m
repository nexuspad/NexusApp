//
//  LightboxPhotoView.m
//  nexusapp
//
//  Created by Ren Liu on 8/18/13.
//
//

#import "LightboxPhotoView.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "ViewDisplayHelper.h"
#import "Constants.h"
#import "NPWebApiService.h"

@interface LightboxPhotoView ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation LightboxPhotoView

@synthesize imageView = _imageView;

- (id)initWithFrameAndUrl:(CGRect)frame imageUpload:(NPUpload*)imageUpload {
    self = [super initWithFrame:frame];

    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:frame];
        
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.contentSize = CGSizeMake(frame.size.width, frame.size.height);
        self.maximumZoomScale = 1.85;
        self.minimumZoomScale = 1;
        self.clipsToBounds = YES;
        self.delegate = self;
        
        [self addSubview:_imageView];
        
        if (imageUpload.photoUrl != nil) {
            [self setPhotoUrl:imageUpload];
        } else {
            [_imageView setImage:[UIImage imageNamed:@"placeholder.png"]];
        }
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        [doubleTap setNumberOfTapsRequired:2];
        [self addGestureRecognizer:doubleTap];
    }

    return self;
}

- (void)setPhotoUrl:(NPUpload*)imageUpload {
    if (imageUpload.photoUrl == nil) {
        [_imageView setImage:[UIImage imageNamed:@"placeholder.png"]];

    } else {

        NSString *photoUrl = [NPWebApiService appendAuthParams:imageUpload.photoUrl];
        DLog(@"photo url: %@", photoUrl);

        UIImage *placeHolderImage;
        
        if (imageUpload.thumbnailImage != nil) {
            placeHolderImage = imageUpload.thumbnailImage;
        } else {
            placeHolderImage = [UIImage imageNamed:@"placeholder.png"];
        }
        
        [_imageView sd_setImageWithURL:[NSURL URLWithString:photoUrl]
                   placeholderImage:placeHolderImage
                            options:SDWebImageProgressiveDownload
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                if (error != nil) {
                                 // Only uncomment when debugging
                                 //DLog(@"Error displaying lightbox photo: %@", error);
                                }
         }];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)inScroll {
    return _imageView;
}


- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
    DLog(@"double tapped....");
    if(self.zoomScale > self.minimumZoomScale)
        [self setZoomScale:self.minimumZoomScale animated:YES];
    else
        [self setZoomScale:self.maximumZoomScale animated:YES];
    
}

- (void)cleanup {
    DLog(@".....clean up photo view at index %li.....", (long)self.tag);
    [_imageView sd_cancelCurrentImageLoad];
    _imageView.image = nil;
    _imageView = nil;
}

@end
