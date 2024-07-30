module bokufu.parser.unparsed;

import bokufu.token;

import numem.all;

@nogc nothrow:

struct RawFunctionData {
    nstring name;
    vector!(RawComponentValue*) args;
}

struct RawBlockData {
    Token associated;
    vector!(RawComponentValue*) values;
}

enum RawComponentValueType {
    token,
    rawBlock,
    rawFunction,
}

union RawComponentValueData {
    Token token_;
    RawBlockData block_;
    RawFunctionData function_;
}

struct RawComponentValue {
@nogc nothrow:
    RawComponentValueType type;
    RawComponentValueData data;

    this(ref return scope inout(RawComponentValue) src) inout
    {
        this.type = src.type;
        if (src.type == RawComponentValueType.token) {
            this.data.token_ = src.data.token_;
        } else if (src.type == RawComponentValueType.rawBlock) {
            this.data.block_ = src.data.block_;
        } else if (src.type == RawComponentValueType.rawFunction) {
            this.data.function_ = src.data.function_;
        }
    }

    this(Token token_) {
        this.type = RawComponentValueType.token;
        this.data.token_ = token_;
    }

    this(RawBlockData block_) {
        this.type = RawComponentValueType.rawBlock;
        this.data.block_ = block_;
    }

    this(RawFunctionData function_) {
        this.type = RawComponentValueType.rawFunction;
        this.data.function_ = function_;
    }
}

struct RawQualifiedRuleData {
    vector!RawComponentValue prelude;
    vector!RawDeclaration declarations;
    vector!(RawRule*) children;
}

struct RawAtRuleData {
    nstring name;
    vector!RawComponentValue prelude;
    
    bool isBlock;
    vector!RawDeclaration declarations;
    vector!RawBlockContents childRules;
}

struct RawNestedDeclarationRuleData {
    vector!RawDeclaration declarations;
}

enum RawRuleType {
    rawAtRule,
    rawQualifiedRule,
    rawNestedDeclarationRule,
}

union RawRuleData {
    RawAtRuleData at_;
    RawQualifiedRuleData qualified_;
    RawNestedDeclarationRuleData nested_;
}

struct RawRule {
@nogc nothrow:
    RawRuleType type;
    RawRuleData data;

    this(ref return scope inout(RawRule) src) inout
    {
        this.type = src.type;
        if (src.type == RawRuleType.rawAtRule) {
            this.data.at_ = src.data.at_;
        } else if (src.type == RawRuleType.rawQualifiedRule) {
            this.data.qualified_ = src.data.qualified_;
        } else if (src.type == RawRuleType.rawNestedDeclarationRule) {
            this.data.nested_ = src.data.nested_;
        }
    }

    this(RawAtRuleData at_) {
        this.type = RawRuleType.rawAtRule;
        this.data.at_ = at_;
    }

    this(RawQualifiedRuleData qualified_) {
        this.type = RawRuleType.rawQualifiedRule;
        this.data.qualified_ = qualified_;
    }

    this(RawNestedDeclarationRuleData nested_) {
        this.type = RawRuleType.rawNestedDeclarationRule;
        this.data.nested_ = nested_;
    }
}

struct RawDeclaration {
    nstring name;
    vector!RawComponentValue values;
    bool important;
    nstring originalText;
}

struct RawBlockContents {
    vector!RawDeclaration decls;
    RawRule* rule;
}
