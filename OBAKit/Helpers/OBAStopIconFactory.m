/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBAStopIconFactory.h>
#import <OBAKit/OBARouteV2.h>
#import <OBAKit/OBACanvasView.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBAMacros.h>

// For the simple getIconForStop call, here are the default dimensions
CGFloat const OBADefaultAnnotationSize = 54.f;

@implementation OBAStopIconFactory

// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

// The construction is a large transparent image that contains the icon in its
// center, with room on all sides for optional direction chevrons. This way, the
// the center of the icon image remains consistently placed on the map regardless
// of where the direction chevron is placed.
//
// The icon is the rounded rect describing the stop, with the glyph of the
// transport type and the label text for STOP.

//    +-----------------+ ---
//    |    <chevron>    |  .
//    |   +---------+   |  .
//    |   |  icon   |   |  .
//    |   | +-----+ |   |  .
//    |<c>| |glyph| |<c>|  Overall View
//    |   | | --- | |   |  .
//    |   | | txt | |   |  .
//    |   | +-----+ |   |  .
//    |   +---------+   |  .
//    |    <chevron>    |  .
//    +-----------------+ ---

// These constants define the geometry of the stop icon, the glyph and text
// placement, and the size and position of the direction chevron.

#define IconCornerRadiusPercentage  0.1f    // Radius of icon corner, relative to overall width
#define StrokeWidthPercentage       0.038f  // Width of stroke for all borders, relative to overall width
#define IconInsetPercentage         0.21f   // Amount of padding to inset the icon (leaving room for chevron), relative to overall size
#define GlyphAreaPercentage         0.7f    // Amount of icon height reserved for glyph
#define TextAreaPercentage          (1.0f - GlyphAreaPercentage) // Amount of icon height reserved for text
#define GlyphHeightPercentage       0.6f    // Height of glyph, relative to icon height
#define GlyphInsetRelativeToStroke  1.5f    // Padding around glyph, relative to stroke width
#define ChevronWidthPercentage      0.25f   // Width of chevron, relative to overall size (assuming N chevron)
#define ChevronHeightPercentage     0.15f   // Height of chevron, relative to overall size (assuming N chevron)

// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

static NSDictionary *rotationAngles = nil;
static UIColor *iconBackgroundColor = nil;
static UIColor *chevronFillColor = nil;
static UIColor *textColor = nil;
static NSString *stopLabelFaceName = nil;
static NSString *stopLabelText = nil;
static NSCache *iconCache = nil;

+ (UIImage *)getIconForStop:(OBAStopV2 *)stop strokeColor:(nonnull UIColor *)strokeColor {
    return [self getIconForStop:stop withSize:CGSizeMake(OBADefaultAnnotationSize, OBADefaultAnnotationSize) strokeColor:strokeColor];
}

+ (UIImage *)getIconForStop:(OBAStopV2 *)stop withSize:(CGSize)size strokeColor:(UIColor*)strokeColor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iconCache = [[NSCache alloc] init];

        stopLabelText = OBALocalized(@"msg_stop_mayus",);

        // Use the system font.
        stopLabelFaceName = [OBATheme titleFont].familyName;

        // Color selections
        // TODO: Consider OBATheme here?
        iconBackgroundColor = [UIColor whiteColor];
        chevronFillColor = [UIColor redColor];
        textColor = [UIColor whiteColor];

        // Rotation transform angles in Radians, the official Angular Unit of
        // Core Graphics since the beginning of time.
        rotationAngles = @{@"N"    : @(0.f),
                           @"NE"   : @(0.7853f),
                           @"E"    : @(1.5708f),
                           @"SE"   : @(2.3562f),
                           @"S"    : @(3.1416f),
                           @"SW"   : @(3.9270f),
                           @"W"    : @(4.7124f),
                           @"NW"   : @(5.4978f)};
    });

    // First, let's compose the cache key out of the name and orientation, then
    // see if we've already got one that matches.
    NSString *routeIconType = [self imageNameForRouteType:stop.firstAvailableRouteTypeForStop];


    NSString *cachedImageKey = [NSString stringWithFormat:@"%@:%@(%fx%f)-%@",
                                routeIconType,
                                stop.direction ?: @"",
                                size.width, size.height,
                                [self colorToString:strokeColor]
                                ];

    UIImage *image = [iconCache objectForKey:cachedImageKey];

    if (image) {
        return image;
    }

    // First time for one of these, so we need to build it up.
    UIView *view = [self createCompositeViewForStop:stop withSize:size strokeColor:strokeColor];

    // Render the composited UIView into a UIImage
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.0f);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Save it to the cache for next time.
    [iconCache setObject:image forKey:cachedImageKey];

    return image;
}

+ (NSString*)colorToString:(UIColor*)color {
    CGFloat *components = (CGFloat*)CGColorGetComponents(color.CGColor);

    CGFloat R = components[0] * 255.f;
    CGFloat G = components[1] * 255.f;
    CGFloat B = components[2] * 255.f;

    NSString *str = [NSString stringWithFormat:@"(%.0f,%.0f,%.0f)", R, G, B];
    return str;
}

#pragma mark - Private

+ (UIView *)createCompositeViewForStop:(OBAStopV2 *)stop withSize:(CGSize)size strokeColor:(UIColor*)strokeColor {
    // Some basic geometry using the constants defined at the top of the file
    CGFloat cornerRadius = size.width * IconCornerRadiusPercentage;
    CGFloat strokeWidth = size.width * StrokeWidthPercentage;

    UIColor *textBackgroundColor = strokeColor;

    CGRect mainViewRect = CGRectMake(0, 0, size.width, size.height);
    CGRect iconRect = CGRectInset(mainViewRect, (size.width * IconInsetPercentage), (size.height * IconInsetPercentage));
    CGRect textRect = CGRectMake(iconRect.origin.x,
                                 iconRect.origin.y + (iconRect.size.height * GlyphAreaPercentage),
                                 iconRect.size.width,
                                 iconRect.size.height * TextAreaPercentage);

    CGRect chevronRect = CGRectMake(mainViewRect.origin.x + ((mainViewRect.size.width - (mainViewRect.size.width * ChevronWidthPercentage)) / 2), 0,
                                    mainViewRect.size.width * ChevronWidthPercentage, mainViewRect.size.height * ChevronHeightPercentage);

    // Glyph overall size is governed by the height of the glyph area
    CGFloat glyphHeight = iconRect.size.height * GlyphHeightPercentage;
    CGFloat glyphWidth = iconRect.size.width - (strokeWidth * 2);
    CGFloat glyphX = (iconRect.origin.x + (iconRect.size.width / 2)) - (glyphWidth / 2);
    CGFloat glyphY = iconRect.origin.y + (strokeWidth * GlyphInsetRelativeToStroke);
    CGRect glyphRect = CGRectMake(glyphX, glyphY, glyphWidth, glyphHeight);

    // The first thing to do is create a view that will hold everything
    UIView *view = [[UIView alloc] initWithFrame:mainViewRect];
    view.backgroundColor = [UIColor clearColor];

    // Add rounded rect for the icon frame
    OBACanvasView *rectView = [[OBACanvasView alloc] initWithFrame:iconRect drawRectBlock:^void (CGRect rect) {
        // Inset the rectangle by half of the stroke width so that the stroke fits
        CGRect strokeRect = CGRectInset(rect, strokeWidth / 2, strokeWidth / 2);

        UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:cornerRadius];

        [iconBackgroundColor setFill];
        [rectanglePath fill];
        [strokeColor setStroke];
        rectanglePath.lineWidth = strokeWidth;
        [rectanglePath stroke];
    }];
    [view addSubview:rectView];

    // Add the text panel at the bottom of the icon
    OBACanvasView *textView = [[OBACanvasView alloc] initWithFrame:textRect drawRectBlock:^void (CGRect rect) {
        // Inset the rectangle by half of the stroke width so that the stroke fits
        CGRect blockRect = rect;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
        // Hate this pragma, but Cocoa doesn't define 'full' or 'empty' values in its
        // bitfield enums, which causes a warning for a value that's out of range
        // even when it's being used exactly as intended.
        UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect:blockRect
                                                            byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                                                  cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
#pragma clang diagnostic pop

        [textBackgroundColor setFill];
        [rectanglePath fill];

        CGRect labelRect = CGRectInset(blockRect, strokeWidth * 2, strokeWidth * 2);
        CGFloat fontSize = [self findFontSizeForFrame:labelRect forFace:stopLabelFaceName withText:stopLabelText];

        NSDictionary *attributes = @{ NSFontAttributeName:[UIFont fontWithName:stopLabelFaceName size:fontSize],
                                      NSForegroundColorAttributeName:textColor,
                                      NSParagraphStyleAttributeName:[NSParagraphStyle new]};
        CGSize labelSize = [stopLabelText sizeWithAttributes:attributes];
        CGRect textDrawingRect = CGRectMake(
                                            blockRect.origin.x + floorf((float)(blockRect.size.width - labelSize.width) / 2.f),
                                            blockRect.origin.y + floorf((float)(blockRect.size.height - labelSize.height) / 2.f),
                                            labelSize.width,
                                            labelSize.height);

        [stopLabelText drawInRect:textDrawingRect withAttributes:attributes];
    }];
    [view addSubview:textView];

    // Add glyph for the specific route type
    UIImageView *glyphView = [[UIImageView alloc] initWithFrame:glyphRect];
    glyphView.contentMode = UIViewContentModeScaleAspectFit;
    NSString *transportGlyphName = [NSString stringWithFormat:@"%@Transport", [self imageNameForRouteType:stop.firstAvailableRouteTypeForStop]];
    glyphView.image = [UIImage imageNamed:transportGlyphName];
    [view addSubview:glyphView];

    // If a direction is expressed, draw the chevron view and position it
    if (stop.direction) {
        CGFloat xOffsetForInflation = 0.f;

        // If the direction is a diagonal, slightly inflate the rect so the
        // chevron doesn't touch the icon corner.
        if (stop.direction.length == 2) {
            mainViewRect = CGRectInset(mainViewRect, - (CGRectGetWidth(mainViewRect) * 0.05f), - (CGRectGetHeight(mainViewRect) * 0.05f));
            xOffsetForInflation = (mainViewRect.size.width * 0.05f);
        }

        // Note that the chevronRect is the actual dimension of the chevron
        // so that's what we draw into, even though the view is the
        // mainViewRect, which needs to match the full icon size for rotation.
        OBACanvasView *chevronView = [[OBACanvasView alloc] initWithFrame:mainViewRect drawRectBlock:^void (CGRect rect) {
            CGRect triangleRect = CGRectInset(chevronRect, strokeWidth, strokeWidth);
            triangleRect = CGRectMake(triangleRect.origin.x + xOffsetForInflation,
                                      triangleRect.origin.y,
                                      triangleRect.size.width,
                                      triangleRect.size.height);

            UIBezierPath* trianglePath = [UIBezierPath bezierPath];
            [trianglePath moveToPoint:CGPointMake(triangleRect.origin.x + (triangleRect.size.width / 2), triangleRect.origin.y)];
            [trianglePath addLineToPoint:CGPointMake(triangleRect.origin.x, triangleRect.origin.y + triangleRect.size.height)];
            [trianglePath addLineToPoint:CGPointMake(triangleRect.origin.x + triangleRect.size.width, triangleRect.origin.y + triangleRect.size.height)];
            [trianglePath closePath];

            [strokeColor setStroke];
            trianglePath.lineWidth = strokeWidth * 2.f;
            [trianglePath stroke];
            [chevronFillColor setFill];
            [trianglePath fill];
        }];

        CGAffineTransform xform = CGAffineTransformMakeRotation([rotationAngles[stop.direction] floatValue]);
        [chevronView setTransform:xform];

        [view addSubview:chevronView];
    }

    return view;
}

+ (UIImage*)imageForRouteType:(OBARouteType)routeType {
    NSString *imageName = [NSString stringWithFormat:@"%@Transport", [self imageNameForRouteType:routeType]];
    return [UIImage imageNamed:imageName];
}

+ (NSString *)imageNameForRouteType:(OBARouteType)routeType {
    // These names, added to "Transport" must match resource names, e.g. "busTransport"
    switch (routeType) {
        case OBARouteTypeMetro:
            return @"lightRail";
        case OBARouteTypeFerry:
            return @"ferry";
        case OBARouteTypeTrain:
            return @"train";
        case OBARouteTypeLightRail:
            return @"lightRail";
        default:
            return @"bus";
    }
}

+ (CGFloat) findFontSizeForFrame:(CGRect)frame forFace:(NSString *)faceName withText:(NSString *)text {
    // Brute-force method to find the largest font size that will fit, chosen by
    // bisecting the range and evaluating the width at every interval.
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    CGFloat largestFontSize = 96;
    CGFloat smallestFontSize = 6;
    CGFloat currentFontSize = 24;
    CGFloat lastFontSize = 0;

    while (currentFontSize != lastFontSize) {
        lastFontSize = currentFontSize;
        currentFontSize = smallestFontSize + (largestFontSize - smallestFontSize) / 2.f;
        CGFloat width = [label.text sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:faceName size:currentFontSize]}].width;

        if (width > frame.size.width) {
            // Too big
            largestFontSize = currentFontSize;
        }
        else if (width < frame.size.width) {
            // Too small
            smallestFontSize = currentFontSize;
        }
        else {
            break;
        }
    }

    return currentFontSize;
}

@end
