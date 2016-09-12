//
//  ApptentiveUtilities.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#include <stdlib.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>

#define KINDA_EQUALS(a, b) (fabs(a - b) < 0.1)
#define DEG_TO_RAD(angle) ((M_PI * angle) / 180.0)
#define RAD_TO_DEG(radians) (radians * (180.0 / M_PI))


UIViewController *topChildViewController(UIViewController *viewController) {
	if ([viewController isKindOfClass:[UINavigationController class]]) {
		return topChildViewController(((UINavigationController *)viewController).visibleViewController);
	} else if ([viewController isKindOfClass:[UITabBarController class]]) {
		return topChildViewController(((UITabBarController *)viewController).selectedViewController);
	} else if (viewController.presentedViewController) {
		return topChildViewController(viewController.presentedViewController);
	} else {
		return viewController;
	}
}


@implementation ApptentiveUtilities

+ (UIViewController *)rootViewControllerForCurrentWindow {
	UIWindow *window = nil;
	for (UIWindow *tmpWindow in [[UIApplication sharedApplication] windows]) {
		if ([[tmpWindow screen] isEqual:[UIScreen mainScreen]] && [tmpWindow isKeyWindow]) {
			window = tmpWindow;
			break;
		}
	}

	if (window) {
		UIViewController *vc = window.rootViewController;

		return vc.presentedViewController ?: vc;
	} else {
		return nil;
	}
}

+ (UIViewController *)topViewController {
	return topChildViewController([UIApplication sharedApplication].delegate.window.rootViewController);
}

+ (UIImage *)appIcon {
	static UIImage *iconFile = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSArray *iconFiles = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"];
		if (!iconFiles) {
			// Asset Catalog app icons
			iconFiles = [NSBundle mainBundle].infoDictionary[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
		}

		UIImage *maxImage = nil;
		for (NSString *path in iconFiles) {
			UIImage *image = [UIImage imageNamed:path];
			if (maxImage == nil || maxImage.size.width < image.size.width) {
				if (image.size.width >= 512) {
					// Just in case someone stuck iTunesArtwork in there.
					continue;
				}
				maxImage = image;
			}
		}
		iconFile = maxImage;
	});
	return iconFile;
}

+ (NSString *)currentMachineName {
	struct utsname systemInfo;
	uname(&systemInfo);
	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)currentSystemName {
	return [[UIDevice currentDevice] systemName];
}

+ (NSString *)currentSystemVersion {
	return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)currentSystemBuild {
	int mib[2] = {CTL_KERN, KERN_OSVERSION};
	size_t size = 0;

	sysctl(mib, 2, NULL, &size, NULL, 0);

	char *answer = malloc(size);
	int result = sysctl(mib, 2, answer, &size, NULL, 0);

	NSString *results = nil;
	if (result >= 0) {
		results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	}
	free(answer);

	return results;
}

+ (NSString *)stringByEscapingForURLArguments:(NSString *)string {
	CFStringRef result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef) @"%:/?#[]@!$&'()*+,;=", kCFStringEncodingUTF8);

	return CFBridgingRelease(result);
}

+ (NSString *)stringByEscapingForPredicate:(NSString *)string {
	CFStringRef result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, (CFStringRef) @"$#", (CFStringRef)NULL, kCFStringEncodingUTF8);

	return CFBridgingRelease(result);
}

+ (NSString *)randomStringOfLength:(NSUInteger)length {
	static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	NSMutableString *result = [NSMutableString stringWithString:@""];
	for (NSUInteger i = 0; i < length; i++) {
		[result appendFormat:@"%c", [letters characterAtIndex:arc4random() % [letters length]]];
	}
	return result;
}

+ (NSString *)stringRepresentationOfDate:(NSDate *)aDate {
	static NSDateFormatter *dateFormatter = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *enUSLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
		[dateFormatter setLocale:enUSLocale];
		[dateFormatter setCalendar:calendar];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	});

	NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
	NSString *result = nil;
	@synchronized(self) { // to avoid calendars stepping on themselves
		dateFormatter.timeZone = timeZone;
		NSString *dateString = [dateFormatter stringFromDate:aDate];

		NSInteger timeZoneOffset = [timeZone secondsFromGMT];
		NSString *sign = (timeZoneOffset >= 0) ? @"+" : @"-";
		NSInteger hoursOffset = fabs(floor(timeZoneOffset / 60 / 60));
		NSInteger minutesOffset = abs((int)floor(timeZoneOffset / 60) % 60);
		NSString *timeZoneString = [NSString stringWithFormat:@"%@%.2d%.2d", sign, (int)hoursOffset, (int)minutesOffset];

		NSTimeInterval interval = [aDate timeIntervalSince1970];
		double fractionalSeconds = interval - (long)interval;

		// This is all necessary because of rdar://10500679 in which NSDateFormatter won't
		// format fractional seconds past two decimal places. Also, strftime() doesn't seem
		// to have fractional seconds on iOS.
		if (fractionalSeconds == 0.0) {
			result = [NSString stringWithFormat:@"%@ %@", dateString, timeZoneString];
		} else {
			NSString *f = [[NSString alloc] initWithFormat:@"%g", fractionalSeconds];
			NSRange r = [f rangeOfString:@"."];
			if (r.location != NSNotFound) {
				NSString *truncatedFloat = [f substringFromIndex:r.location + r.length];
				result = [NSString stringWithFormat:@"%@.%@ %@", dateString, truncatedFloat, timeZoneString];
			} else {
				// For some reason, we couldn't find the decimal place.
				result = [NSString stringWithFormat:@"%@.%ld %@", dateString, (long)(fractionalSeconds * 1000), timeZoneString];
			}
			f = nil;
		}
	}
	return result;
}

+ (NSComparisonResult)compareVersionString:(NSString *)a toVersionString:(NSString *)b {
	NSArray *leftComponents = [a componentsSeparatedByString:@"."];
	NSArray *rightComponents = [b componentsSeparatedByString:@"."];
	NSUInteger maxComponents = MAX(leftComponents.count, rightComponents.count);

	NSComparisonResult comparisonResult = NSOrderedSame;
	for (NSUInteger i = 0; i < maxComponents; i++) {
		NSInteger leftComponent = 0;
		if (i < leftComponents.count) {
			leftComponent = [leftComponents[i] integerValue];
		}
		NSInteger rightComponent = 0;
		if (i < rightComponents.count) {
			rightComponent = [rightComponents[i] integerValue];
		}
		if (leftComponent == rightComponent) {
			continue;
		} else if (leftComponent > rightComponent) {
			comparisonResult = NSOrderedDescending;
			break;
		} else if (leftComponent < rightComponent) {
			comparisonResult = NSOrderedAscending;
			break;
		}
	}
	return comparisonResult;
}

+ (BOOL)versionString:(NSString *)a isGreaterThanVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ApptentiveUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedDescending);
}

+ (BOOL)versionString:(NSString *)a isLessThanVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ApptentiveUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedAscending);
}

+ (BOOL)versionString:(NSString *)a isEqualToVersionString:(NSString *)b {
	NSComparisonResult comparisonResult = [ApptentiveUtilities compareVersionString:a toVersionString:b];
	return (comparisonResult == NSOrderedSame);
}

+ (NSArray *)availableAppLocalizations {
	static NSArray *localAppLocalizations = nil;
	@synchronized(self) {
		if (localAppLocalizations == nil) {
			NSArray *rawLocalizations = [[NSBundle mainBundle] localizations];
			NSMutableArray *localizations = [[NSMutableArray alloc] init];
			for (NSString *loc in rawLocalizations) {
				NSString *s = [NSLocale canonicalLocaleIdentifierFromString:loc];
				if (![localizations containsObject:s]) {
					[localizations addObject:s];
				}
			}
			localAppLocalizations = [NSArray arrayWithArray:localizations];
		}
	}
	return localAppLocalizations;
}

+ (NSString *)appBundleVersionString {
	return [[NSBundle mainBundle].infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];
}

+ (NSString *)appBundleShortVersionString {
	return [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)appVersionString {
	static NSString *_appVersionString = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_appVersionString = [self appBundleShortVersionString] ?: [self appBundleVersionString];
	});

	return _appVersionString;
}

+ (NSString *)buildNumberString {
	static NSString *_buildNumberString = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_buildNumberString = [self appBundleVersionString];
	});

	return _buildNumberString;
}

+ (BOOL)appStoreReceiptExists {
	return ([NSData dataWithContentsOfURL:[NSBundle mainBundle].appStoreReceiptURL] != nil);
}

+ (NSString *)appStoreReceiptFileName {
	return [[NSBundle mainBundle].appStoreReceiptURL lastPathComponent];
}

+ (NSTimeInterval)maxAgeFromCacheControlHeader:(NSString *)cacheControl {
	if (cacheControl == nil || [cacheControl rangeOfString:@"max-age"].location == NSNotFound) {
		return 0;
	}
	NSTimeInterval maxAge = 0;
	NSScanner *scanner = [[NSScanner alloc] initWithString:[cacheControl lowercaseString]];
	[scanner scanUpToString:@"max-age" intoString:NULL];
	if ([scanner scanString:@"max-age" intoString:NULL] && [scanner scanString:@"=" intoString:NULL]) {
		if (![scanner scanDouble:&maxAge]) {
			maxAge = 0;
		}
	}
	scanner = nil;
	return maxAge;
}

+ (BOOL)dictionary:(NSDictionary *)a isEqualToDictionary:(NSDictionary *)b {
	BOOL isEqual = NO;

	do { // once
		if (a == b) {
			isEqual = YES;
			break;
		}
		if ((a == nil && b != nil) || (a != nil && b == nil)) {
			break;
		}
		if ([a count] != [b count]) {
			break;
		}
		for (NSObject *keyA in a) {
			NSObject *valueB = [b objectForKey:keyA];
			if (valueB == nil) {
				goto done;
			}
			NSObject *valueA = [a objectForKey:keyA];
			if ([valueA isKindOfClass:[NSDictionary class]] && [valueB isKindOfClass:[NSDictionary class]]) {
				BOOL deepEquals = [ApptentiveUtilities dictionary:(NSDictionary *)valueA isEqualToDictionary:(NSDictionary *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if ([valueA isKindOfClass:[NSArray class]] && [valueB isKindOfClass:[NSArray class]]) {
				BOOL deepEquals = [ApptentiveUtilities array:(NSArray *)valueA isEqualToArray:(NSArray *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if (![valueA isEqual:valueB]) {
				goto done;
			}
		}
		isEqual = YES;
	} while (NO);

done:
	return isEqual;
}

+ (BOOL)array:(NSArray *)a isEqualToArray:(NSArray *)b {
	BOOL isEqual = NO;

	do { // once
		if (a == b) {
			isEqual = YES;
			break;
		}
		if ((a == nil && b != nil) || (a != nil && b == nil)) {
			break;
		}
		if ([a count] != [b count]) {
			break;
		}
		NSUInteger index = 0;
		for (NSObject *valueA in a) {
			NSObject *valueB = [b objectAtIndex:index];
			if ([valueA isKindOfClass:[NSDictionary class]] && [valueB isKindOfClass:[NSDictionary class]]) {
				BOOL deepEquals = [ApptentiveUtilities dictionary:(NSDictionary *)valueA isEqualToDictionary:(NSDictionary *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if ([valueA isKindOfClass:[NSArray class]] && [valueB isKindOfClass:[NSArray class]]) {
				BOOL deepEquals = [ApptentiveUtilities array:(NSArray *)valueA isEqualToArray:(NSArray *)valueB];
				if (!deepEquals) {
					goto done;
				}
			} else if (![valueA isEqual:valueB]) {
				goto done;
			}
			index++;
		}
		isEqual = YES;
	} while (NO);

done:
	return isEqual;
}

// Returns a dictionary consisting of:
//
// 1. Any key-value pairs that appear in new but not old
// 2. The keys that appear in old but not new with the values set to [NSNull null]
// 3. Any keys whose values have changed (with the new value)
//
// Nested dictionaries (e.g. custom_data) are sent in their entirety
// if they have changed (in order to match what the server is expecting).
+ (NSDictionary *)diffDictionary:(NSDictionary *) new againstDictionary:(NSDictionary *)old {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	NSArray *newKeys = [new.allKeys sortedArrayUsingSelector:@selector(compare:)];
	NSArray *oldKeys = [old.allKeys sortedArrayUsingSelector:@selector(compare:)];
	NSUInteger i = 0, j = 0;

	while (i < [newKeys count] || j < [oldKeys count]) {
		NSComparisonResult comp = NSOrderedSame;
		NSString *newKey;
		NSString *oldKey;

		if (i < [newKeys count] && j < [oldKeys count]) {
			newKey = newKeys[i];
			oldKey = oldKeys[j];
			comp = [newKey compare:oldKey];
		}
		if (i >= [newKeys count]) {
			oldKey = oldKeys[j];
			newKey = nil;
			comp = NSOrderedDescending;
		} else if (j >= [oldKeys count]) {
			newKey = newKeys[i];
			oldKey = nil;
			comp = NSOrderedAscending;
		}

		if (comp == NSOrderedSame) {
			// Same key, value may have changed
			NSString *key = newKey;
			if (key) {
				id newValue = new[key];
				id oldValue = old[key];

				if ([newValue isEqual:@""] && ![oldValue isEqual:@""]) {
					// Treat new empty strings as null
					result[key] = [NSNull null];
				} else if ([newValue isKindOfClass:[NSArray class]] && [oldValue isKindOfClass:[NSArray class]]) {
					if (![[newValue sortedArrayUsingSelector:@selector(compare:)] isEqualToArray:[oldValue sortedArrayUsingSelector:@selector(compare:)]]) {
						result[key] = newValue;
					}
				} else if (![newValue isEqual:oldValue]) {
					result[key] = newValue;
				}

				i++, j++;
			}
		} else if (comp == NSOrderedAscending) {
			// New key appeared
			result[newKey] = new[newKey];
			i++;
		} else if (comp == NSOrderedDescending) {
			// Old key disappeared
			result[oldKey] = [NSNull null];
			j++;
		}
	}

	return result;
}

+ (BOOL)emailAddressIsValid:(NSString *)emailAddress {
	if (!emailAddress) {
		return NO;
	}

	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[^\\s@]+@[^\\s@]+\\s*$" options:NSRegularExpressionCaseInsensitive error:&error];
	if (!regex) {
		ApptentiveLogError(@"Unable to build email regular expression: %@", error);
		return NO;
	}
	NSUInteger count = [regex numberOfMatchesInString:emailAddress options:NSMatchingAnchored range:NSMakeRange(0, [emailAddress length])];
	BOOL isValid = (count > 0);

	return isValid;
}

@end

extern CGRect ATCGRectOfEvenSize(CGRect inRect) {
	CGRect result = CGRectMake(floor(inRect.origin.x), floor(inRect.origin.y), ceil(inRect.size.width), ceil(inRect.size.height));

	if (fmod(result.size.width, 2.0) != 0.0) {
		result.size.width += 1.0;
	}
	if (fmod(result.size.height, 2.0) != 0.0) {
		result.size.height += 1.0;
	}

	return result;
}

CGSize ATThumbnailSizeOfMaxSize(CGSize imageSize, CGSize maxSize) {
	CGFloat ratio = MIN(maxSize.width / imageSize.width, maxSize.height / imageSize.height);
	if (ratio < 1.0) {
		return CGSizeMake(floor(ratio * imageSize.width), floor(ratio * imageSize.height));
	} else {
		return imageSize;
	}
}

CGRect ATThumbnailCropRectForThumbnailSize(CGSize imageSize, CGSize thumbnailSize) {
	CGFloat cropRatio = thumbnailSize.width / thumbnailSize.height;
	CGFloat sizeRatio = imageSize.width / imageSize.height;

	if (cropRatio < sizeRatio) {
		// Shrink width. eg. 100:100 < 1600:1200
		CGFloat croppedWidth = imageSize.width * (1.0 / sizeRatio);
		CGFloat originX = floor((imageSize.width - croppedWidth) / 2.0);

		return CGRectMake(originX, 0, croppedWidth, imageSize.height);
	} else if (cropRatio > sizeRatio) {
		// Shrink height. eg. 100:100 > 1200:1600
		CGFloat croppedHeight = floor(imageSize.height * sizeRatio);
		CGFloat originY = floor((imageSize.height - croppedHeight) / 2.0);

		return CGRectMake(0, originY, imageSize.width, croppedHeight);
	} else {
		return CGRectMake(0, 0, imageSize.width, imageSize.height);
	}
}
