#import "OBAHasReferencesV2.h"


@interface OBAEntryWithReferencesV2 : OBAHasReferencesV2 {
    id _entry;
}

@property (nonatomic,strong) id entry;

@end
