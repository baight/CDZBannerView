//
//  CDZBannerView.h
//
//
//  Created by cui baight on 13-5-29.
//  Copyright (c) 2013年 baight. All rights reserved.
//

#import <UIKit/UIKit.h>

// enormously modified by zhengchen2 2013-12-27
/*
 
 BannerView 是一个 可以实现若干张图片图片循环滚动的控件
 BannerView 中某张图片被点击时，会向 委托 发送 bannerViewDidClicked: 消息，参数为图片索引
 
 属性 imageArray 是一个数组，里边储存着要循环显示的图片信息
 如果 imageArray 成员若是 NSURL 类，则展示网络图片，网络图片未下载下来时，显示 属性placeholderImage图片
 如果 imageArray 成员若是 NSString 类，并且 NSString 类是以 "http://" 开头的，将该NSString视为一个有效网络图片链接，同上。
 如果 imageArray 成员若是 NSString 类，并且 NSString 类是不是以 "http" 开头的，则将NSString视为一个有效本地图片名称，进行显示
 imageArray 中至少应该有一张图片，否则显示不正常
 
 属性 placeholderImage 是当网络图片未下载下来时，所显示的图片。
 
 */



@interface CDZBannerView : UIView<UIScrollViewDelegate, UIGestureRecognizerDelegate>{
    UIScrollView *_scrollView;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@property (nonatomic, retain, readonly) UIImageView* screen0;  // 第一屏
@property (nonatomic, retain, readonly) UIImageView* screen1;  // 第二屏
@property (nonatomic, retain, readonly) UIImageView* screen2;  // 第三屏

@property (nonatomic, strong, readonly) UIPageControl* pageControl;

@property (nonatomic, weak) IBOutlet id delegate;

@property (nonatomic, retain) NSArray* imageArray;                  // 要显示的图片信息数组
@property (nonatomic, retain) UIImage* placeholderImage;            // 网络图片未下载下来时，显示该本地图片。该属性有默认值，可不设置
@property (nonatomic, assign) NSTimeInterval timeInterval;         // 图片滚动间隔
@property (nonatomic, assign) NSInteger currentPage;             // 当前显示第几页,从 0 开始计算

@property (nonatomic, assign) BOOL canClickImage;
@property (nonatomic, assign) BOOL canCycleScroll;

-(void)setImageArray:(NSArray *)imageArray initPage:(NSInteger)initPage;

- (id)initWithFrame:(CGRect)frame delegate:delegate;
- (id)initWithFrame:(CGRect)frame delegate:delegate imageArray:(NSArray*)items;

-(void)switchToNextPage;
-(void)switchToLastPage;

@end


@protocol CDZBannerViewDelegate <NSObject>
@optional
-(void)bannerView:(CDZBannerView*)bannerView clickIndex:(NSInteger)index;
-(void)bannerView:(CDZBannerView*)bannerView didSwithToPage:(NSInteger)currentPage;
@end
