// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSMutableDictionaryWrapper.h"
#import "DSCommon.h"


NS_ASSUME_NONNULL_BEGIN


extern NSString * const DSDictionaryXSLStyleSheetContentPlaceholder;


@interface DSDictionaryXSLArguments : DSMutableDictionaryWrapper<DSXSLArgumentKey, NSString *> <NSMutableCopying>


// Known arguments:
/*
 parental-control: '' or '1'
 aria-label: string, copied to <html> in result of the app & panel xforms
    - seems to be set to title or headword
 base-url: string, copied as the href of a <base> element in the <head> of app & panel
    - file:// URL of KeyText.index resource in the dictionary bundle... weird
 rtl-direction: string: if nonempty, dir="rtl" is tacked onto <html> in app & panel
    - some property read off the dictionary info plist? or language detection?
 stylesheet-content: string: content to put in a <style> in the <head> in app & panel
    - internally they seem to have abandoned the idea of putting all the CSS in this, and instead
      put a placeholder string in and then replace that string with the CSS blob
 */


@property (nonatomic, getter=isParentalControlEnabled) BOOL parentalControlEnabled;
@property (nonatomic, copy, nullable) NSString *ariaLabel;
@property (nonatomic, copy, nullable) NSURL *baseURL;
@property (nonatomic, copy, nullable) NSString *rtlDirection;
@property (nonatomic, copy, nullable) NSString *stylesheetContent;
-(void)setStylesheetContentPlaceholder;

-(void)setString:(NSString *)value forKey:(DSXSLArgumentKey)key escape:(BOOL)escape;
-(void)setURL:(NSURL *)url forKey:(DSXSLArgumentKey)key escape:(BOOL)escape;
-(void)setBool:(BOOL)val forKey:(DSXSLArgumentKey)key;
-(BOOL)boolForKey:(DSXSLArgumentKey)key DS_WARN_UNUSED_RESULT;

@end


NS_ASSUME_NONNULL_END
