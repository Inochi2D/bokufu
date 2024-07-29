module bokufu.parser.unparsed;

import bokufu.token;

import std.sumtype;

import numem.all;

struct RawFunction {
    nstring name;
    vector!(RawComponentValue*) args;
}

alias BlockToken = SumType!(OpenSquareToken, OpenParenToken, OpenCurlyToken);
struct RawBlock {
    BlockToken associated;
    vector!(RawComponentValue*) values;
}

alias RawComponentValue = SumType!(Token, RawBlock, RawFunction);

struct RawQualifiedRule {
    vector!RawComponentValue prelude;
    vector!RawDeclaration declarations;
    vector!(RawRule*) children;
}

struct RawAtRule {
    nstring name;
    vector!RawComponentValue prelude;
    
    bool isBlock;
    vector!RawDeclaration declarations;
    vector!RawBlockContents childRules;
}

struct RawNestedDeclarationRule {
    vector!RawDeclaration declarations;
}

alias RawRule = SumType!(RawAtRule, RawQualifiedRule, RawNestedDeclarationRule);
 
struct RawDeclaration {
    nstring name;
    vector!RawComponentValue values;
    bool important;
    nstring originalText;
}

alias RawBlockContents = SumType!(RawRule*, vector!RawDeclaration);
