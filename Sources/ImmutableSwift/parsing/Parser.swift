class Parser {
    enum ParserError: Error {
        case failedToPrase(_ tokens: [Token], _ node: Any)
    }

    func parse(_ tokenizer: Tokenizer) -> DataModel? {
        let tokens: [Token] = tokenizer.tokenize()
        return Parser.parseDataModel(ArraySlice<Token>(tokens))
    }

    private static func parseDataModel(_ tokens: ArraySlice<Token>) -> DataModel? {
        // parse imports
        var ptr: Int = tokens.startIndex
        let parseImportsResult = parseImports(tokens)
        if parseImportsResult.success {
            ptr = parseImportsResult.endIndex
        }

        // parse optional access level
        let parseAccessLevelResult = Parser.parseAccessControlLevel(tokens[ptr...])
        if parseAccessLevelResult.success {
            ptr = parseAccessLevelResult.endIndex
        }

        // parse required nameToken
        let (nameToken, nameTokenIndex) = Parser.nextMeaningfulToken(tokens[ptr...])
        if nameToken == nil || !(nameToken is Word) {
            print("Failed to parse", DataModel.self, "from tokens:", tokens)
            return nil
        }
        ptr = nameTokenIndex + 1

        // parse optional plugins
        let parsePluginsResult = Parser.parsePlugins(tokens[ptr...])
        if parsePluginsResult.success {
            ptr = parsePluginsResult.endIndex
        }

        // parse schema
        let parseSchemaResult = Parser.parseSchema(tokens[ptr...])
        if !parseSchemaResult.success {
            return nil
        }

        return DataModel(parseImportsResult.importStatements, parseAccessLevelResult.accessControlLevel, nameToken!.source, parsePluginsResult.plugins, parseSchemaResult.schema!)
    }

    private static func parseImports(_ tokens: ArraySlice<Token>) -> (success: Bool, importStatements: [Import]?, endIndex: Int) {
        var importStatements: [Import] = []

        var (success, importStatement, endIndex) = parseImport(tokens)
        var previousEndIndex: Int = endIndex
        while success {
            previousEndIndex = endIndex
            importStatements.append(importStatement!)
            (success, importStatement, endIndex) = parseImport(tokens[endIndex...])
        }
        if !importStatements.isEmpty {
            return (true, importStatements, previousEndIndex)
        } else {
            return (false, nil, -1)
        }
    }

    private static func parseImport(_ tokens: ArraySlice<Token>) -> (success: Bool, importStatement: Import?, endIndex: Int) {
        let (tokensInCurrentLine, endIndex) = Parser.tokensInCurrentLine(tokens)
        let meaningfulTokensInCurrentLine = Parser.stripWhitespaceAndLineBreak(tokensInCurrentLine)

        if meaningfulTokensInCurrentLine.count < 2 {
            return (false, nil, -1)
        }

        if !(meaningfulTokensInCurrentLine[0] is Word) {
            return (false, nil, -1)
        }

        let importKeyword: Word = meaningfulTokensInCurrentLine[0] as! Word
        if importKeyword.source != Keyword.IMPORT {
            return (false, nil, -1)
        }

        if Parser.matchTokenTypes(meaningfulTokensInCurrentLine, [Word.self, Word.self]) {
            // import module
            return (true, SingleModuleImport((meaningfulTokensInCurrentLine[1] as! Word).source), endIndex)
        } else if Parser.matchTokenTypes(meaningfulTokensInCurrentLine, [Word.self, Word.self, Dot.self, Word.self]) {
            // import module.submodule
            return (true, ModuleWithSubmoduleImport((meaningfulTokensInCurrentLine[1] as! Word).source, (meaningfulTokensInCurrentLine[3] as! Word).source), endIndex)
        } else if Parser.matchTokenTypes(meaningfulTokensInCurrentLine, [Word.self, Word.self, Word.self, Dot.self, Word.self]) {
            // import kind module.symbol
            return (true, ModuleWithSymbolImport((meaningfulTokensInCurrentLine[1] as! Word).source, (meaningfulTokensInCurrentLine[2] as! Word).source, (meaningfulTokensInCurrentLine[4] as! Word).source), endIndex)
        }

        return (false, nil, -1)
    }

    private static func parseAccessControlLevel(_ tokens: ArraySlice<Token>) -> (success: Bool, accessControlLevel: AccessControl?, endIndex: Int) {
        let (accessControlLevel, index) = Parser.nextMeaningfulToken(tokens)
        if accessControlLevel == nil {
            return (false, nil, -1)
        }

        if !(accessControlLevel is Word) {
            return (false, nil, -1)
        }

        if (accessControlLevel as! Word).source == Keyword.AccessControlModifier.PUBLIC_LEVEL {
            return (true, AccessControl.levelPublic, index + 1)
        } else if (accessControlLevel as! Word).source == Keyword.AccessControlModifier.INTERNAL_LEVEL {
            return (true, AccessControl.levelInternal, index + 1)
        }

        return (false, nil, -1)
    }

    private static func parsePlugins(_ tokens: ArraySlice<Token>) -> (success: Bool, plugins: PluginList?, endIndex: Int) {
        var plugins: [String] = []

        let indexOfLeftParen = Parser.indexOfTokenWithType(tokens, LeftParen.self)
        let indexOfRightParen = Parser.indexOfTokenWithType(tokens, RightParen.self)

        if indexOfLeftParen >= 0, indexOfRightParen >= 0, indexOfLeftParen < indexOfRightParen {
            for i in indexOfLeftParen + 1 ..< indexOfRightParen {
                if tokens[i] is Word {
                    plugins.append(tokens[i].source)
                }
            }
        }

        if !plugins.isEmpty {
            return (true, PluginList(plugins), indexOfRightParen + 1)
        } else {
            return (false, nil, -1)
        }
    }

    private static func parseSchema(_ tokens: ArraySlice<Token>) -> (success: Bool, schema: Schema?, endIndex: Int) {
        var statements: [Statement] = []
        let indexOfLeftBracket = Parser.indexOfTokenWithType(tokens, LeftCurlyBracket.self)
        let indexOfRightBracket = Parser.indexOfTokenWithType(tokens, RightCurlyBracket.self)

        if indexOfLeftBracket < 0 || indexOfRightBracket < 0 || indexOfLeftBracket >= indexOfRightBracket {
            return (false, nil, -1)
        }

        var (tokensInCurrentLine, endIndex) = Parser.tokensInCurrentLine(tokens[(indexOfLeftBracket + 1)...])
        while true {
            tokensInCurrentLine = tokensInCurrentLine.filter { !($0 is RightCurlyBracket) }
            if Parser.nextMeaningfulToken(tokensInCurrentLine[...]).0 is PoundSign {
                let (_, indexOfPoundSign) = Parser.nextMeaningfulToken(tokensInCurrentLine[...])
                statements.append(Parser.parseComment(tokensInCurrentLine[(indexOfPoundSign + 1)...]))
            } else {
                let stateDef = parseStateDef(tokensInCurrentLine)
                if stateDef != nil {
                    statements.append(stateDef!)
                }
            }
            if endIndex >= indexOfRightBracket {
                break
            }
            (tokensInCurrentLine, endIndex) = Parser.tokensInCurrentLine(tokens[endIndex...])
        }

        if !statements.isEmpty {
            return (true, Schema(statements), indexOfRightBracket + 1)
        } else {
            return (false, nil, -1)
        }
    }

    private static func parseComment(_ tokens: ArraySlice<Token>) -> Comment {
        var source = ""
        for index in tokens.startIndex ..< tokens.endIndex {
            source = source + tokens[index].source
        }

        return Comment(source)
    }

    private static func parseStateDef(_ tokens: [Token]) -> StateDef? {
        let meaningfulTokens: [Token] = Parser.stripWhitespaceAndLineBreak(tokens)
        if meaningfulTokens.count <= 1 {
            return nil
        }

        var typeIdentifier: String = ""

        for i in 0 ..< meaningfulTokens.count - 1 {
            typeIdentifier = typeIdentifier + meaningfulTokens[i].source
        }
        return StateDef(typeIdentifier, meaningfulTokens.last!.source)
    }

    // meaningful tokens refer to tokens that are neither whitespace nor linebreak
    private static func nextMeaningfulToken(_ tokens: ArraySlice<Token>) -> (meaningfulToken: Token?, index: Int) {
        for i in tokens.startIndex ..< tokens.endIndex {
            if !(tokens[i] is WhiteSpace), !(tokens[i] is LineBreak) {
                return (tokens[i], i)
            }
        }
        return (nil, -1)
    }

    private static func indexOfTokenWithType(_ tokens: ArraySlice<Token>, _ tokenType: Token.Type) -> Int {
        for index in tokens.startIndex ... tokens.endIndex - 1 {
            if type(of: tokens[index]) == tokenType {
                return index
            }
        }
        return -1
    }

    private static func tokensInCurrentLine(_ tokens: ArraySlice<Token>) -> (tokens: [Token], endIndex: Int) {
        var resultTokens: [Token] = []
        var endIndex: Int = tokens.endIndex
        for i in tokens.startIndex ... tokens.endIndex - 1 {
            if tokens[i] is LineBreak {
                endIndex = i + 1
                break
            } else {
                resultTokens.append(tokens[i])
            }
        }
        return (resultTokens, endIndex)
    }

    private static func stripWhitespaceAndLineBreak(_ tokens: [Token]) -> [Token] {
        return tokens.filter { !($0 is LineBreak) && !($0 is WhiteSpace) }
    }

    private static func matchTokenTypes(_ tokens: [Token], _ tokenTypes: [Token.Type]) -> Bool {
        if tokens.count != tokenTypes.count {
            return false
        }

        for i in 0 ..< tokens.count {
            if type(of: tokens[i]) != tokenTypes[i] {
                return false
            }
        }
        return true
    }
}
