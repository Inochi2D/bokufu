module bokufu.parser;

import bokufu.parser.unparsed;

import bokufu.tokenizer;
import bokufu.token;

import std.algorithm : move;
import std.sumtype;

import numem.all;

template matches(Types...)
{
    import std.meta : staticMap, templateOr;
    import std.typecons : Yes;

    

    bool matches(SumType)(auto ref SumType arg)
    if (isSumType!SumType)
    {
        alias exactly(T) = function (arg)
        {
            static assert(is(typeof(arg) == T));
            return true;
        };


        return match!(
            staticMap!(exactly, Types),
            _ => false,
        )(arg);
    }
}


struct Parser
{
package(bokufu.parser) @nogc:
	Tokenizer tokenizer;

	public this(Tokenizer tokenizer) {
		this.tokenizer = tokenizer;
	}

    public vector!RawRule consumeSpreadSheet() {
        vector!RawRule ret;

        while (tokenizer.hasMoreTokens()) {
            auto peek = tokenizer.peekToken();

            if (peek.matches!(WhitespaceToken)) {
                tokenizer.skipToken();
            } else {
                peek.match!(
                    (AtKeywordToken a) {
                        tokenizer.skipToken();
                        auto rule = this.consumeAtRule(a);
                        if (!rule.name.empty) {
                            ret ~= RawRule(move(rule));
                        }
                    },
                    (t) {
                        auto rule = this.consumeQualifiedRule();
                        ret ~= RawRule(move(rule));
                    }
                );
            }
        }

        return ret;
    }

    RawQualifiedRule consumeQualifiedRule(
        bool nested = false,
        bool hasStop = false,
        Token stop = Token(WhitespaceToken())
    ) {
        RawQualifiedRule rule = {};

        while (tokenizer.hasMoreTokens()) {
            auto peek = tokenizer.peekToken();

            if(hasStop && peek == stop) {
                break;
            } else if (peek.matches!(CloseCurlyToken)) {
                if (nested) {
                    break;
                }

                rule.prelude ~= RawComponentValue(peek);
                tokenizer.skipToken();
            } else if (peek.matches!(OpenCurlyToken)) {
                // If the first two non-<whitespace-token> values of rule’s prelude are an
                // <ident-token> whose value starts with "--" followed by a <colon-token>, then:
                // THIS IS NOT DONE

                tokenizer.skipToken();
                auto blockData = this.consumeRawBlockContents();
                if (!blockData.empty) {
                    blockData[0].match!(
                        (vector!RawDeclaration decls) {
                            rule.declarations = move(decls);
                            blockData.popFront();
                        },
                        (_) {}
                    );

                    while (!blockData.empty) {
                        auto data = blockData[0];
                        data.match!(
                            (vector!RawDeclaration decls) {
                                rule.children ~= nogc_new!RawRule(RawRule(RawNestedDeclarationRule(move(decls))));
                            },
                            (RawRule* a) {
                                rule.children ~= a;
                            },
                        );
                        blockData.popFront();
                    }
                }
                // consume the last `}`
                tokenizer.consumeToken();
                return rule;
            } else {
                tokenizer.skipToken();
                rule.prelude ~= this.consumeComponentValue(peek);
            }
        }

        // really should be `None`
        return RawQualifiedRule();
    }

    // Assumes `start` was the last consumed token
    RawAtRule consumeAtRule(AtKeywordToken start, bool nested = false) {
        RawAtRule rule = {
            name: start.value
        };

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next.matches!(SemicolonToken)) {
                break;
            } else if (next.matches!(CloseCurlyToken)) {
                if (nested) {
                    break;
                }

                rule.prelude ~= RawComponentValue(next);
            } else if (next.matches!(OpenCurlyToken)) {
                auto blockData = this.consumeRawBlockContents();
                tokenizer.consumeToken();

                rule.childRules ~= move(blockData);
            } else {
                rule.prelude ~= this.consumeComponentValue(next);
            }
        }

        return rule;
    }

    vector!RawBlockContents consumeRawBlockContents() {
        vector!RawBlockContents rules;
        vector!RawDeclaration decls;
        
        while (tokenizer.hasMoreTokens()) {
            auto peek = tokenizer.peekToken();

            if(peek.matches!(CloseCurlyToken)) {
                break;
            } else if(peek.matches!(WhitespaceToken) | peek.matches!(SemicolonToken)) {
                tokenizer.skipToken();
            } else {
                //     (AtKeywordToken a) {
                //         if (!decls.empty) {
                //             rules ~= RawBlockContents(move(decls));
                //         }

                //         auto next = this.consumeAtRule(a, true);
                //         if (!next.name.empty()) {
                //             rules ~= RawBlockContents(RawRule(move(next)));
                //         }
                //     },
                Tokenizer cloned = this.tokenizer;
                        
                auto decl = this.consumeDeclaration(true);
                if (decl.name.size() > 0) {
                    decls ~= move(decl);
                } else {
                    this.tokenizer = cloned;

                    auto rule = this.consumeQualifiedRule();

                    if (!decls.empty) {
                        rules ~= RawBlockContents(move(decls));
                    }
                    rules ~= RawBlockContents(nogc_new!RawRule(RawRule(move(rule))));
                }
            }
        }

        return rules;
    }

    RawDeclaration consumeDeclaration(bool nested = false) {
        RawDeclaration decl;

        Token cur = tokenizer.consumeToken();
        if (cur.match!(
            (IdentToken t) {
                decl.name = move(t.value);
                return false;
            },
            _ => true,
        )) {
            // TODO: bad declaration
        }
        tokenizer.consumeWhitespace();
        
        cur = tokenizer.consumeToken();
        if (cur.match!(
            (ColonToken t) {
                return false;
            },
            _ => true,
        )) {
            // TODO: bad declaration
        }
        tokenizer.consumeWhitespace();

        auto list = this.consumeComponentValueList(nested, Token(SemicolonToken()));

        // if (list[list.size() - 2] == RawComponentValue(Token(DelimToken('!')))) {
        //     list[list.size() - 1].match!(
        //         (Token t) {
        //             t.match!(
        //                 (StringToken t) {
        //                     if (asciiCaseInsensitiveEq(t.value[], "important")) {
        //                         list.popBack();
        //                         list.popBack();

        //                         decl.important = true;
        //                     }
        //                 },
        //                 (_) {}
        //             );
        //         },
        //         (_) {},
        //     );
        // }

        while (list[list.size() - 1] == RawComponentValue(Token(WhitespaceToken()))) {
            list.popBack();
        }

        bool seenBlock = false;
        bool seenOtherNonWhitespace = false;

        // TODO: custom properties

        for (int i = 0; i < list.size(); i++) {
            list[i].match!(
                (Token t) {
                    t.match!(
                        // Nothing
                        (WhitespaceToken t) {},
                        (_) {
                            seenOtherNonWhitespace = true;
                        }
                    );
                },
                (RawBlock t) {
                    if (t.associated == BlockToken(OpenCurlyToken())) {
                        seenBlock = true;
                    } else {
                        seenOtherNonWhitespace = true;
                    }
                },
                (_) {
                    seenOtherNonWhitespace = true;
                },
            );
        }

        decl.values = move(list);

        return decl;
    }

    vector!RawComponentValue consumeComponentValueList(bool nested = false, Token stop = Token(CloseParenToken())) {
        vector!RawComponentValue ret;

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next.matches!(CloseParenToken) || next == stop) {
                break;
            } else if (next.matches!(CloseCurlyToken)) {
                if (nested) {
                    break;
                }

                ret ~= RawComponentValue(next);
            } else {
                ret ~= this.consumeComponentValue(next);
            }
        }

        return ret;
    }

    // Assumes `start` was the last consumed token
    RawFunction consumeFunction(FunctionToken start) {
        RawFunction func = {
            name: start.value
        };

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next.matches!(CloseParenToken)) {
                break;
            } else {
                func.args ~= nogc_new!RawComponentValue(this.consumeComponentValue(next));
            }
        }

        return func;
    }
    
    RawBlock consumeSimpleBlock(BlockToken associated) {
        RawBlock block = {
            associated: associated
        };

        Token closing = associated.match!(
            (OpenSquareToken a) => Token(CloseSquareToken()),
            (OpenParenToken a) => Token(CloseParenToken()),
            (OpenCurlyToken a) => Token(CloseCurlyToken()),
        );

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next == closing) {
                break;
            } else {
                block.values ~= nogc_new!RawComponentValue(this.consumeComponentValue(next));
            }
        }

        return block;
    }

    RawComponentValue consumeComponentValue(Token t) {
        debug {
            import std.stdio;
            writeln("start component value ", t);
        }

        return t.match!(
            (OpenSquareToken a) => RawComponentValue(this.consumeSimpleBlock(BlockToken(a))),
            (OpenParenToken a) => RawComponentValue(this.consumeSimpleBlock(BlockToken(a))),
            (OpenCurlyToken a) => RawComponentValue(this.consumeSimpleBlock(BlockToken(a))),
            (FunctionToken a) => RawComponentValue(this.consumeFunction(a)),
            (a) => RawComponentValue(Token(a)),
        );
    }
}
