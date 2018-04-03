// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSIndexInfo.h"
#import "FrameworkInternals.h"
#import "DSIndexField.h"


@implementation DSIndexInfo

@synthesize fields=_fields;

-(DSIndexName)name
{
    return (DSIndexName __nonnull)self[kIDXPropertyIndexName];
}

-(NSString *)path
{
    return (NSString * __nonnull)self[kIDXPropertyIndexPath];
}

-(NSArray *)supportedSearchMethods
{
    return self[kIDXPropertyIndexKeyMatchingMethods] ?: @[];
}

-(BOOL)supportsSearchMethod:(DSSearchMethod)searchMethod
{
    return [self.supportedSearchMethods containsObject:searchMethod];
}

-(BOOL)supportsFindByID
{
    return [self[kIDXPropertyIndexSupportDataID] boolValue];
}

-(BOOL)isBigEndian
{
    return [self[kIDXPropertyIndexBigEndian] boolValue];
}

-(NSArray<DSIndexField *> *)fields
{
    if(!_fields) {
        NSDictionary *dataFieldsByKind = self[kIDXPropertyDataFields];

        NSArray *externalDataFieldDicts = dataFieldsByKind[kIDXPropertyExternalFields];
        NSArray *fixedDataFieldDicts = dataFieldsByKind[kIDXPropertyFixedFields];
        NSArray *variableDataFieldDicts = dataFieldsByKind[kIDXPropertyVariableFields];

        NSMutableArray *res = [NSMutableArray new];

        for(NSDictionary *fieldDict in externalDataFieldDicts) {
            DSExternalDataIndexField *field = [[DSExternalDataIndexField alloc] initWithInfoDictionary:fieldDict];
            [res addObject:field];
        }

        for(NSDictionary *fieldDict in fixedDataFieldDicts) {
            DSFixedLengthIndexField *field = [[DSFixedLengthIndexField alloc] initWithInfoDictionary:fieldDict];
            [res addObject:field];
        }

        for(NSDictionary *fieldDict in variableDataFieldDicts) {
            DSVariableLengthIndexField *field = [[DSVariableLengthIndexField alloc] initWithInfoDictionary:fieldDict];
            [res addObject:field];
        }

        _fields = res;
    }

    return _fields;
}

@end
