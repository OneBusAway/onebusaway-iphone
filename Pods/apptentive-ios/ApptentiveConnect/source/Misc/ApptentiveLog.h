//
//  ApptentiveLog.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/29/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveLogger.h"

#ifndef APPTENTIVE_LOGGING_ENABLED
#define APPTENTIVE_LOGGING_ENABLED 1
#endif

#ifndef APPTENTIVE_LOGGING_LEVEL_DEBUG
#if APPTENTIVE_DEBUG
#define APPTENTIVE_LOGGING_LEVEL_DEBUG 1
#else
#define APPTENTIVE_LOGGING_LEVEL_DEBUG 0
#endif
#endif

#ifndef APPTENTIVE_LOGGING_LEVEL_INFO
#define APPTENTIVE_LOGGING_LEVEL_INFO 1
#endif

#ifndef APPTENTIVE_LOGGING_LEVEL_WARNING
#define APPTENTIVE_LOGGING_LEVEL_WARNING 1
#endif

#ifndef APPTENTIVE_LOGGING_LEVEL_ERROR
#define APPTENTIVE_LOGGING_LEVEL_ERROR 1
#endif

#if !(defined(APPTENTIVE_LOGGING_ENABLED) && APPTENTIVE_LOGGING_ENABLED)
#undef APPTENTIVE_LOGGING_LEVEL_DEBUG
#undef APPTENTIVE_LOGGING_LEVEL_INFO
#undef APPTENTIVE_LOGGING_LEVEL_WARNING
#undef APPTENTIVE_LOGGING_LEVEL_ERROR
#endif

#define APPTENTIVE_LOG_FORMAT(format_val, level, ...) ([ApptentiveLogger logWithLevel:level file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ format:(format_val), ##__VA_ARGS__])

#if APPTENTIVE_LOGGING_LEVEL_DEBUG
#define ApptentiveLogDebug(s, ...) APPTENTIVE_LOG_FORMAT(s, @"debug", ##__VA_ARGS__)
#else
#define ApptentiveLogDebug(s, ...)
#endif

#if APPTENTIVE_LOGGING_LEVEL_INFO
#define ApptentiveLogInfo(s, ...) APPTENTIVE_LOG_FORMAT(s, @"info", ##__VA_ARGS__)
#else
#define ApptentiveLogInfo(s, ...)
#endif

#if APPTENTIVE_LOGGING_LEVEL_WARNING
#define ApptentiveLogWarning(s, ...) APPTENTIVE_LOG_FORMAT(s, @"warning", ##__VA_ARGS__)
#else
#define ApptentiveLogWarning(s, ...)
#endif

#if APPTENTIVE_LOGGING_LEVEL_ERROR
#define ApptentiveLogError(s, ...) APPTENTIVE_LOG_FORMAT(s, @"error", ##__VA_ARGS__)
#else
#define ApptentiveLogError(s, ...)
#endif
