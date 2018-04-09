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
    return (DSIndexName __nonnull)self[DSIndexInfoKeyName];
}

-(NSString *)path
{
    return (NSString * __nonnull)self[DSIndexInfoKeyPath];
}

-(NSArray *)supportedSearchMethods
{
    return self[DSIndexInfoKeyKeyMatchingMethods] ?: @[];
}

-(BOOL)supportsSearchMethod:(DSSearchMethod)searchMethod
{
    return [self.supportedSearchMethods containsObject:searchMethod];
}

-(BOOL)supportsFindByID
{
    return [self[DSIndexInfoKeySupportsDataID] boolValue];
}

-(BOOL)isBigEndian
{
    return [self[DSIndexInfoKeyBigEndian] boolValue];
}

-(NSArray<DSIndexField *> *)fields
{
    if(!_fields) {
        typedef NSDictionary<DSIndexFieldInfoKey, id> DSIndexFieldInfoDict;
        NSDictionary<DSIndexInfoDataFieldsKey, NSArray<DSIndexFieldInfoDict *> *> *dataFieldsByKind = self[DSIndexInfoKeyDataFields];

        NSArray<DSIndexFieldInfoDict *> *externalDataFieldDicts = dataFieldsByKind[DSIndexInfoDataFieldsKeyExternalFields];
        NSArray<DSIndexFieldInfoDict *> *fixedDataFieldDicts = dataFieldsByKind[DSIndexInfoDataFieldsKeyFixedFields];
        NSArray<DSIndexFieldInfoDict *> *variableDataFieldDicts = dataFieldsByKind[DSIndexInfoDataFieldsKeyVariableFields];

        NSMutableArray<DSIndexField *> *res = [NSMutableArray new];

        for(DSIndexFieldInfoDict *fieldDict in externalDataFieldDicts) {
            DSExternalDataIndexField *field = [[DSExternalDataIndexField alloc] initWithInfoDictionary:fieldDict];
            [res addObject:field];
        }

        for(DSIndexFieldInfoDict *fieldDict in fixedDataFieldDicts) {
            DSFixedLengthIndexField *field = [[DSFixedLengthIndexField alloc] initWithInfoDictionary:fieldDict];
            [res addObject:field];
        }

        for(DSIndexFieldInfoDict *fieldDict in variableDataFieldDicts) {
            DSVariableLengthIndexField *field = [[DSVariableLengthIndexField alloc] initWithInfoDictionary:fieldDict];
            [res addObject:field];
        }

        _fields = res;
    }

    return _fields;
}

@end
