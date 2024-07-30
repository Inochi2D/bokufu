module bokufu.parser;

import bokufu.parser.unparsed;

import bokufu.tokenizer;
import bokufu.token;

import numem.all;


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

            if (peek.type == TokenType.whitespaceToken) {
                tokenizer.skipToken();
            } else if (peek.type == TokenType.atKeywordToken) {
                tokenizer.skipToken();
                auto rule = this.consumeAtRule(peek.data.at_);
                if (!rule.name.empty) {
                    ret ~= RawRule(rule);
                }
            } else {
                auto rule = this.consumeQualifiedRule();
                ret ~= RawRule(rule);
            }
        }

        return ret;
    }

    RawQualifiedRuleData consumeQualifiedRule(
        bool nested = false,
        bool hasStop = false,
        Token stop = Token(TokenType.whitespaceToken)
    ) {
        RawQualifiedRuleData rule = {};

        while (tokenizer.hasMoreTokens()) {
            auto peek = tokenizer.peekToken();

            if(hasStop && peek == stop) {
                break;
            } else if (peek.type == TokenType.closeCurlyToken) {
                if (nested) {
                    break;
                }

                rule.prelude ~= RawComponentValue(peek);
                tokenizer.skipToken();
            } else if (peek.type == TokenType.openCurlyToken) {
                // If the first two non-<whitespace-token> values of rule’s prelude are an
                // <ident-token> whose value starts with "--" followed by a <colon-token>, then:
                // THIS IS NOT DONE

                tokenizer.skipToken();
                auto blockData = this.consumeRawBlockContents();
                if (!blockData.empty) {
                    // blockData[0].match!(
                    //     (vector!RawDeclaration decls) {
                    //         rule.declarations = move(decls);
                    //         blockData.popFront();
                    //     },
                    //     (_) {}
                    // );

                    // while (!blockData.empty) {
                    //     auto data = blockData[0];
                    //     data.match!(
                    //         (vector!RawDeclaration decls) {
                    //             rule.children ~= nogc_new!RawRule(RawRule(RawNestedDeclarationRule(move(decls))));
                    //         },
                    //         (RawRule* a) {
                    //             rule.children ~= a;
                    //         },
                    //     );
                    //     blockData.popFront();
                    // }
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
        return RawQualifiedRuleData();
    }

    // Assumes `start` was the last consumed token
    RawAtRuleData consumeAtRule(AtKeywordTokenData start, bool nested = false) {
        RawAtRuleData rule = {
            name: start.value
        };

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next.type == TokenType.semicolonToken) {
                break;
            } else if (next.type == TokenType.closeCurlyToken) {
                if (nested) {
                    break;
                }

                rule.prelude ~= RawComponentValue(next);
            } else if (next.type == TokenType.openCurlyToken) {
                auto blockData = this.consumeRawBlockContents();
                tokenizer.consumeToken();

                rule.childRules ~= blockData;
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

            if(peek.type == TokenType.closeCurlyToken) {
                break;
            } else if(peek.type == TokenType.whitespaceToken || peek.type == TokenType.semicolonToken) {
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
                    decls ~= decl;
                } else {
                    this.tokenizer = cloned;

                    auto rule = this.consumeQualifiedRule();

                    if (!decls.empty) {
                        rules ~= RawBlockContents(decls, null);
                    }
                    rules ~= RawBlockContents(vector!RawDeclaration(), nogc_new!RawRule(RawRule(rule)));
                }
            }
        }

        return rules;
    }

    RawDeclaration consumeDeclaration(bool nested = false) {
        RawDeclaration decl;

        Token cur = tokenizer.consumeToken();
        if (cur.type == TokenType.identToken) {
            auto data = &cur.data.ident_;
            decl.name = data.value;
        }
        tokenizer.consumeWhitespace();
        
        cur = tokenizer.consumeToken();
        if (cur.type != TokenType.colonToken) {
            // TODO: bad declaration
        }
        tokenizer.consumeWhitespace();

        auto list = this.consumeComponentValueList(nested, TokenType.semicolonToken);

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

        while (list[list.size() - 1] == RawComponentValue(Token(TokenType.whitespaceToken))) {
            list.popBack();
        }

        bool seenBlock = false;
        bool seenOtherNonWhitespace = false;

        // TODO: custom properties

        for (int i = 0; i < list.size(); i++) {
            final switch (list[i].type) {
                case RawComponentValueType.token:
                {
                    switch (list[i].data.token_.type) {
                        case TokenType.whitespaceToken: break;
                        default:
                            seenOtherNonWhitespace = true;
                            break;
                    }
                    break;
                }
                case RawComponentValueType.rawBlock:
                {
                    if (list[i].data.block_.associated.type == TokenType.openCurlyToken) {
                        seenBlock = true;
                    } else {
                        seenOtherNonWhitespace = true;
                    }
                    break;
                }
                case RawComponentValueType.rawFunction:
                    seenOtherNonWhitespace = true;
                    break;
            }
        }

        decl.values = list;

        return decl;
    }

    vector!RawComponentValue consumeComponentValueList(bool nested = false, TokenType stop = TokenType.closeParenToken) {
        vector!RawComponentValue ret;

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next.type == TokenType.closeParenToken || next.type == stop) {
                break;
            } else if (next.type == TokenType.closeCurlyToken) {
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
    RawFunctionData consumeFunction(FunctionTokenData start) {
        RawFunctionData func = {
            name: start.value
        };
        

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next.type == TokenType.closeParenToken) {
                break;
            } else {
                func.args ~= nogc_new!RawComponentValue(this.consumeComponentValue(next));
            }
        }

        return func;
    }
    
    RawBlockData consumeSimpleBlock(Token associated) {
        RawBlockData block = {
            associated: associated
        };

        TokenType closing;
        switch (associated.type) {
            case TokenType.openSquareToken:
                closing = TokenType.closeSquareToken;
                break;
            case TokenType.openParenToken:
                closing = TokenType.closeParenToken;
                break;
            case TokenType.openCurlyToken:
                closing = TokenType.closeCurlyToken;
                break;
            default: break;
        }

        while (tokenizer.hasMoreTokens()) {
            auto next = tokenizer.consumeToken();

            if(next.type == closing) {
                break;
            } else {
                block.values ~= nogc_new!RawComponentValue(this.consumeComponentValue(next));
            }
        }

        return block;
    }

    RawComponentValue consumeComponentValue(Token t) {
        switch (t.type) {
            case TokenType.openSquareToken:
                goto case;
            case TokenType.openParenToken:
                goto case;
            case TokenType.openCurlyToken:
                return RawComponentValue(this.consumeSimpleBlock(t));
            case TokenType.functionToken:

                return RawComponentValue(this.consumeFunction(t.data.func_));
            default: return RawComponentValue(t);
        }
    }
}
