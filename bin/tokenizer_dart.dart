import 'package:args/args.dart';
import 'dart:io';

// Note: This test case: "Hello! World! Hello World! Hello World !\nTest!,!" has two possible outcomes.
// One outcome is for the entered string in the dart file and the text file, while the other is the CLI outcome.
// The first outcome recognizes \nTest as separate, while the other outcome recognizes the other as a one.
// This is due to the fact that the terminal in general has different code for a new line and not applicable directly to
// the program.

enum TokenType {
  word, punctuation, phrase, number, empty, eol, eof, unkown,
}

class Token {
  String value;
  TokenType type;
  int row;
  int column;

  Token(
    this.value, 
    this.type, 
    this.row, 
    this.column
  );

  @override
  String toString() {
    return value;
  }
}

List<Token> tokens = [];

void main(List<String> arguments) {
  ArgParser parser = ArgParser();
  
  parser.addOption('string', abbr: 's', defaultsTo: "Hello, world!");
  parser.addOption('preprocess', abbr: 'p', defaultsTo: 'true');
  parser.addOption('usingfile', abbr: 'f', defaultsTo: 'false');
  parser.addOption('filename', abbr: 'n', defaultsTo: '');
 
  ArgResults results = parser.parse(arguments);

  // String testString = "Hello! World! Hello World! Hello World !\nTest!,!";
  // tokens = identify(
  //   extract(testString)
  // );

  String string = results['string'];
  bool preprocess = bool.parse(results['preprocess']);
  bool usingFile = bool.parse(results['usingfile']);
  String filename = results['filename'];

  if (usingFile && filename.isNotEmpty) {
    String contents = File(filename).readAsStringSync();
    string = contents;
  }

  tokens = identify(
    extract(
      string,
      preprocess: preprocess,
      usingFile: usingFile
    )
  );

  print(tokens);

  for (Token token in tokens) {
    print("Token: ${token.value}\t\t Type: ${token.type}\t\t Row: ${token.row}\t\t Column: ${token.column}");
  }
}

List<Token> extract(String string, {bool preprocess = true, bool usingFile = false}) {
  List<Token> rawTokens = [];
  String currentToken = "";
  int currentRow = 0;
  int currentCol = 0;

  for (int rune in string.runes) {
    String char = String.fromCharCode(rune);
    
    if (char == "\n") {
      currentRow = 0;
      rawTokens.add(
        Token("eol", TokenType.eol, currentRow, currentCol)
      );
      currentCol++;
      continue;
    }

    if (char != "!") {
      currentToken += char;
      continue;
    }

    if (RegExp(r"\s").hasMatch(currentToken[0]) && preprocess) {
      currentToken = currentToken.substring(1, currentToken.length);
    }

    if (RegExp(r"\s").hasMatch(currentToken[currentToken.length - 1]) && preprocess) { 
      currentToken = currentToken.substring(0, currentToken.length - 1);
    }

    rawTokens.add(
      Token(currentToken, TokenType.empty, currentRow, currentCol)
    );
    currentToken = "";
    currentRow++;
  }

  if (currentToken.isNotEmpty) {
    rawTokens.add(
      Token(currentToken, TokenType.empty, currentRow, currentCol)
    );
  }

  if (!usingFile) {
    rawTokens.add(
      Token("eol", TokenType.eol, currentRow, currentCol)
    );
  }

  if (usingFile) {
    rawTokens.add(
      Token("eof", TokenType.eof, currentRow, currentCol)
    );
  }

  return rawTokens;
}

List<Token> identify(List<Token> tokens) {
  for (Token token in tokens) {
    if (token.type == TokenType.eol || token.type == TokenType.eof) continue;

    if (changeType(isPhrase(token.value), token, TokenType.phrase)) continue;

    if (changeType(isNumeric(token.value), token, TokenType.number)) continue;

    if (changeType(isAlphabetical(token.value), token, TokenType.word)) continue;
    
    if (changeType(isPunctuation(token.value), token, TokenType.punctuation)) continue;

    if (changeType(isUnknown(token.value), token, TokenType.unkown)) continue;
  }
  return tokens;
}

bool changeType(bool condition, Token token, TokenType type) {
  if (condition) {
    token.type = type;
    return true;
  }
  return false;
}

bool isNumeric(String s) {
  final regex = RegExp(r'^-?(([0-9]*)|(([0-9]*)\.([0-9]*)))$');
  return regex.hasMatch(s);
}

bool isAlphabetical(String s) {
  final wordAlone = RegExp(r'^[a-zA-Z]+$');
  final withPunctuation = RegExp(r"(?<=\s|^|\b)(?:[-'.%$#&\/]\b|\b[-'.%$#&\/]|[A-Za-z0-9]|\([A-Za-z0-9]+\))+(?=\s|$|\b)");
  return wordAlone.hasMatch(s) || withPunctuation.hasMatch(s);
}

bool isPhrase(String s) {
  final regex = RegExp(r"\s\b|\b\s");
  return regex.hasMatch(s);
}

bool isPunctuation(String s) {
  final regex = RegExp(r'[^\w\s]+');
  return regex.hasMatch(s);
}

bool isUnknown(String s) {
  return !(isNumeric(s) && isAlphabetical(s) && isPhrase(s) && isPunctuation(s));
}
