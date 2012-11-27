#import "OBAHasReferencesV2.h"


@interface OBASituationV2 : OBAHasReferencesV2 {

}

@property (nonatomic,strong) NSString * situationId;
@property (nonatomic) long long creationTime;

@property (nonatomic,strong) NSString * summary;
@property (nonatomic,strong) NSString * description;
@property (nonatomic,strong) NSString * advice;

@property (nonatomic,strong) NSArray * consequences;

@property (nonatomic,strong) NSString * severity;
@property (nonatomic,strong) NSString * sensitivity;

@end
