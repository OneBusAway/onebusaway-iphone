#import "OBAHasReferencesV2.h"


@interface OBASituationV2 : OBAHasReferencesV2 {

}

@property (nonatomic,retain) NSString * situationId;
@property (nonatomic) long long creationTime;

@property (nonatomic,retain) NSString * summary;
@property (nonatomic,retain) NSString * description;
@property (nonatomic,retain) NSString * advice;

@property (nonatomic,retain) NSArray * consequences;

@property (nonatomic,retain) NSString * severity;
@property (nonatomic,retain) NSString * sensitivity;

@end
