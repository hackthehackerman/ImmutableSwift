class Scanner {
    let source: String
    var currentCharIndex: Int = 0

    init(fromSource source: String) {
        self.source = source
    }

    func nextChar() -> Character {
        let index = source.index(source.startIndex, offsetBy: currentCharIndex)
        currentCharIndex = currentCharIndex + 1
        return source[index]
    }

    func peek() -> Character {
        let index = source.index(source.startIndex, offsetBy: currentCharIndex)
        return source[index]
    }

    func hasNext() -> Bool {
        return currentCharIndex < source.count
    }
}
