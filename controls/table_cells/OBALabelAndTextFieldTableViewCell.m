#import "OBALabelAndTextFieldTableViewCell.h"


#define kOBATableWidth                       320
#define kOBASpacing                          5
#define kOBAMinLabelWidth                    97


@implementation OBALabelAndTextFieldTableViewCell

+ (OBALabelAndTextFieldTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {
    
    static NSString *cellId = @"OBALabelAndTextFieldTableViewCell";
    
    // Try to retrieve from the table view a now-unused cell with the given identifier
    OBALabelAndTextFieldTableViewCell *cell = (OBALabelAndTextFieldTableViewCell *) [tableView dequeueReusableCellWithIdentifier:cellId];
    
    // If no cell is available, create a new one using the given identifier
    if (cell == nil) {
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:cellId owner:self options:nil];
        cell = nib[0];
        cell.textField.textAlignment = UITextAlignmentRight;
        cell.textField.returnKeyType = UIReturnKeyDone;
        cell.accessoryType = UITableViewCellAccessoryNone;        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}


- (void)layoutSubviews {
    CGSize labelSize = [_label sizeThatFits:CGSizeZero];
    labelSize.width = MIN(labelSize.width, _label.bounds.size.width);
    
    CGRect textFieldFrame = _textField.frame;
    textFieldFrame.origin.x = _label.frame.origin.x + MAX(kOBAMinLabelWidth, labelSize.width) + kOBASpacing;
    if (!_label.text.length)
        textFieldFrame.origin.x = _label.frame.origin.x;
    textFieldFrame.size.width = kOBATableWidth - textFieldFrame.origin.x - _label.frame.origin.x;
    _textField.frame = textFieldFrame;
}

@end
