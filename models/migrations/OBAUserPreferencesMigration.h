#import "OBAModelDAO.h"


@interface OBAUserPreferencesMigration : NSObject {

}

- (void) migrateCoreDataPath:(NSString*)path toDao:(OBAModelDAO*)dao;

@end
