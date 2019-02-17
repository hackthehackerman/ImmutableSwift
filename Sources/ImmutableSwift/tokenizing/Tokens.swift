class Token: CustomStringConvertible {
    let source: String
    init(_ source: String) {
        self.source = source
    }

    var description: String {
        return String(describing: type(of: self)) + ": " + source
    }
}

class Word: Token {}
class WhiteSpace: Token {}
class LineBreak: Token {}
class LeftCurlyBracket: Token {}
class RightCurlyBracket: Token {}
class LeftParen: Token {}
class RightParen: Token {}
class PoundSign: Token {}
class Dot: Token {}
class Comma: Token {}
