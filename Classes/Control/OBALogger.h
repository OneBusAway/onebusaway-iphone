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

//#import <Foundation/Foundation.h>

typedef enum {
	OBALoggerLevelDebug,
	OBALoggerLevelInfo,
	OBALoggerLevelWarning,
	OBALoggerLevelSevere
}
OBALoggerLevel;

#ifdef NDEBUG

#define OBALog(level,s,...)
#define OBALogWithError(level,errorObject,s,...)

#else

#define OBALog(level,s,...) [OBALogger logWithLevel:level pointer:self file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ message:[NSString stringWithFormat:(s), ##__VA_ARGS__]]
#define OBALogWithError(level,errorObject,s,...) [OBALogger logWithLevel:level pointer:self file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ message:[NSString stringWithFormat:(s), ##__VA_ARGS__] error:errorObject]

#endif

#define OBALogDebug(s,...) OBALog(OBALoggerLevelDebug,s, ##__VA_ARGS__)
#define OBALogDebugWithError(error,s,...) OBALogWithError(OBALoggerLevelDebug,error,s, ##__VA_ARGS__)

#define OBALogInfo(s,...) OBALog(OBALoggerLevelInfo,s, ##__VA_ARGS__)
#define OBALogInfoWithError(error,s,...) OBALogWithError(OBALoggerLevelInfo,error, s, ##__VA_ARGS__)

#define OBALogWarning(s,...) OBALog(OBALoggerLevelWarning,s, ##__VA_ARGS__)
#define OBALogWarningWithError(error,s,...) OBALogWithError(OBALoggerLevelWarning,error,s, ##__VA_ARGS__)

#define OBALogSevere(s,...) OBALog(OBALoggerLevelSevere,s, ##__VA_ARGS__)
#define OBALogSevereWithError(error,s,...) OBALogWithError(OBALoggerLevelSevere,error,s, ##__VA_ARGS__)

@interface OBALogger : NSObject {

}

+ (void) logWithLevel:(OBALoggerLevel)level pointer:(id)pointer file:(NSString*)file line:(NSInteger)line message:(NSString*)message;
+ (void) logWithLevel:(OBALoggerLevel)level pointer:(id)pointer file:(NSString*)file line:(NSInteger)line message:(NSString*)message error:(NSError*)error;
+ (NSString*) logLevelAsString:(OBALoggerLevel)level;

@end
