import Foundation

class Tokenizer {
    let scanner: Scanner

    init(withScanner scanner: Scanner) {
        self.scanner = scanner
    }

    func tokenize() -> [Token] {
        var tokens: [Token] = []
        while scanner.hasNext() {
            let nextChar = scanner.peek()
            if [" ", "\t"].contains(nextChar) {
                _ = scanner.nextChar()
                tokens.append(WhiteSpace(String(nextChar)))
            } else if "\n" == nextChar {
                _ = scanner.nextChar()
                tokens.append(LineBreak(String(nextChar)))
            } else if "{" == nextChar {
                _ = scanner.nextChar()
                tokens.append(LeftCurlyBracket(String(nextChar)))
            } else if "}" == nextChar {
                _ = scanner.nextChar()
                tokens.append(RightCurlyBracket(String(nextChar)))
            } else if "(" == nextChar {
                _ = scanner.nextChar()
                tokens.append(LeftParen(String(nextChar)))
            } else if ")" == nextChar {
                _ = scanner.nextChar()
                tokens.append(RightParen(String(nextChar)))
            } else if "#" == nextChar {
                _ = scanner.nextChar()
                tokens.append(PoundSign(String(nextChar)))
            } else if "," == nextChar {
                _ = scanner.nextChar()
                tokens.append(Comma(String(nextChar)))
            } else if "." == nextChar {
                _ = scanner.nextChar()
                tokens.append(Dot(String(nextChar)))
            } else {
                let word = Tokenizer.parseWord(scanner)
                tokens.append(word)
            }
        }
        return tokens
    }

    private static func parseWord(_ scanner: Scanner) -> Word {
        let stopWords: [Character] = [" ", "\t", "\n", "{", "}", "(", ")", "#", ",", "."]
        var source = ""

        while scanner.hasNext(), !stopWords.contains(scanner.peek()) {
            source = source + String(scanner.nextChar())
        }

        return Word(source)
    }
}
