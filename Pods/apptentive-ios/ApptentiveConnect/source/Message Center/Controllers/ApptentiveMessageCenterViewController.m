//
//  ApptentiveMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveMessageCenterGreetingView.h"
#import "ApptentiveMessageCenterStatusView.h"
#import "ApptentiveMessageCenterInputView.h"
#import "ApptentiveMessageCenterProfileView.h"
#import "ApptentiveMessageCenterMessageCell.h"
#import "ApptentiveMessageCenterReplyCell.h"
#import "ApptentiveMessageCenterContextMessageCell.h"
#import "ApptentiveCompoundMessageCell.h"
#import "ApptentiveMessageCenterInteraction.h"
#import "Apptentive_Private.h"
#import "ApptentiveNetworkImageView.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveNetworkImageIconView.h"
#import "ApptentiveReachability.h"
#import "ApptentiveProgressNavigationBar.h"
#import "ApptentiveAboutViewController.h"
#import "ApptentiveAttachButton.h"
#import "ApptentiveAttachmentController.h"
#import "ApptentiveIndexedCollectionView.h"
#import "ApptentiveAttachmentCell.h"
#import <MobileCoreServices/UTCoreTypes.h>

#define HEADER_LABEL_HEIGHT 64.0
#define TEXT_VIEW_HORIZONTAL_INSET 12.0
#define TEXT_VIEW_VERTICAL_INSET 10.0
#define ATTACHMENT_MARGIN CGSizeMake(16.0, 15.0)

#define FOOTER_ANIMATION_DURATION 0.10

// The following need to match the storyboard for sizing cells on iOS 7
#define MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN 30.0
#define REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN 74.0
#define MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN 29.0
#define REPLY_LABEL_TOTAL_VERTICAL_MARGIN 46.0
#define REPLY_CELL_MINIMUM_HEIGHT 66.0
#define STATUS_LABEL_HEIGHT 14.0
#define STATUS_LABEL_MARGIN 6.0

NSString *const ATInteractionMessageCenterEventLabelLaunch = @"launch";
NSString *const ATInteractionMessageCenterEventLabelClose = @"close";
NSString *const ATInteractionMessageCenterEventLabelAttach = @"attach";

NSString *const ATInteractionMessageCenterEventLabelComposeOpen = @"compose_open";
NSString *const ATInteractionMessageCenterEventLabelComposeClose = @"compose_close";
NSString *const ATInteractionMessageCenterEventLabelKeyboardOpen = @"keyboard_open";
NSString *const ATInteractionMessageCenterEventLabelKeyboardClose = @"keyboard_close";

NSString *const ATInteractionMessageCenterEventLabelGreetingMessage = @"greeting_message";
NSString *const ATInteractionMessageCenterEventLabelStatus = @"status";
NSString *const ATInteractionMessageCenterEventLabelHTTPError = @"message_http_error";
NSString *const ATInteractionMessageCenterEventLabelNetworkError = @"message_network_error";

NSString *const ATInteractionMessageCenterEventLabelProfileOpen = @"profile_open";
NSString *const ATInteractionMessageCenterEventLabelProfileClose = @"profile_close";
NSString *const ATInteractionMessageCenterEventLabelProfileName = @"profile_name";
NSString *const ATInteractionMessageCenterEventLabelProfileEmail = @"profile_email";
NSString *const ATInteractionMessageCenterEventLabelProfileSubmit = @"profile_submit";

NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";
NSString *const ATMessageCenterDidSkipProfileKey = @"ATMessageCenterDidSkipProfileKey";

typedef NS_ENUM(NSInteger, ATMessageCenterState) {
	ATMessageCenterStateInvalid = 0,
	ATMessageCenterStateEmpty,
	ATMessageCenterStateComposing,
	ATMessageCenterStateWhoCard,
	ATMessageCenterStateSending,
	ATMessageCenterStateConfirmed,
	ATMessageCenterStateNetworkError,
	ATMessageCenterStateHTTPError,
	ATMessageCenterStateReplied
};


@interface ApptentiveMessageCenterViewController ()

@property (weak, nonatomic) IBOutlet ApptentiveMessageCenterGreetingView *greetingView;
@property (strong, nonatomic) IBOutlet ApptentiveMessageCenterStatusView *statusView;
@property (strong, nonatomic) IBOutlet ApptentiveMessageCenterInputView *messageInputView;
@property (strong, nonatomic) IBOutlet ApptentiveMessageCenterProfileView *profileView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *neuMessageButtonItem; // newMessageButtonItem

@property (strong, nonatomic) IBOutlet ApptentiveAttachmentController *attachmentController;

@property (strong, nonatomic) ApptentiveMessageCenterDataSource *dataSource;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (readonly, nonatomic) NSIndexPath *indexPathOfLastMessage;

@property (assign, nonatomic) ATMessageCenterState state;

@property (weak, nonatomic) UIView *activeFooterView;

@property (strong, nonatomic) ApptentiveMessage *contextMessage;

@property (assign, nonatomic) BOOL isSubsequentDisplay;

@property (readonly, nonatomic) NSString *trimmedMessage;
@property (readonly, nonatomic) BOOL messageComposerHasText;
@property (readonly, nonatomic) BOOL messageComposerHasAttachments;
@property (readonly, nonatomic) NSDictionary *bodyLengthDictionary;

@property (assign, nonatomic) CGRect lastKnownKeyboardRect;

@end


@implementation ApptentiveMessageCenterViewController

- (void)viewDidLoad {
	// TODO: Figure out a way to avoid tightly coupling this
	[Apptentive sharedConnection].backend.presentedMessageCenterViewController = self;

	[super viewDidLoad];

	[self.interaction engage:ATInteractionMessageCenterEventLabelLaunch fromViewController:self];

	[self.navigationController.toolbar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(compose:)]];

	self.navigationItem.rightBarButtonItem.title = ApptentiveLocalizedString(@"Close", @"Button that closes Message Center.");
	self.navigationItem.rightBarButtonItem.accessibilityHint = ApptentiveLocalizedString(@"Closes Message Center.", @"Accessibility hint for 'close' button");

	self.dataSource = [[ApptentiveMessageCenterDataSource alloc] initWithDelegate:self];
	[self.dataSource start];

	[Apptentive sharedConnection].backend.messageDelegate = self;

	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
	self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
	self.dataSource.dateFormatter.dateFormat = self.dateFormatter.dateFormat; // Used to determine if date changed between messages

	self.navigationItem.title = self.interaction.title;

	self.tableView.separatorColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorSeparator];
	self.tableView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorCollectionBackground];

	self.greetingView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorBackground];
	self.greetingView.borderView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorSeparator];

	self.greetingView.titleLabel.text = self.interaction.greetingTitle;
	self.greetingView.titleLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleHeaderTitle];

	self.greetingView.messageLabel.text = self.interaction.greetingBody;
	self.greetingView.messageLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleHeaderMessage];

	self.greetingView.imageView.imageURL = self.interaction.greetingImageURL;

	self.greetingView.aboutButton.hidden = !self.interaction.branding;
	self.greetingView.aboutButton.tintColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleHeaderMessage];
	self.greetingView.isOnScreen = NO;

	[self updateHeaderFooterTextSize:nil];

	[self.greetingView.aboutButton setImage:[[ApptentiveBackend imageNamed:@"at_info"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	self.greetingView.aboutButton.accessibilityLabel = ApptentiveLocalizedString(@"About Apptentive", @"Accessibility label for 'show about' button");
	self.greetingView.aboutButton.accessibilityHint = ApptentiveLocalizedString(@"Displays information about this feature.", @"Accessibilty hint for 'show about' button");

	self.statusView.mode = ATMessageCenterStatusModeEmpty;

	self.messageInputView.messageView.text = self.draftMessage ?: @"";
	self.messageInputView.messageView.textContainerInset = UIEdgeInsetsMake(TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET);
	[self.messageInputView.clearButton setImage:[[ApptentiveBackend imageNamed:@"at_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

	self.messageInputView.placeholderLabel.text = self.interaction.composerPlaceholderText;
	self.messageInputView.placeholderLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorTextInputPlaceholder];

	self.messageInputView.placeholderLabel.hidden = self.messageInputView.messageView.text.length > 0;

	self.messageInputView.titleLabel.text = self.interaction.composerTitle;
	self.neuMessageButtonItem.title = self.interaction.composerTitle;
	[self.messageInputView.sendButton setTitle:self.interaction.composerSendButtonTitle forState:UIControlStateNormal];

	self.messageInputView.sendButton.accessibilityHint = ApptentiveLocalizedString(@"Sends the message.", @"Accessibility hint for 'send' button");

	self.messageInputView.clearButton.accessibilityLabel = ApptentiveLocalizedString(@"Discard", @"Accessibility label for 'discard' button");
	self.messageInputView.clearButton.accessibilityHint = ApptentiveLocalizedString(@"Discards the message.", @"Accessibility hint for 'discard' button");

	[self.messageInputView.attachButton setImage:[ApptentiveBackend imageNamed:@"at_attach"] forState:UIControlStateNormal];
	[self.messageInputView.attachButton setTitleColor:[[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorBackground] forState:UIControlStateNormal];

	self.messageInputView.attachButton.accessibilityLabel = ApptentiveLocalizedString(@"Attach", @"Accessibility label for 'attach' button");
	self.messageInputView.attachButton.accessibilityHint = ApptentiveLocalizedString(@"Attaches a photo or screenshot", @"Accessibility hint for 'attach'");

	self.messageInputView.containerView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorBackground];
	self.messageInputView.borderColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorSeparator];
	self.messageInputView.messageView.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleTextInput];
	self.messageInputView.messageView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorTextInputBackground];
	self.messageInputView.titleLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleButton];

	self.statusView.statusLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleMessageCenterStatus];
	self.statusView.imageView.tintColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleMessageCenterStatus];

	if (self.interaction.profileRequested) {
		UIBarButtonItem *profileButtonItem = [[UIBarButtonItem alloc] initWithImage:[ApptentiveBackend imageNamed:@"at_account"] landscapeImagePhone:[ApptentiveBackend imageNamed:@"at_account"] style:UIBarButtonItemStylePlain target:self action:@selector(showWho:)];
		profileButtonItem.accessibilityLabel = ApptentiveLocalizedString(@"Profile", @"Accessibility label for 'edit profile' button");
		profileButtonItem.accessibilityHint = ApptentiveLocalizedString(@"Displays name and email editor.", @"Accessibility hint for 'edit profile' button");
		self.navigationItem.leftBarButtonItem = profileButtonItem;

		self.profileView.containerView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorBackground];
		self.profileView.titleLabel.text = self.interaction.profileInitialTitle;
		self.profileView.titleLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleButton];
		self.profileView.requiredLabel.text = self.interaction.profileInitialEmailExplanation;
		self.profileView.requiredLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleSurveyInstructions];
		[self.profileView.saveButton setTitle:self.interaction.profileInitialSaveButtonTitle forState:UIControlStateNormal];
		[self.profileView.skipButton setTitle:self.interaction.profileInitialSkipButtonTitle forState:UIControlStateNormal];
		self.profileView.skipButton.hidden = self.interaction.profileRequired;
		[self validateWho:self];
		self.profileView.borderColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorSeparator];

		self.profileView.nameField.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorTextInputBackground];
		self.profileView.emailField.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorTextInputBackground];

		NSDictionary *placeholderAttributes = @{NSForegroundColorAttributeName: [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorTextInputPlaceholder]};
		self.profileView.nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.interaction.profileInitialNamePlaceholder attributes:placeholderAttributes];
		self.profileView.emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.interaction.profileInitialEmailPlaceholder attributes:placeholderAttributes];

		if (self.interaction.profileRequired && [self shouldShowProfileViewBeforeComposing:YES]) {
			self.profileView.skipButton.hidden = YES;
			self.profileView.mode = ATMessageCenterProfileModeCompact;

			self.composeButtonItem.enabled = NO;
			self.neuMessageButtonItem.enabled = NO;
		} else {
			self.profileView.mode = ATMessageCenterProfileModeFull;
		}
	} else {
		self.navigationItem.leftBarButtonItem = nil;
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToFooterView:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDraft) name:UIApplicationDidEnterBackgroundNotification object:nil];

	// Fix iOS 7 bug where contentSize gets set to zero
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fixContentSize:) name:UIKeyboardDidShowNotification object:nil];

	// Respond to dynamic type size changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeaderFooterTextSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];

	[self.attachmentController addObserver:self forKeyPath:@"attachments" options:0 context:NULL];
	[self.attachmentController viewDidLoad];

	[self updateSendButtonEnabledStatus];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
	UIInterfaceOrientation interfaceOrientation = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIInterfaceOrientationPortrait : self.interfaceOrientation;
#pragma clang diagnostic pop
	self.greetingView.orientation = interfaceOrientation;
	self.profileView.orientation = interfaceOrientation;
	self.messageInputView.orientation = interfaceOrientation;
}

- (void)dealloc {
	[self.dataSource removeUnsentContextMessages];

	self.tableView.delegate = nil;
	self.messageInputView.messageView.delegate = nil;
	self.profileView.nameField.delegate = nil;
	self.profileView.emailField.delegate = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	@try {
		// May get here before -viewDidLoad completes, in which case we aren't an observer.
		[self.attachmentController removeObserver:self forKeyPath:@"attachments"];
	} @catch (NSException *__unused exception) {
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[UIView animateWithDuration:duration animations:^{
		UIInterfaceOrientation interfaceOrientation = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIInterfaceOrientationPortrait : toInterfaceOrientation;

		self.greetingView.orientation = interfaceOrientation;
		self.profileView.orientation = interfaceOrientation;
		self.messageInputView.orientation = interfaceOrientation;
		
		self.tableView.tableHeaderView = self.greetingView;
		[self resizeFooterView:nil];
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.lastKnownKeyboardRect = CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds), 20);

	if (self.attachmentController.active) {
		self.state = ATMessageCenterStateComposing;
		[self.attachmentController becomeFirstResponder];

		CGSize screenSize = [UIScreen mainScreen].bounds.size;
		CGSize drawerSize = self.attachmentController.inputView.bounds.size;
		self.lastKnownKeyboardRect = CGRectMake(0, screenSize.height - drawerSize.height, screenSize.width, drawerSize.height);
	} else if (self.messageComposerHasText || self.messageComposerHasAttachments) {
		self.state = ATMessageCenterStateComposing;
		[self.messageInputView.messageView becomeFirstResponder];
	} else if (self.isSubsequentDisplay == NO) {
		[self updateState];
	}

	if (self.isSubsequentDisplay == NO || self.attachmentController.active) {
		[self resizeFooterView:nil];
		[self engageGreetingViewEventIfNecessary];
		[self scrollToLastMessageAnimated:NO];

		self.isSubsequentDisplay = YES;
	}

	self.contextMessage = nil;
	if (self.interaction.contextMessageBody) {
		self.contextMessage = [[Apptentive sharedConnection].backend automatedMessageWithTitle:nil body:self.interaction.contextMessageBody];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self saveDraft];

	[[Apptentive sharedConnection].backend messageCenterWillDismiss:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.dataSource numberOfMessageGroups];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.dataSource numberOfMessagesInGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.dataSource markAsReadMessageAtIndexPath:indexPath];

	UITableViewCell<ApptentiveMessageCenterCell> *cell;
	ATMessageCenterMessageType type = [self.dataSource cellTypeAtIndexPath:indexPath];

	if (type == ATMessageCenterMessageTypeMessage || type == ATMessageCenterMessageTypeCompoundMessage) {
		NSString *cellIdentifier = type == ATMessageCenterMessageTypeCompoundMessage ? @"CompoundMessage" : @"Message";
		ApptentiveMessageCenterMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

		switch ([self.dataSource statusOfMessageAtIndexPath:indexPath]) {
			case ATMessageCenterMessageStatusHidden:
				messageCell.statusLabelHidden = YES;
				messageCell.layer.borderWidth = 0;
				break;
			case ATMessageCenterMessageStatusFailed:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
				messageCell.layer.borderColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorFailure].CGColor;
				messageCell.statusLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorFailure];
				messageCell.statusLabel.text = ApptentiveLocalizedString(@"Failed", @"Message failed to send.");
				break;
			case ATMessageCenterMessageStatusSending:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleMessageStatus];
				messageCell.statusLabel.text = ApptentiveLocalizedString(@"Sending…", @"Message is sending.");
				break;
			case ATMessageCenterMessageStatusSent:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleMessageStatus];
				messageCell.statusLabel.text = ApptentiveLocalizedString(@"Sent", @"Message sent successfully");
				break;
		}

		messageCell.statusLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleMessageStatus];

		cell = messageCell;
	} else if (type == ATMessageCenterMessageTypeReply || type == ATMessageCenterMessageTypeCompoundReply) {
		NSString *cellIdentifier = type == ATMessageCenterMessageTypeCompoundReply ? @"CompoundReply" : @"Reply";
		ApptentiveMessageCenterReplyCell *replyCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

		replyCell.supportUserImageView.imageURL = [self.dataSource imageURLOfSenderAtIndexPath:indexPath];

		replyCell.messageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		replyCell.senderLabel.text = [self.dataSource senderOfMessageAtIndexPath:indexPath];

		cell = replyCell;
	} else if (type == ATMessageCenterMessageTypeContextMessage) {
		// TODO: handle title
		ApptentiveMessageCenterContextMessageCell *contextMessageCell = [tableView dequeueReusableCellWithIdentifier:@"ContextMessage" forIndexPath:indexPath];

		cell = contextMessageCell;
	}

	cell.messageLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:UIFontTextStyleBody];
	cell.messageLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:UIFontTextStyleBody];
	cell.messageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];

	if (type == ATMessageCenterMessageTypeCompoundMessage || type == ATMessageCenterMessageTypeCompoundReply) {
		UITableViewCell<ApptentiveMessageCenterCompoundCell> *compoundCell = (ApptentiveCompoundMessageCell *)cell;

		compoundCell.collectionView.index = indexPath.section;
		compoundCell.collectionView.dataSource = self;
		compoundCell.collectionView.delegate = self;
		[compoundCell.collectionView reloadData];
		compoundCell.collectionView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorBackground];

		UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)compoundCell.collectionView.collectionViewLayout;
		layout.sectionInset = UIEdgeInsetsMake(ATTACHMENT_MARGIN.height, ATTACHMENT_MARGIN.width, ATTACHMENT_MARGIN.height, ATTACHMENT_MARGIN.width);
		layout.minimumInteritemSpacing = ATTACHMENT_MARGIN.width;
		layout.itemSize = [ApptentiveAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN];

		compoundCell.messageLabelHidden = compoundCell.messageLabel.text.length == 0;
	}

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat height = self.tableView.sectionHeaderHeight;

	if ([self.dataSource shouldShowDateForMessageGroupAtIndex:section]) {
		height += HEADER_LABEL_HEIGHT;
	}

	return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// iOS 7 requires this and there's no good way to instantiate a cell to sample, so we're hard-coding it for now.
	CGFloat verticalMargin, horizontalMargin, minimumCellHeight;
	BOOL statusLabelVisible = [self.dataSource statusOfMessageAtIndexPath:indexPath] != ATMessageCenterMessageStatusHidden;

	switch ([self.dataSource cellTypeAtIndexPath:indexPath]) {
		case ATMessageCenterMessageTypeContextMessage:
		case ATMessageCenterMessageTypeMessage:
			horizontalMargin = MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN;
			minimumCellHeight = 0;
			break;

		case ATMessageCenterMessageTypeCompoundMessage:
			horizontalMargin = MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN / 2.0 + [ApptentiveAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN];
			if (statusLabelVisible) {
				verticalMargin += MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN / 2.0 - STATUS_LABEL_MARGIN;
			}
			minimumCellHeight = 0;
			break;

		case ATMessageCenterMessageTypeReply:
			horizontalMargin = REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = REPLY_LABEL_TOTAL_VERTICAL_MARGIN;
			minimumCellHeight = REPLY_CELL_MINIMUM_HEIGHT;
			break;

		case ATMessageCenterMessageTypeCompoundReply:
			horizontalMargin = REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = 33.5 + [ApptentiveAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN];
			minimumCellHeight = REPLY_CELL_MINIMUM_HEIGHT + [ApptentiveAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN] - MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN / 2.0;
			break;
	}

	if (statusLabelVisible) {
		verticalMargin += STATUS_LABEL_HEIGHT + STATUS_LABEL_MARGIN;
	}

	NSString *labelText = [self.dataSource textOfMessageAtIndexPath:indexPath];
	CGFloat effectiveLabelWidth = CGRectGetWidth(tableView.bounds) - horizontalMargin;
	CGRect labelRect = CGRectZero;
	if (labelText.length) {
		UIFont *font = [[Apptentive sharedConnection].styleSheet fontForStyle:UIFontTextStyleBody];
		UIColor *color = [[Apptentive sharedConnection].styleSheet colorForStyle:UIFontTextStyleBody];
		NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:labelText attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: color}];
		labelRect = [attributedText boundingRectWithSize:CGSizeMake(effectiveLabelWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	} else {
		verticalMargin -= MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN / 2.0;
	}

	double height = ceil(fmax(labelRect.size.height + verticalMargin, minimumCellHeight) + 0.5);

	// "Due to an underlying implementation detail, you should not return values greater than 2009."
	return fmin(height, 2009.0);
}

#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (![self.dataSource shouldShowDateForMessageGroupAtIndex:section]) {
		return nil;
	}

	UITableViewHeaderFooterView *header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Date"];

	if (header == nil) {
		header = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"Date"];
	}

	header.textLabel.text = [self.dateFormatter stringFromDate:[self.dataSource dateOfMessageGroupAtIndex:section]];

	return header;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
	UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
	headerView.textLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleMessageDate];
	headerView.textLabel.textColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveTextStyleMessageDate];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([self.dataSource cellTypeAtIndexPath:indexPath]) {
		case ATMessageCenterMessageTypeMessage:
		case ATMessageCenterMessageTypeCompoundMessage:
			cell.contentView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorMessageBackground];
			break;
		case ATMessageCenterMessageTypeReply:
		case ATMessageCenterMessageTypeCompoundReply:
			cell.contentView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorReplyBackground];
		case ATMessageCenterMessageTypeContextMessage:
			cell.contentView.backgroundColor = [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorContextBackground];
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if (indexPath) {
		[[UIPasteboard generalPasteboard] setValue:[self.dataSource textOfMessageAtIndexPath:indexPath] forPasteboardType:(__bridge NSString *)kUTTypeUTF8PlainText];
	}
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self engageGreetingViewEventIfNecessary];
}

#pragma mark Fetch results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self updateStatusOfVisibleCells];

	@try {
		[self.tableView endUpdates];
	} @catch (NSException *exception) {
		ApptentiveLogError(@"caught exception: %@: %@", [exception name], [exception description]);
	}

	if (self.state != ATMessageCenterStateWhoCard && self.state != ATMessageCenterStateComposing) {
		[self updateState];

		[self resizeFooterView:nil];
		[self scrollToLastMessageAnimated:YES];
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	switch (type) {
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeMove:
			if (![indexPath isEqual:newIndexPath]) {
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
				[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			}
			break;

		default:
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}

#pragma mark Message center data source delegate

- (void)messageCenterDataSource:(ApptentiveMessageCenterDataSource *)dataSource didLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveCompoundMessageCell *cell = (ApptentiveCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ApptentiveIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ApptentiveAttachmentCell *attachmentCell = (ApptentiveAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];
	attachmentCell.progressView.hidden = YES;

	[collectionView reloadItemsAtIndexPaths:@[collectionViewIndexPath]];
}

- (void)messageCenterDataSource:(ApptentiveMessageCenterDataSource *)dataSource attachmentDownloadAtIndexPath:(NSIndexPath *)indexPath didProgress:(float)progress {
	ApptentiveCompoundMessageCell *cell = (ApptentiveCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ApptentiveIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ApptentiveAttachmentCell *attachmentCell = (ApptentiveAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];

	attachmentCell.progressView.hidden = NO;
	[attachmentCell.progressView setProgress:progress animated:YES];
}

- (void)messageCenterDataSource:(ApptentiveMessageCenterDataSource *)dataSource didFailToLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath error:(NSError *)error {
	ApptentiveCompoundMessageCell *cell = (ApptentiveCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ApptentiveIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ApptentiveAttachmentCell *attachmentCell = (ApptentiveAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];

	attachmentCell.progressView.hidden = YES;
	attachmentCell.progressView.progress = 0;

	[[[UIAlertView alloc] initWithTitle:ApptentiveLocalizedString(@"Unable to Download Attachment", @"Attachment download failed alert title") message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *attachmentIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:((ApptentiveIndexedCollectionView *)collectionView).index];

	if ([self.dataSource canPreviewAttachmentAtIndexPath:attachmentIndexPath]) {
		QLPreviewController *previewController = [[QLPreviewController alloc] init];

		previewController.dataSource = [self.dataSource previewDataSourceAtIndex:((ApptentiveIndexedCollectionView *)collectionView).index];
		previewController.currentPreviewItemIndex = indexPath.row;

		[self.navigationController pushViewController:previewController animated:YES];
	} else {
		[self.dataSource downloadAttachmentAtIndexPath:attachmentIndexPath];
	}
}

#pragma mark Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self.dataSource numberOfAttachmentsForMessageAtIndex:((ApptentiveIndexedCollectionView *)collectionView).index];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveAttachmentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Attachment" forIndexPath:indexPath];
	NSIndexPath *attachmentIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:((ApptentiveIndexedCollectionView *)collectionView).index];

	cell.usePlaceholder = [self.dataSource shouldUsePlaceholderForAttachmentAtIndexPath:attachmentIndexPath];
	cell.imageView.image = [self.dataSource imageForAttachmentAtIndexPath:attachmentIndexPath size:[ApptentiveAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN]];
	cell.extensionLabel.text = [self.dataSource extensionForAttachmentAtIndexPath:attachmentIndexPath];

	return cell;
}

#pragma mark - Text view delegate

- (void)textViewDidChange:(UITextView *)textView {
	[self updateSendButtonEnabledStatus];
	self.messageInputView.placeholderLabel.hidden = textView.text.length > 0;

	// Fix bug where text view doesn't scroll far enough down
	// Adapted from http://stackoverflow.com/a/19277383/27951
	CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
	CGFloat overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top);
	if (overflow > 0) {
		// Scroll caret to visible area
		CGPoint offset = textView.contentOffset;
		offset.y += overflow + textView.textContainerInset.bottom;

		// Cannot animate with setContentOffset:animated: or caret will not appear
		[UIView animateWithDuration:.2 animations:^{
			[textView setContentOffset:offset];
		}];
	}
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	self.state = ATMessageCenterStateComposing;

	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	self.attachmentController.active = NO;

	[self scrollToFooterView:nil];
}

#pragma mark Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.profileView.nameField) {
		[self.profileView.emailField becomeFirstResponder];
	} else {
		[self saveWho:textField];
		[self.profileView.emailField resignFirstResponder];
	}

	return NO;
}

#pragma mark - Message backend delegate

- (void)backend:(ApptentiveBackend *)backend messageProgressDidChange:(float)progress {
	ApptentiveProgressNavigationBar *navigationBar = (ApptentiveProgressNavigationBar *)self.navigationController.navigationBar;

	BOOL animated = navigationBar.progressView.progress < progress;
	[navigationBar.progressView setProgress:progress animated:animated];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
		[self discardDraft];
	}
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender {
	[self.attachmentController resignFirstResponder];

	[self.dataSource stop];

	UIViewController *presentingViewController = self.presentingViewController;

	[self dismissViewControllerAnimated:YES completion:^{
		[self.interaction engage:ATInteractionMessageCenterEventLabelClose fromViewController:presentingViewController];
	}];
}

- (IBAction)sendButtonPressed:(id)sender {
	NSString *message = self.trimmedMessage;

	if (self.contextMessage) {
		[[Apptentive sharedConnection].backend sendAutomatedMessage:self.contextMessage];
		self.contextMessage = nil;
	}

	if (self.messageComposerHasAttachments) {
		[[Apptentive sharedConnection].backend sendCompoundMessageWithText:message attachments:self.attachmentController.attachments hiddenOnClient:NO];
		[self.attachmentController clear];
	} else {
		[[Apptentive sharedConnection].backend sendTextMessageWithBody:message];
	}

	[self.attachmentController resignFirstResponder];
	self.attachmentController.active = NO;

	if ([self shouldShowProfileViewBeforeComposing:NO]) {
		[self.interaction engage:ATInteractionMessageCenterEventLabelProfileOpen fromViewController:self userInfo:@{ @"required": @(self.interaction.profileRequired),
			@"trigger": @"automatic" }];

		self.state = ATMessageCenterStateWhoCard;
	} else {
		[self.messageInputView.messageView resignFirstResponder];
		[self updateState];
	}

	self.messageInputView.messageView.text = @"";
	[self updateSendButtonEnabledStatus];
}

- (IBAction)compose:(id)sender {
	self.state = ATMessageCenterStateComposing;
	[self.messageInputView.messageView becomeFirstResponder];
}

- (IBAction)clear:(UIButton *)sender {
	if (!self.messageComposerHasText && !self.messageComposerHasAttachments) {
		[self discardDraft];
		return;
	}

	if (NSClassFromString(@"UIAlertController")) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.interaction.composerCloseConfirmBody message:nil preferredStyle:UIAlertControllerStyleActionSheet];

		[alertController addAction:[UIAlertAction actionWithTitle:self.interaction.composerCloseCancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
		[alertController addAction:[UIAlertAction actionWithTitle:self.interaction.composerCloseDiscardButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
			[self discardDraft];
		}]];

		[self presentViewController:alertController animated:YES completion:nil];
		alertController.popoverPresentationController.sourceView = sender.superview;
		alertController.popoverPresentationController.sourceRect = sender.frame;
	} else {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:self.interaction.composerCloseConfirmBody delegate:self cancelButtonTitle:self.interaction.composerCloseCancelButtonTitle destructiveButtonTitle:self.interaction.composerCloseDiscardButtonTitle otherButtonTitles:nil];

		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			[actionSheet showFromRect:sender.frame inView:sender.superview animated:YES];
		} else if (!self.navigationController.toolbarHidden) {
			[actionSheet showFromToolbar:self.navigationController.toolbar];
		} else {
			[actionSheet showInView:self.view];
		}
	}
}

- (IBAction)showWho:(id)sender {
	self.profileView.mode = ATMessageCenterProfileModeFull;

	self.profileView.skipButton.hidden = NO;
	self.profileView.titleLabel.text = self.interaction.profileEditTitle;

	NSDictionary *placeholderAttributes = @{NSForegroundColorAttributeName: [[Apptentive sharedConnection].styleSheet colorForStyle:ApptentiveColorTextInputPlaceholder]};
	self.profileView.nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.interaction.profileEditNamePlaceholder attributes:placeholderAttributes];
	self.profileView.emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.interaction.profileEditEmailPlaceholder attributes:placeholderAttributes];

	[self.profileView.saveButton setTitle:self.interaction.profileEditSaveButtonTitle forState:UIControlStateNormal];
	[self.profileView.skipButton setTitle:self.interaction.profileEditSkipButtonTitle forState:UIControlStateNormal];

	[self.interaction engage:ATInteractionMessageCenterEventLabelProfileOpen fromViewController:self userInfo:@{ @"required": @(self.interaction.profileRequired),
		@"trigger": @"button" }];

	self.state = ATMessageCenterStateWhoCard;

	[self resizeFooterView:nil];
	[self scrollToFooterView:nil];
}

- (IBAction)validateWho:(id)sender {
	self.profileView.saveButton.enabled = [self isWhoValid];
}

- (IBAction)saveWho:(id)sender {
	if (![self isWhoValid]) {
		return;
	}

	NSString *buttonLabel = nil;
	if ([sender isKindOfClass:[UIButton class]]) {
		buttonLabel = ((UIButton *)sender).titleLabel.text;
	} else if ([sender isKindOfClass:[UITextField class]]) {
		buttonLabel = @"return_key";
	}

	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@(self.interaction.profileRequired) forKey:@"required"];
	if (buttonLabel) {
		[userInfo setObject:buttonLabel forKey:@"button_label"];
	}

	[self.interaction engage:ATInteractionMessageCenterEventLabelProfileSubmit fromViewController:self userInfo:userInfo];

	if (self.profileView.nameField.text != [Apptentive sharedConnection].personName) {
		[Apptentive sharedConnection].personName = self.profileView.nameField.text;
		[self.interaction engage:ATInteractionMessageCenterEventLabelProfileName fromViewController:self userInfo:@{ @"length": @(self.profileView.nameField.text.length) }];
	}

	if (self.profileView.emailField.text != [Apptentive sharedConnection].personEmailAddress) {
		[Apptentive sharedConnection].personEmailAddress = self.profileView.emailField.text;
		[self.interaction engage:ATInteractionMessageCenterEventLabelProfileEmail fromViewController:self userInfo:@{ @"length": @(self.profileView.emailField.text.length),
			@"valid": @([ApptentiveUtilities emailAddressIsValid:self.profileView.emailField.text]) }];
	}

	[[Apptentive sharedConnection].backend updatePersonIfNeeded];

	self.composeButtonItem.enabled = YES;
	self.neuMessageButtonItem.enabled = YES;
	[self updateState];

	if (self.state == ATMessageCenterStateEmpty) {
		[self.messageInputView.messageView becomeFirstResponder];
	} else {
		[self.view endEditing:YES];
		[self resizeFooterView:nil];
	}
}

- (IBAction)skipWho:(id)sender {
	NSDictionary *userInfo = @{ @"required": @(self.interaction.profileRequired) };
	if ([sender isKindOfClass:[UIButton class]]) {
		userInfo = @{ @"required": @(self.interaction.profileRequired),
			@"method": @"button",
			@"button_label": ((UIButton *)sender).titleLabel.text };
	}
	[self.interaction engage:ATInteractionMessageCenterEventLabelProfileClose fromViewController:sender userInfo:userInfo];

	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:ATMessageCenterDidSkipProfileKey];
	[self updateState];
	[self.view endEditing:YES];
	[self resizeFooterView:nil];
}

- (IBAction)showAbout:(id)sender {
	[(ApptentiveNavigationController *)self.navigationController pushAboutApptentiveViewController];
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context {
	[self updateSendButtonEnabledStatus];
}

#pragma mark - Private

- (void)updateStatusOfVisibleCells {
	NSMutableArray *indexPathsToReload = [NSMutableArray array];
	for (UITableViewCell *cell in self.tableView.visibleCells) {
		if ([cell isKindOfClass:[ApptentiveMessageCenterMessageCell class]]) {
			ApptentiveMessageCenterMessageCell *messageCell = (ApptentiveMessageCenterMessageCell *)cell;
			NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
			BOOL shouldHideStatus = [self.dataSource statusOfMessageAtIndexPath:indexPath] == ATMessageCenterMessageStatusHidden;

			if (messageCell.statusLabelHidden != shouldHideStatus) {
				[indexPathsToReload addObject:indexPath];
			}
		}
	}

	@try {
		[self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
	} @catch (NSException *exception) {
		ApptentiveLogError(@"caught exception: %@: %@", [exception name], [exception description]);
	}
}

- (NSDictionary *)bodyLengthDictionary {
	return @{ @"body_length": @(self.messageInputView.messageView.text.length) };
}

- (NSString *)trimmedMessage {
	return [self.messageInputView.messageView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)messageComposerHasText {
	return self.trimmedMessage.length > 0;
}

- (BOOL)messageComposerHasAttachments {
	return self.attachmentController.attachments.count > 0;
}

- (void)updateSendButtonEnabledStatus {
	self.messageInputView.sendButton.enabled = self.messageComposerHasText || self.messageComposerHasAttachments;
}

- (void)saveDraft {
	if (self.messageComposerHasText) {
		[[NSUserDefaults standardUserDefaults] setObject:self.trimmedMessage forKey:ATMessageCenterDraftMessageKey];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATMessageCenterDraftMessageKey];
	}

	[self.attachmentController saveDraft];
}

- (BOOL)isWhoValid {
	BOOL emailIsValid = [ApptentiveUtilities emailAddressIsValid:self.profileView.emailField.text];
	BOOL emailIsBlank = self.profileView.emailField.text.length == 0;

	if (self.interaction.profileRequired) {
		return emailIsValid;
	} else {
		return emailIsValid || emailIsBlank;
	}
}

- (void)updateState {
	if ([self shouldShowProfileViewBeforeComposing:YES]) {
		[self.interaction engage:ATInteractionMessageCenterEventLabelProfileOpen fromViewController:self userInfo:@{ @"required": @(self.interaction.profileRequired),
			@"trigger": @"automatic" }];

		self.state = ATMessageCenterStateWhoCard;
	} else if (!self.dataSource.hasNonContextMessages) {
		self.state = ATMessageCenterStateEmpty;
	} else if (self.dataSource.lastMessageIsReply) {
		self.state = ATMessageCenterStateReplied;
	} else {
		BOOL networkIsUnreachable = [[ApptentiveReachability sharedReachability] currentNetworkStatus] == ApptentiveNetworkNotReachable;

		switch (self.dataSource.lastUserMessageState) {
			case ATPendingMessageStateConfirmed:
				self.state = ATMessageCenterStateConfirmed;
				break;
			case ATPendingMessageStateError:
				self.state = networkIsUnreachable ? ATMessageCenterStateNetworkError : ATMessageCenterStateHTTPError;
				break;
			case ATPendingMessageStateSending:
				self.state = networkIsUnreachable ? ATMessageCenterStateNetworkError : ATMessageCenterStateSending;
				break;
			case ATPendingMessageStateComposing:
				// This indicates that the last message is a context message.
				self.state = ATMessageCenterStateReplied;
				break;
			case ATPendingMessageStateNone:
				self.state = ATMessageCenterStateEmpty;
				break;
		}
	}
}

- (void)setState:(ATMessageCenterState)state {
	if (_state != state) {
		UIView *oldFooter = self.activeFooterView;
		UIView *newFooter = nil;
		BOOL toolbarHidden = NO;

		_state = state;

		self.navigationItem.leftBarButtonItem.enabled = YES;

		switch (state) {
			case ATMessageCenterStateEmpty:
				newFooter = self.messageInputView;
				toolbarHidden = YES;
				break;

			case ATMessageCenterStateComposing:
				newFooter = self.messageInputView;
				toolbarHidden = YES;
				break;

			case ATMessageCenterStateWhoCard:
				// Only focus profile view if appearing post-send.
				if ([self.attachmentController isFirstResponder]) {
					[self.attachmentController resignFirstResponder];
					[self.profileView becomeFirstResponder];
				}
				if (!self.interaction.profileRequired) {
					[self.profileView becomeFirstResponder];
				}
				self.navigationItem.leftBarButtonItem.enabled = NO;
				self.profileView.nameField.text = [Apptentive sharedConnection].personName;
				self.profileView.emailField.text = [Apptentive sharedConnection].personEmailAddress;
				toolbarHidden = YES;
				newFooter = self.profileView;
				break;

			case ATMessageCenterStateSending:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeEmpty;
				self.statusView.statusLabel.text = nil;
				break;

			case ATMessageCenterStateConfirmed:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeEmpty;
				self.statusView.statusLabel.text = self.interaction.statusBody;

				[self.interaction engage:ATInteractionMessageCenterEventLabelStatus fromViewController:self];
				break;

			case ATMessageCenterStateNetworkError:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeNetworkError;
				self.statusView.statusLabel.text = self.interaction.networkErrorBody;

				[self.interaction engage:ATInteractionMessageCenterEventLabelNetworkError fromViewController:self];

				[self scrollToFooterView:nil];
				break;

			case ATMessageCenterStateHTTPError:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeHTTPError;
				self.statusView.statusLabel.text = self.interaction.HTTPErrorBody;

				[self.interaction engage:ATInteractionMessageCenterEventLabelHTTPError fromViewController:self];

				[self scrollToFooterView:nil];
				break;

			case ATMessageCenterStateReplied:
				newFooter = nil;
				break;

			default:
				ApptentiveLogError(@"Invalid Message Center State: %d", state);
				break;
		}

		[self.navigationController setToolbarHidden:toolbarHidden animated:YES];

		if (newFooter != oldFooter) {
			newFooter.alpha = 0;
			newFooter.hidden = NO;

			if (oldFooter == self.messageInputView) {
				[self.interaction engage:ATInteractionMessageCenterEventLabelComposeClose fromViewController:self userInfo:self.bodyLengthDictionary];
			}

			if (newFooter == self.messageInputView) {
				[self.interaction engage:ATInteractionMessageCenterEventLabelComposeOpen fromViewController:self];
			}

			self.activeFooterView = newFooter;
			[self resizeFooterView:nil];

			[UIView animateWithDuration:0.25 animations:^{
				newFooter.alpha = 1;
				oldFooter.alpha = 0;
			} completion:^(BOOL finished) {
				oldFooter.hidden = YES;
			}];
		}
	}
}

- (NSIndexPath *)indexPathOfLastMessage {
	NSInteger lastSectionIndex = self.tableView.numberOfSections - 1;

	if (lastSectionIndex == -1) {
		return nil;
	}

	NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex] - 1;

	if (lastRowIndex == -1) {
		return nil;
	}

	return [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
}

- (CGRect)rectOfLastMessage {
	NSIndexPath *indexPath = self.indexPathOfLastMessage;

	if (indexPath) {
		return [self.tableView rectForRowAtIndexPath:indexPath];
	} else {
		return self.greetingView.frame;
	}
}

- (void)scrollToFooterView:(NSNotification *)notification {
	if (notification) {
		self.lastKnownKeyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	}

	BOOL isIOS7 = ![NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)];
	CGRect localKeyboardRect = self.view.window ? [self.view.window convertRect:self.lastKnownKeyboardRect toView:self.tableView.superview] : self.lastKnownKeyboardRect;

	CGFloat topContentInset = isIOS7 ? 64.0 : self.tableView.contentInset.top;
	CGFloat footerSpace = [self.dataSource numberOfMessageGroups] > 0 ? self.tableView.sectionFooterHeight : 0;
	CGFloat verticalOffset = CGRectGetMaxY(self.rectOfLastMessage) + footerSpace;
	CGFloat toolbarHeight = self.navigationController.toolbarHidden ? 0 : CGRectGetHeight(self.navigationController.toolbar.bounds);

	CGFloat iOS7FudgeFactor = isIOS7 && self.view.window == nil ? topContentInset : 0;
	CGFloat heightOfVisibleView = fmin(CGRectGetMinY(localKeyboardRect), CGRectGetHeight(self.view.bounds) - toolbarHeight - iOS7FudgeFactor);
	CGFloat verticalOffsetMaximum = fmax(-64, self.tableView.contentSize.height - heightOfVisibleView);

	verticalOffset = fmin(verticalOffset, verticalOffsetMaximum);
	CGPoint contentOffset = CGPointMake(0, verticalOffset);

	CGFloat duration = notification ? [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] : 0.25;
	[UIView animateWithDuration:duration animations:^{
			self.tableView.contentOffset = contentOffset;
	}];
}

- (void)resizeFooterView:(NSNotification *)notification {
	CGFloat height = 0;

	if (self.state == ATMessageCenterStateComposing || self.state == ATMessageCenterStateEmpty) {
		if (notification) {
			self.lastKnownKeyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
		}

		CGRect localKeyboardRect = self.view.window ? [self.view.window convertRect:self.lastKnownKeyboardRect toView:self.tableView.superview] : self.lastKnownKeyboardRect;
		CGFloat topContentInset = [NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)] ? self.tableView.contentInset.top : 64.0;

		// Available space is between the top of the keyboard and the bottom of the navigation bar
		height = fmin(CGRectGetMinY(localKeyboardRect), CGRectGetHeight(self.view.bounds)) - topContentInset;

		// Unless the top of the keyboard is below the (visible) toolbar, then subtract the toolbar height
		if (CGRectGetHeight(CGRectIntersection(localKeyboardRect, self.view.frame)) == 0 && !self.navigationController.toolbarHidden) {
			height -= CGRectGetHeight(self.navigationController.toolbar.bounds);
		}

		if (!self.dataSource.hasNonContextMessages && CGRectGetMinY(localKeyboardRect) >= CGRectGetMaxY(self.tableView.frame)) {
			height -= CGRectGetHeight(self.greetingView.bounds);
		}
	} else {
		height = CGRectGetHeight(self.activeFooterView.bounds);

		if (!self.navigationController.toolbarHidden) {
			height += CGRectGetHeight(self.navigationController.toolbar.bounds);
		}
	}

	CGRect frame = self.tableView.tableFooterView.frame;

	frame.size.height = height;

	[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
		self.tableView.tableFooterView.frame = frame;
		[self.tableView.tableFooterView layoutIfNeeded];
		[self.activeFooterView updateConstraints];
		self.tableView.tableFooterView = self.tableView.tableFooterView;
	}];
}

- (void)keyboardDidShow:(NSNotification *)notification {
	if (!self.attachmentController.active) {
		[self.interaction engage:ATInteractionMessageCenterEventLabelKeyboardOpen fromViewController:self userInfo:self.bodyLengthDictionary];
	}
}

- (void)keyboardDidHide:(NSNotification *)notification {
	if (!self.attachmentController.active) {
		[self.interaction engage:ATInteractionMessageCenterEventLabelKeyboardClose fromViewController:self userInfo:self.bodyLengthDictionary];
	}
}

- (NSString *)draftMessage {
	return [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey] ?: @"";
}

- (void)scrollToLastMessageAnimated:(BOOL)animated {
	if (self.state != ATMessageCenterStateEmpty && !(self.state == ATMessageCenterStateWhoCard && self.interaction.profileRequired && !self.dataSource.hasNonContextMessages)) {
		[self scrollToFooterView:nil];
	}
}

- (void)engageGreetingViewEventIfNecessary {
	BOOL greetingOnScreen = self.tableView.contentOffset.y < self.greetingView.bounds.size.height;
	if (self.greetingView.isOnScreen != greetingOnScreen) {
		if (greetingOnScreen) {
			[self.interaction engage:ATInteractionMessageCenterEventLabelGreetingMessage fromViewController:self];
		}
		self.greetingView.isOnScreen = greetingOnScreen;
	}
}

- (BOOL)shouldShowProfileViewBeforeComposing:(BOOL)beforeComposing {
	if ([ApptentiveUtilities emailAddressIsValid:[Apptentive sharedConnection].personEmailAddress]) {
		return NO;
	} else if (self.interaction.profileRequired) {
		return YES;
	} else if (self.interaction.profileRequested && !beforeComposing) {
		return ![[NSUserDefaults standardUserDefaults] boolForKey:ATMessageCenterDidSkipProfileKey];
	} else {
		return NO;
	}
}

- (void)discardDraft {
	self.messageInputView.messageView.text = nil;
	[self.messageInputView.messageView resignFirstResponder];

	[self.attachmentController clear];
	[self.attachmentController resignFirstResponder];

	[self updateSendButtonEnabledStatus];
	[self updateState];

	[self resizeFooterView:nil];

	// iOS 7 needs a sec to allow the keyboard to disappear before scrolling
	dispatch_async(dispatch_get_main_queue(), ^{
		[self scrollToLastMessageAnimated:YES];
	});
}

// Fix a bug where iOS7 resets the contentSize to zero sometimes
- (void)fixContentSize:(NSNotification *)notification {
	if (self.tableView.contentSize.height == 0) {
		self.tableView.tableFooterView = self.tableView.tableFooterView;
		[self scrollToFooterView:nil];
	}
}

- (void)updateHeaderFooterTextSize:(NSNotification *)notification {
	self.greetingView.titleLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleHeaderTitle];
	self.greetingView.messageLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleHeaderMessage];

	self.messageInputView.sendButton.titleLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleDoneButton];
	self.messageInputView.placeholderLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleTextInput];

	self.messageInputView.titleLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleButton];
	self.messageInputView.messageView.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleTextInput];

	self.statusView.statusLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleMessageCenterStatus];

	self.profileView.titleLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleButton];
	self.profileView.saveButton.titleLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleDoneButton];
	self.profileView.skipButton.titleLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleButton];
	self.profileView.requiredLabel.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];
	self.profileView.nameField.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleTextInput];
	self.profileView.emailField.font = [[Apptentive sharedConnection].styleSheet fontForStyle:ApptentiveTextStyleTextInput];
}

@end
