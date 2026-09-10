//
//  UMDbQueryCondition.m
//  ulibdb.framework
//
//  Created by Andreas Fink on 27.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMDbQueryCondition.h>
#import <ulib/UMDbQueryPlaceholder.h>
#import <ulib/ulib_config.h>

@implementation UMDbQueryCondition

@synthesize leftSideOperator;
@synthesize rightSideOperator;


- (UMDbQueryCondition *) initWithLeft:(id)left op:(UMDbQueryConditionOperator)op right:(id)right
{
    self=[super init];
    if(self)
    {
        if (left)
        {
            leftSideOperator = left;
        }
        else
        {
            leftSideOperator = nil;
        }
        if (right)
        {
            rightSideOperator = right;
        }
        else
        {
            rightSideOperator = nil;
        }
        operator = op;
    }
    return self;
}

+ (UMDbQueryCondition *) queryConditionLeft:(id)left
                                         op:(UMDbQueryConditionOperator)op
                                      right:(id)right
{
    return [[UMDbQueryCondition alloc] initWithLeft:left op:op right:right];
}



- (NSString *) description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"("];
    if(leftSideOperator)
    {
        [s appendString:[leftSideOperator description]];
    }
    else
    {
        [s appendFormat:@"NULL"];
    }
    [s appendFormat:@","];
    
    
    switch(operator)
    {
        case UMDBQUERY_OPERATOR_NONE:
            [s appendString:@"NONE"];
            break;
        case UMDBQUERY_OPERATOR_AND:
            [s appendString:@"AND"];
            break;
        case UMDBQUERY_OPERATOR_OR:
            [s appendString:@"OR"];
            break;
        case UMDBQUERY_OPERATOR_NOT:
            [s appendString:@"NOT"];
            break;
        case UMDBQUERY_OPERATOR_EQUAL:
            [s appendString:@"EQUAL"];
            break;
        case UMDBQUERY_OPERATOR_NOT_EQUAL:
            [s appendString:@"NOT_EQUAL"];
            break;
        case UMDBQUERY_OPERATOR_LIKE:
            [s appendString:@"LIKE"];
            break;
        case UMDBQUERY_OPERATOR_NOT_LIKE:
            [s appendString:@"NOT_LIKE"];
            break;
        case UMDBQUERY_OPERATOR_GREATER_THAN:
            [s appendString:@"GREATER_THAN"];
            break;
        case UMDBQUERY_OPERATOR_LESS_THAN:
            [s appendString:@"LESS_THAN"];
            break;
        default:
            [s appendString:@"BOGOUS"];
            break;
    }
    [s appendFormat:@","];
    if(rightSideOperator)
    {
        [s appendString:[rightSideOperator description]];
    }
    else
    {
        [s appendFormat:@"NULL"];
    }
    [s appendFormat:@")"];
    return s;
}


- (NSString *) sqlForQuery:(UMDbQuery *)query
                parameters:(NSArray *)params
                    dbType:(UMDbDriverType)dbType
           primaryKeyValue:(id)primaryKeyValue;
{
    return [self sqlForQuery:query
                  parameters:params
                      dbType:dbType
                     session:NULL
             primaryKeyValue:primaryKeyValue];

}

- (NSString *) sqlForQuery:(UMDbQuery *)query
                parameters:(NSArray *)params
                    dbType:(UMDbDriverType)dbType
                   session:(UMDbSession *)session
           primaryKeyValue:(id)primaryKeyValue
{
    NSMutableString *s = [[NSMutableString alloc]initWithString:@" "];
    if(leftSideOperator)
    {
        if([leftSideOperator isKindOfClass:[UMDbQueryCondition class]])
        {
            [s appendString:@"("];
            [s appendString:[leftSideOperator sqlForQuery:query parameters:params dbType:dbType primaryKeyValue:primaryKeyValue]];
            [s appendString:@")"];
        }
        else if([leftSideOperator isKindOfClass:[UMDbQueryPlaceholder class]])
        {
            [s appendString:[leftSideOperator sqlForQueryLeft:query
                                                   parameters:params
                                                       dbType:dbType
                                                      session:session
                                              primaryKeyValue:primaryKeyValue]];
        }
        else if([leftSideOperator isKindOfClass:[NSString class]])
        {
            if ([leftSideOperator length] > 0)
            {
                [s appendString:leftSideOperator];
            }
            else
            {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Left condition is empty, cannot create query" userInfo:nil];
            }
        }
    }
    else
    {
         @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Left condition is nil, cannot create query" userInfo:nil];
    }
    switch(operator)
    {
        case UMDBQUERY_OPERATOR_NONE:
            [s appendString:@" "];
            break;
        case UMDBQUERY_OPERATOR_AND:
            [s appendString:@" AND "];
            break;
        case UMDBQUERY_OPERATOR_OR:
            [s appendString:@" OR "];
            break;
        case UMDBQUERY_OPERATOR_NOT:
            [s appendString:@" NOT "];
            break;
        case UMDBQUERY_OPERATOR_EQUAL:
            [s appendString:@" = "];
            break;
        case UMDBQUERY_OPERATOR_NOT_EQUAL:
            [s appendString:@" <> "];
            break;
        case UMDBQUERY_OPERATOR_LIKE:
            [s appendString:@" LIKE "];
            break;
        case UMDBQUERY_OPERATOR_NOT_LIKE:
            [s appendString:@" NOT LIKE "];
            break;
        case UMDBQUERY_OPERATOR_GREATER_THAN:
            [s appendString:@" > "];
            break;
        case UMDBQUERY_OPERATOR_LESS_THAN:
            [s appendString:@" < "];
            break;
        default:
            break;

    }
    if(rightSideOperator)
    {
        if([rightSideOperator isKindOfClass:[UMDbQueryCondition class]])
        {
            [s appendString:@"("];
            [s appendString:[rightSideOperator sqlForQuery:query parameters:params dbType:dbType primaryKeyValue:primaryKeyValue]];
            [s appendString:@")"];
        }
        else if([rightSideOperator isKindOfClass:[UMDbQueryPlaceholder class]])
        {
            NSMutableString *sql = [[rightSideOperator sqlForQueryRight:query       parameters:params
                                                                 dbType:dbType
                                                                session:session
                                                        primaryKeyValue:primaryKeyValue] mutableCopy];
            if ([sql compare:@""] == NSOrderedSame) 
            {
                [s appendString:@"NULL"];
                NSRange wholeString = NSMakeRange(0, [s length]);
                [s replaceOccurrencesOfString:@"=" 
                                   withString:@"IS"
                                      options:NSLiteralSearch 
                                        range:wholeString];
            } 
            else if ([sql compare:@"NULL"] == NSOrderedSame) 
            {
                [s appendString:sql];
                NSRange wholeString = NSMakeRange(0, [s length]);
                [s replaceOccurrencesOfString:@"=" 
                                   withString:@"IS"
                                      options:NSLiteralSearch 
                                        range:wholeString];
            }
            else
                [s appendString:sql];
        }
        else if([rightSideOperator isKindOfClass:[NSString class]])
        {
            NSString *opAsString = [NSString stringWithString:rightSideOperator];
            if ([opAsString compare:@""] == NSOrderedSame) 
            {
                [s appendString:@"NULL"];
                NSRange wholeString = NSMakeRange(0, [s length]);
                [s replaceOccurrencesOfString:@"=" 
                                   withString:@"IS"
                                      options:NSLiteralSearch 
                                        range:wholeString];
            }
            else
            {
                [s appendString:rightSideOperator];
            }
        }
    }
    else
    {
        NSRange wholeString = NSMakeRange(0, [s length]);
        [s replaceOccurrencesOfString:@"=" 
                           withString:@"IS"
                              options:NSLiteralSearch 
                                range:wholeString];
        [s appendString:@"NULL"];
    }
    return s;
}

+ (UMDbQueryCondition *) a:(id)left isNotEqualTo:(id)right
{
    return [[UMDbQueryCondition alloc] 
            initWithLeft:left
            op:UMDBQUERY_OPERATOR_NOT_EQUAL
            right:right];
}

+ (UMDbQueryCondition *) a:(id)left isEqualTo:(id)right
{
    return [[UMDbQueryCondition alloc] 
            initWithLeft:left
            op:UMDBQUERY_OPERATOR_EQUAL
            right:right];
    
}

+ (UMDbQueryCondition *) a:(id)left isGreaterThan:(id)right
{
    return [[UMDbQueryCondition alloc] 
            initWithLeft:left
            op:UMDBQUERY_OPERATOR_GREATER_THAN
            right:right];
  
}


+ (UMDbQueryCondition *) a:(id)left isLessThan:(id)right
{
    return [[UMDbQueryCondition alloc] 
            initWithLeft:left
            op:UMDBQUERY_OPERATOR_LESS_THAN
            right:right];
    
}

+ (UMDbQueryCondition *) a:(id)left isLike:(id)right
{
    return [[UMDbQueryCondition alloc] 
            initWithLeft:left
            op:UMDBQUERY_OPERATOR_LIKE
            right:right];

}



- (NSString *) sqlForQueryLeft:(UMDbQuery *)query
                    parameters:(NSArray *)params
                        dbType:(UMDbDriverType)dbType
               primaryKeyValue:(id)primaryKeyValue
{
    return [self sqlForQuery:query parameters:params dbType:dbType primaryKeyValue:primaryKeyValue];
}

- (NSString *) sqlForQueryRight:(UMDbQuery *)query parameters:(NSArray *)params dbType:(UMDbDriverType)dbType primaryKeyValue:(id)primaryKeyValue
{
    return [self sqlForQuery:query parameters:params dbType:dbType primaryKeyValue:primaryKeyValue];
}

@end
