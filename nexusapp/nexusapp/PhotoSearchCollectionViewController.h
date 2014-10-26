//
//  PhotoSearchCollectionViewController.h
//  nexusapp
//
//  Created by Ren Liu on 8/16/13.
//
//

#import <UIKit/UIKit.h>
#import "EntryList.h"
#import "EntryLightboxViewDelegate.h"

@interface PhotoSearchCollectionViewController : UICollectionViewController
                                                <UISearchBarDelegate,
                                                EntryLightboxViewDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) EntryList *searchListResult;

@end
