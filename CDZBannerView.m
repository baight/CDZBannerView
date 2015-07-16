//
//  CDZBannerView.m
//
//
//  Created by cui baight on 13-5-29.
//  Copyright (c) 2013年 baight. All rights reserved.
//

#import "CDZBannerView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+WebCache.h"

#define OFFSET_X 7.0f
#define SPACE_V 5.0f
#define HEIGHT 50.0f
#define TEXT_COLOR [UIColor whiteColor]

// enormously modified by zhengchen2
// 想要实现 UIScrollView 的循环滚动，解决方法（http://www.cnblogs.com/ydhliphonedev/archive/2012/05/03/2480256.html）如下：
/*
 
 首先，你需要准备三屏的数据
 
 以手指向右拖动为例，【屏幕】指的是scorllview的显示区域
 
 article1 article2 article3
           【屏幕】
 
 拖动以后成这样：
 
 article1 article2 article3
 【屏幕】
 
 将article3放到第一个去（设定article3的frame），这是屏幕还显示的是article1的内容
 
 article3 article1 article2
 【屏幕】
 
 将屏幕移到中间：使用setContentOffset，禁用动画，这样骗过人眼
 
 article3 article1 article2
          【屏幕】
 
 最后更新指针顺序：
 
 article1 article2 article3
          【屏幕】
 
 
 无缝循环实现了。
 
 by gqzhu
 
 */



@implementation CDZBannerView
-(id)init{
    if(self = [super initWithFrame:CGRectMake(0, 0, 100, 100)]){
        
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self myInit];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame delegate:(id<CDZBannerViewDelegate>)delegate{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDelegate:delegate];
        [self myInit];
    }
    return  self;
}
- (id)initWithFrame:(CGRect)frame delegate:(id<CDZBannerViewDelegate>)delegate imageArray:(NSArray*)array{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = delegate;
        _imageArray = array;
        [self myInit];
        [self updateData];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self myInit];
    }
    return self;
}

-(void)myInit{
    _canCycleScroll = YES;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.scrollsToTop = NO;
    _scrollView.userInteractionEnabled = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;   // 不显示水平滚动条
    _scrollView.showsVerticalScrollIndicator = NO;     // 不显示垂直滚动条
    _scrollView.pagingEnabled = YES;            // 整页翻动
    _scrollView.delegate = self;
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width*3,_scrollView.frame.size.height);  // 总共三屏数据
    _scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width, 0); // 显示第二屏
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:_scrollView];
    
    _pageControl=[[UIPageControl alloc]initWithFrame:CGRectMake(0, self.bounds.size.height - 30, self.bounds.size.width, 20)];
    _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:_pageControl];
    
    _screen0 = [[UIImageView alloc] init];
    _screen0.clipsToBounds = YES;
    [_screen0 setFrame:CGRectMake(0, 0,self.bounds.size.width, self.bounds.size.height)];
    _screen0.tag=0;
    [_scrollView addSubview:_screen0];
    
    _screen1 = [[UIImageView alloc] init];
    _screen1.clipsToBounds = YES;
    [_screen1 setFrame:CGRectMake(self.bounds.size.width, 0,self.bounds.size.width, self.bounds.size.height)];
    _screen1.tag=1;
    [_scrollView addSubview:_screen1];
    
    _screen2 = [[UIImageView alloc] init];
    _screen2.clipsToBounds = YES;
    [_screen2 setFrame:CGRectMake(self.bounds.size.width*2, 0,self.bounds.size.width, self.bounds.size.height)];
    _screen2.tag=2;
    [_scrollView addSubview:_screen2];
}
-(void)setCanClickImage:(BOOL)canClickImage{
    _canClickImage = canClickImage;
    if(_canClickImage){
        if(_tapGestureRecognizer == nil){
            UITapGestureRecognizer *tapGestureRecognize = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureRecognizerForDatailClick:)];
            tapGestureRecognize.delegate = self;
            tapGestureRecognize.numberOfTapsRequired = 1;
            tapGestureRecognize.numberOfTouchesRequired = 1;
            _tapGestureRecognizer = tapGestureRecognize;
        }
        [self addGestureRecognizer:_tapGestureRecognizer];
    }
    else{
        if(_tapGestureRecognizer){
            [self removeGestureRecognizer:_tapGestureRecognizer];
        }
    }
}


-(void)setContentMode:(UIViewContentMode)contentMode{
    _screen0.contentMode = contentMode;
    _screen1.contentMode = contentMode;
    _screen2.contentMode = contentMode;
}
-(UIViewContentMode)contentMode{
    return _screen1.contentMode;
}

-(void)setImageArray:(NSArray *)imageArray{
    [self setImageArray:imageArray initPage:0];
}
-(void)setImageArray:(NSArray *)imageArray initPage:(NSInteger)initPage{
    _imageArray = imageArray;
    _currentPage = initPage;
    
    [self updateData];
}
-(void)setCurrentPage:(NSInteger)currentPage{
    if(_currentPage == currentPage){
        return;
    }
    if(currentPage >= _imageArray.count){
        currentPage = _imageArray.count - 1;
    }
    _currentPage = currentPage;
    [self update3Screens];
    
    _pageControl.currentPage = currentPage;
}
-(void)setPlaceholderImage:(UIImage *)placeholderImage{
    _placeholderImage = placeholderImage;
    
    if(_screen0.image == nil){
        _screen0.image = placeholderImage;
    }
    if(_screen1.image == nil){
        _screen1.image = placeholderImage;
    }
    if(_screen2.image == nil){
        _screen2.image = placeholderImage;
    }
}
-(void)setTimeInterval:(NSTimeInterval)timeInterval{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToNextPage) object:nil];
    _timeInterval = timeInterval;
    if(_timeInterval > 0){
        [self performSelector:@selector(switchToNextPage) withObject:nil afterDelay:_timeInterval];
    }
}

// 根据 _imageArray 更新 _pageControl 的宽度和页数，开启自动循环滚动
- (void)updateData{
    _pageControl.numberOfPages = _imageArray.count;
    _pageControl.currentPage = _currentPage;
    
    [self update3Screens];   // 更新三屏数据
    // 显示第二屏数据
    if(_canCycleScroll){
        [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:NO];
    }
    else{
        if(_currentPage == 0){
            [_scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        }
        else if(_currentPage == _imageArray.count-1){
            [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width*2, 0) animated:NO];
        }
        else{
            [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:NO];
        }
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToNextPage) object:nil];
    if(_imageArray.count < 1){
        _scrollView.userInteractionEnabled = NO;
        _scrollView.scrollEnabled = NO;
        _pageControl.hidden = YES;
    }
    else if(_imageArray.count == 1){
        _scrollView.userInteractionEnabled = YES;
        _scrollView.scrollEnabled = NO;
        _pageControl.hidden = YES;
    }
    else{
        _scrollView.userInteractionEnabled = YES;
        _scrollView.scrollEnabled = YES;
        _pageControl.hidden = NO;
        if(_timeInterval > 0){
            [self performSelector:@selector(switchToNextPage) withObject:nil afterDelay:_timeInterval];
        }
    }
}

// 根据 _currentPage 来更新三屏的数据
-(void)update3Screens{
    if(_imageArray.count <= 0){
        _screen0.image = _placeholderImage;
        _screen1.image = _placeholderImage;
        _screen2.image = _placeholderImage;
    }
    else{
        [self updateScreen0];
        [self updateScreen1];
        [self updateScreen2];
    }
}

-(void)updateScreen0{
    id info;
    if(_currentPage == 0){
        if(_canCycleScroll){
            info = [_imageArray objectAtIndex:_imageArray.count-1];
        }
        else{
            info = [_imageArray objectAtIndex:0];
        }
    }
    else if(_currentPage == _imageArray.count-1){
        if(_canCycleScroll){
            info = [_imageArray objectAtIndex:_currentPage-1];
        }
        else{
            if(_imageArray.count >= 3){
                info = [_imageArray objectAtIndex:_imageArray.count-3];
            }
            else{
                info = [_imageArray firstObject];
            }
        }
    }
    else{
        info = [_imageArray objectAtIndex:_currentPage-1];
    }
    
    [self updateScreen:_screen0 urlOrString:info];
}
-(void)updateScreen1{
    id info;
    if(_canCycleScroll){
        info = [_imageArray objectAtIndex:_currentPage];
    }
    else{
        if(_currentPage == 0){
            if(_imageArray.count >= 2){
                info = [_imageArray objectAtIndex:1];
            }
            else{
                info = [_imageArray firstObject];
            }
        }
        else if(_currentPage == _imageArray.count-1){
            if(_imageArray.count >= 2){
                info = [_imageArray objectAtIndex:_imageArray.count-2];
            }
            else{
                info = [_imageArray lastObject];
            }
        }
        else{
            info = [_imageArray objectAtIndex:_currentPage];
        }
    }
    
    [self updateScreen:_screen1 urlOrString:info];
}
-(void)updateScreen2{
    id info;
    if(_currentPage == 0){
        if(_canCycleScroll){
            if(_imageArray.count >= 2){
                info = [_imageArray objectAtIndex:1];
            }
            else{
                info = [_imageArray firstObject];
            }
        }
        else{
            if(_imageArray.count >= 3){
                info = [_imageArray objectAtIndex:2];
            }
            else{
                info = [_imageArray lastObject];
            }
        }
    }
    else if(_currentPage == _imageArray.count-1){    // 当前页为最后一页，所以第三屏数据应该为第一页数据
        if(_canCycleScroll){
            info = [_imageArray objectAtIndex:0];
        }
        else{
            info = [_imageArray objectAtIndex:_imageArray.count-1];
        }
    }
    else{
        info = [_imageArray objectAtIndex:_currentPage+1];
    }
    [self updateScreen:_screen2 urlOrString:info];
}
-(void)updateScreen:(UIImageView*)screen urlOrString:(id)urlOrString{
    if([urlOrString isKindOfClass:[NSURL class]]){   // 如果是 NSURL 类，则展示网络图片，网络图片未下载下来时，显示 属性placeholderImage图片
        [screen sd_setImageWithURL:urlOrString placeholderImage:_placeholderImage];
    }
    else if([urlOrString isKindOfClass:[NSString class]]){
        NSString* str = urlOrString;
        if ([str hasPrefix:@"http"]){     // 若是 NSString 类，并且 NSString 类是以 "http://" 开头的，将该NSString视为一个有效网络图片链接，如上。
            [screen sd_setImageWithURL:[NSURL URLWithString:str] placeholderImage:_placeholderImage];
        }
        else{                                // 若是 NSString 类，并且 NSString 类是不是以 "http://" 开头的，则将NSString视为一个有效本地图片名字，进行显示
            if(str.length > 0){
                [screen setImage:[UIImage imageNamed:str]];
            }
            else{
                [screen setImage:_placeholderImage];
            }
        }
    }
}

// 跳转到下一页数据
-(void)switchToNextPage{
    // 正在拖动
    if(_scrollView.isDragging == true){
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToNextPage) object:nil];
    
    if(_canCycleScroll || (_currentPage != 0 && _currentPage != _imageArray.count-1)){
        [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width*2, 0) animated:YES];
    }
    else{
        [_scrollView setContentOffset:CGPointMake(MIN(_scrollView.contentOffset.x + _scrollView.frame.size.width, _scrollView.frame.size.width*2), 0) animated:YES];
    }
    
    // 在动画结束后，调用 [self update3Screens]方法，并无动画滚回第二屏
    _currentPage++;
    if(_currentPage >= _imageArray.count){
        if(_canCycleScroll){
            _currentPage = 0;
        }
        else{
            _currentPage = _imageArray.count - 1;
        }
    }
    
    if(_timeInterval > 0){
        [self performSelector:@selector(switchToNextPage) withObject:nil afterDelay:_timeInterval];
    }
}
-(void)switchToLastPage{
    // 正在拖动
    if(_scrollView.isDragging == true){
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToNextPage) object:nil];
    
    if(_canCycleScroll || (_currentPage != 0 && _currentPage != _imageArray.count-1)){
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    else{
        [_scrollView setContentOffset:CGPointMake(MAX(_scrollView.contentOffset.x - _scrollView.frame.size.width, 0), 0) animated:YES];
    }
    
    // 在动画结束后，调用 [self update3Screens]方法，并无动画滚回第二屏
    _currentPage--;
    if(_currentPage < 0){
        if(_canCycleScroll){
            _currentPage = _imageArray.count - 1;
        }
        else{
            _currentPage = 0;
        }
    }
    
    if(_timeInterval > 0){
        [self performSelector:@selector(switchToNextPage) withObject:nil afterDelay:_timeInterval];
    }
}

- (void)singleTapGestureRecognizerForDatailClick:(UIGestureRecognizer*)gestureRecognizer
{
    if (_currentPage > -1 && _currentPage < _imageArray.count) {
        if ([self.delegate respondsToSelector:@selector(bannerView:clickIndex:)]) {
            [self.delegate bannerView:self clickIndex:_currentPage];
        }
    }
}


-(void)setBounds:(CGRect)bounds{
    [super setBounds:bounds];
    _scrollView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    _scrollView.contentSize = CGSizeMake(bounds.size.width*3,bounds.size.height);  // 总共三屏数据
    _screen0.frame = CGRectMake(0,0,bounds.size.width,bounds.size.height);
    _screen1.frame = CGRectMake(bounds.size.width,0,bounds.size.width,bounds.size.height);
    _screen2.frame = CGRectMake(bounds.size.width*2,0,bounds.size.width,bounds.size.height);
    
    [self updateData];
}
-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _scrollView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    _scrollView.contentSize = CGSizeMake(frame.size.width*3,frame.size.height);  // 总共三屏数据
    _screen0.frame = CGRectMake(0,0,frame.size.width,frame.size.height);
    _screen1.frame = CGRectMake(frame.size.width,0,frame.size.width,frame.size.height);
    _screen2.frame = CGRectMake(frame.size.width*2,0,frame.size.width,frame.size.height);
    
    [self updateData];
}


#pragma mark - UIScrollViewDelegate
// 动画停止
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    // 无动画滚回第二屏
    [self update3Screens];
    if(_canCycleScroll){
        [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:NO];
    }
    else{
        if(_currentPage == 0){
            [_scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        }
        else if(_currentPage == _imageArray.count - 1){
            [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width*2, 0) animated:NO];
        }
        else{
            [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:NO];
        }
    }
    
    _pageControl.currentPage = _currentPage;
    
    if([_delegate respondsToSelector:@selector(bannerView:didSwithToPage:)]){
        [_delegate bannerView:self didSwithToPage:self.currentPage];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToNextPage) object:nil];
    if(_timeInterval > 0){
        [self performSelector:@selector(switchToNextPage) withObject:nil afterDelay:_timeInterval];
    }
    if (decelerate) {
        scrollView.userInteractionEnabled = NO;
    }
}

// 手动拖动跳转并跳转动画结束后，会调用此方法
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if(_imageArray.count == 0){
        return;
    }
    
    scrollView.userInteractionEnabled = YES;
    
    if(scrollView.contentOffset.x < scrollView.bounds.size.width/2){  // 在第一屏
        _currentPage--;
    }
    else if(scrollView.contentOffset.x > scrollView.bounds.size.width*1.5){   // 在第三屏
        _currentPage++;
    }
    else{  // 在第二屏
        if(_currentPage == 0){
            _currentPage++;
        }
        else if(_currentPage == _imageArray.count-1){
            _currentPage--;
        }
    }
    
    if(_currentPage < 0){
        if(_canCycleScroll){
            _currentPage = _imageArray.count-1;
        }
        else{
            _currentPage = 0;
        }
    }
    else if(_currentPage >= _imageArray.count){
        if(_canCycleScroll){
            _currentPage = 0;
        }
        else{
            _currentPage = _imageArray.count - 1;
        }
    }
    
    // 无动画滚回第二屏
    [self update3Screens];
    if(_canCycleScroll){
        [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:NO];
    }
    else{
        if(_currentPage == 0){
            [_scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        }
        else if(_currentPage == _imageArray.count - 1){
            [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width*2, 0) animated:NO];
        }
        else{
            [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:NO];
        }
    }
    
    _pageControl.currentPage = _currentPage;
    
    if([_delegate respondsToSelector:@selector(bannerView:didSwithToPage:)]){
        [_delegate bannerView:self didSwithToPage:self.currentPage];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    // 只有在拖动时，才会实时调整 _pageControl.currentPage
    if(_scrollView.isDragging == false){
        return;
    }
    
    // 实时调整 _pageControl.currentPage
    NSInteger page;
    if(scrollView.contentOffset.x < scrollView.bounds.size.width/2){  // 在第一屏
        page = _currentPage-1;
    }
    else if(scrollView.contentOffset.x > scrollView.bounds.size.width*1.5){   // 在第三屏
        page = _currentPage+1;
    }
    else{ // 第二屏
        if(_currentPage == 0){
            if(_canCycleScroll){
                page = _currentPage;
            }
            else{
                page = _currentPage+1;
            }
        }
        else if(_currentPage == _imageArray.count-1){
            if(_canCycleScroll){
                page = _currentPage;
            }
            else{
                page = _currentPage-1;
            }
        }
        else{
            page = _currentPage;
        }
    }
    
    if(page < 0){
        if(_canCycleScroll){
            page = _imageArray.count-1;
        }
        else{
            page = 0;
        }
    }
    else if(page >= _imageArray.count){
        if(_canCycleScroll){
            page = 0;
        }
        else{
            page = _imageArray.count-1;
        }
    }
    _pageControl.currentPage = page;
}//*/

@end