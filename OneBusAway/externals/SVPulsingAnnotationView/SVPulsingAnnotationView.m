//
//  SVPulsingAnnotationView.m
//
//  Created by Sam Vermette on 01.03.13.
//  https://github.com/samvermette/SVPulsingAnnotationView
//

#import "SVPulsingAnnotationView.h"
#import <QuartzCore/QuartzCore.h>

@interface SVPulsingAnnotationView ()

@property (nonatomic, strong) CALayer *shinyDotLayer;
@property (nonatomic, strong) CALayer *glowingHaloLayer;
@property (nonatomic, strong, readwrite) UIImageView *headingImageView;

@property (nonatomic, strong) CALayer *outerDotLayer;
@property (nonatomic, strong) CALayer *colorDotLayer;
@property (nonatomic, strong) CALayer *colorHaloLayer;

@property (nonatomic, strong) CAAnimationGroup *pulseAnimationGroup;
@end

@implementation SVPulsingAnnotationView

@synthesize annotation = _annotation;
@synthesize image = _image;

+ (NSMutableDictionary*)cachedRingImages {
    static NSMutableDictionary *cachedRingLayers = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{ cachedRingLayers = [NSMutableDictionary new]; });
    return cachedRingLayers;
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier size:(CGSize)size {
    if(self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.calloutOffset = CGPointMake(0, 4);
        self.bounds = CGRectMake(0, 0, size.width, size.height);
        self.pulseScaleFactor = 5.3f;
        self.pulseAnimationDuration = 1.5;
        self.outerPulseAnimationDuration = 3;
        self.delayBetweenPulseCycles = 0;
        self.annotationColor = [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1];
        self.outerColor = [UIColor whiteColor];
        self.outerDotAlpha = 1;

        self.willMoveToSuperviewAnimationBlock = ^(SVPulsingAnnotationView *annotationView, UIView *superview) {
            CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

            bounceAnimation.values = @[@0.05, @1.25, @0.8, @1.1, @0.9, @1.0];
            bounceAnimation.duration = 0.3;
            bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut, easeInOut, easeInOut];
            [annotationView.layer addAnimation:bounceAnimation forKey:@"popIn"];
        };
    }
    return self;
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    return [self initWithAnnotation:annotation reuseIdentifier:reuseIdentifier size:CGSizeMake(22, 22)];
}

- (void)rebuildLayers {
    [_outerDotLayer removeFromSuperlayer];
    _outerDotLayer = nil;
    
    [_colorDotLayer removeFromSuperlayer];
    _colorDotLayer = nil;
    
    [_colorHaloLayer removeFromSuperlayer];
    _colorHaloLayer = nil;
    
    _pulseAnimationGroup = nil;
    
    if (!self.image) {
        [_imageView removeFromSuperview];
        _imageView = nil;
    }
    
    if (self.headingImage) {
        [self addSubview:self.headingImageView];
        [self sendSubviewToBack:self.headingImageView];
        self.headingImageView.frame = CGRectMake(-40, -40, 120, 120);
    }
    else {
        [self.headingImageView removeFromSuperview];
    }

    [self.layer addSublayer:self.colorHaloLayer];
    [self.layer addSublayer:self.outerDotLayer];
    [self.layer addSublayer:self.colorDotLayer];

    if (self.image) {
        [self addSubview:self.imageView];
        [self bringSubviewToFront:self.imageView];
    }
}

- (void)willMoveToSuperview:(UIView *)superview {
    if (superview) {
        [self rebuildLayers];
    }
    
    if (self.willMoveToSuperviewAnimationBlock) {
        self.willMoveToSuperviewAnimationBlock(self, superview);
    }
}

- (void)popIn {
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    bounceAnimation.values = @[@0.05, @1.25, @0.8, @1.1, @0.9, @1.0];
    bounceAnimation.duration = 0.3;
    bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut, easeInOut, easeInOut];
    [self.layer addAnimation:bounceAnimation forKey:@"popIn"];
}

#pragma mark - Setters

- (void)setAnnotationColor:(UIColor *)annotationColor {
    if(CGColorGetNumberOfComponents(annotationColor.CGColor) == 2) {
        CGFloat white = CGColorGetComponents(annotationColor.CGColor)[0];
        CGFloat alpha = CGColorGetComponents(annotationColor.CGColor)[1];
        annotationColor = [UIColor colorWithRed:white green:white blue:white alpha:alpha];
    }
    
    _annotationColor = annotationColor;
    _imageView.tintColor = annotationColor;
    _headingImageView.tintColor = annotationColor;
    
    if(self.superview)
        [self rebuildLayers];
}

- (void)setDelayBetweenPulseCycles:(NSTimeInterval)delayBetweenPulseCycles {
    _delayBetweenPulseCycles = delayBetweenPulseCycles;
    
    if(self.superview)
        [self rebuildLayers];
}

- (void)setPulseAnimationDuration:(NSTimeInterval)pulseAnimationDuration {
    _pulseAnimationDuration = pulseAnimationDuration;
    
    if(self.superview)
        [self rebuildLayers];
}

- (void)setImage:(UIImage *)image {
    _image = image;

    self.imageView.image = _image;
    
    if (self.superview) {
        [self rebuildLayers];
    }
}

- (void)setHeadingImage:(UIImage *)image {
    _headingImage = image;

    self.headingImageView.image = _headingImage;

    if (self.superview) {
        [self rebuildLayers];
    }
    
//    CGFloat imageWidth = ceil(image.size.width);
//    CGFloat imageHeight = ceil(image.size.height);
//
//    self.headingImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    self.headingImageView.frame = CGRectMake(floor((self.bounds.size.width - imageWidth) * 0.5),
//                                             floor((self.bounds.size.height - imageHeight) * 0.5),
//                                             imageWidth,
//                                             imageHeight);
//    self.headingImageView.tintColor = self.annotationColor;
}

#pragma mark - Getters

- (UIColor *)pulseColor {
    if(!_pulseColor)
        return self.annotationColor;
    return _pulseColor;
}

- (CAAnimationGroup*)pulseAnimationGroup {
    if(!_pulseAnimationGroup) {
        CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        
        _pulseAnimationGroup = [CAAnimationGroup animation];
        _pulseAnimationGroup.duration = self.outerPulseAnimationDuration + self.delayBetweenPulseCycles;
        _pulseAnimationGroup.repeatCount = INFINITY;
        _pulseAnimationGroup.removedOnCompletion = NO;
        _pulseAnimationGroup.timingFunction = defaultCurve;
        
        NSMutableArray *animations = [NSMutableArray new];
        
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
        pulseAnimation.fromValue = @0.0;
        pulseAnimation.toValue = @1.0;
        pulseAnimation.duration = self.outerPulseAnimationDuration;
        [animations addObject:pulseAnimation];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        animation.duration = self.outerPulseAnimationDuration;
        animation.values = @[@0.45, @0.45, @0];
        animation.keyTimes = @[@0, @0.2, @1];
        animation.removedOnCompletion = NO;
        [animations addObject:animation];
        
        _pulseAnimationGroup.animations = animations;
    }
    return _pulseAnimationGroup;
}

#pragma mark - Graphics

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view {
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);

    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);

    CGPoint position = view.layer.position;

    position.x -= oldPoint.x;
    position.x += newPoint.x;

    position.y -= oldPoint.y;
    position.y += newPoint.y;

    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

- (UIImageView *)imageView {
    if(!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, 10, 10)];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (UIImageView *)headingImageView {
    if (!_headingImageView) {
        _headingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
        _headingImageView.contentMode = UIViewContentModeCenter;
    }
    
    return _headingImageView;
}

- (CALayer*)outerDotLayer {
    if(!_outerDotLayer) {
        _outerDotLayer = [CALayer layer];
        _outerDotLayer.bounds = self.bounds;
        _outerDotLayer.contents = (id)[self circleImageWithColor:self.outerColor height:self.bounds.size.height].CGImage;
        _outerDotLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _outerDotLayer.contentsGravity = kCAGravityCenter;
        _outerDotLayer.contentsScale = [UIScreen mainScreen].scale;
        _outerDotLayer.shadowColor = [UIColor blackColor].CGColor;
        _outerDotLayer.shadowOffset = CGSizeMake(0, 2);
        _outerDotLayer.shadowRadius = 3;
        _outerDotLayer.shadowOpacity = 0.3f;
        _outerDotLayer.opacity = self.outerDotAlpha;
    }
    return _outerDotLayer;
}

- (CALayer*)colorDotLayer {
    if(!_colorDotLayer) {
        _colorDotLayer = [CALayer layer];
        CGFloat width = self.bounds.size.width-6;
        _colorDotLayer.bounds = CGRectMake(0, 0, width, width);
        _colorDotLayer.allowsGroupOpacity = YES;
        _colorDotLayer.backgroundColor = self.annotationColor.CGColor;
        _colorDotLayer.cornerRadius = width/2;
        _colorDotLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            if(self.delayBetweenPulseCycles != INFINITY) {
                CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];

                CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
                animationGroup.duration = self.pulseAnimationDuration;
                animationGroup.repeatCount = INFINITY;
                animationGroup.removedOnCompletion = NO;
                animationGroup.autoreverses = YES;
                animationGroup.timingFunction = defaultCurve;
                animationGroup.speed = 1;
                animationGroup.fillMode = kCAFillModeBoth;

                CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
                pulseAnimation.fromValue = @0.8;
                pulseAnimation.toValue = @1;
                pulseAnimation.duration = self.pulseAnimationDuration;
                
                CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                opacityAnimation.fromValue = @0.8;
                opacityAnimation.toValue = @1;
                opacityAnimation.duration = self.pulseAnimationDuration;
                
                animationGroup.animations = @[pulseAnimation, opacityAnimation];

                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self->_colorDotLayer addAnimation:animationGroup forKey:@"pulse"];
                });
            }
        });

    }
    return _colorDotLayer;
}

- (CALayer *)colorHaloLayer {
    if(!_colorHaloLayer) {
        _colorHaloLayer = [CALayer layer];
        CGFloat width = self.bounds.size.width*self.pulseScaleFactor;
        _colorHaloLayer.bounds = CGRectMake(0, 0, width, width);
        _colorHaloLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _colorHaloLayer.contentsScale = [UIScreen mainScreen].scale;
        _colorHaloLayer.backgroundColor = self.pulseColor.CGColor;
        _colorHaloLayer.cornerRadius = width/2;
        _colorHaloLayer.opacity = 0;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if(self.delayBetweenPulseCycles != INFINITY) {
                CAAnimationGroup *animationGroup = self.pulseAnimationGroup;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self->_colorHaloLayer addAnimation:animationGroup forKey:@"pulse"];
                });
            }
        });
    }
    return _colorHaloLayer;
}

- (UIImage*)circleImageWithColor:(UIColor*)color height:(CGFloat)height {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, height), NO, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UIBezierPath* fillPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, height, height)];
    [color setFill];
    [fillPath fill];
    
    UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRelease(colorSpace);
    
    return dotImage;
}

@end
