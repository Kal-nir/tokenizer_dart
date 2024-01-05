import 'package:args/args.dart';
import 'dart:io';

/// Tokenizer Dart
/// 
/// A tokenizer made in dart. It has two methods to tokenize, one is the extraction process based on a delimiter.
/// The other is the identification which conducts lexical analysis on what type of token it is. This was 
/// entirely made using Dart with little to no tokenizer library, even a split string method. This was all
/// possible with the use of the token data structure and regular expressions.
/// 
/// Author: Jonas and Gwyn

// Note: This test case: "Hello! World! Hello World! Hello World !\nTest!,!" has two possible outcomes.
// One outcome is for the entered string in the dart file and the text file, while the other is the CLI outcome.
// The first outcome recognizes \nTest as separate, while the other outcome recognizes the other as a one.
// This is due to the fact that the terminal in general has different code for a new line and not applicable directly to
// the program.

/// TokenType Enumeration
/// 
/// This makes sure that tokens are properly categorized. This also ensures a proper
/// development quality.
enum TokenType {
  word, punctuation, phrase, number, empty, eol, eof, unkown,
}

/// Token Data Structure
/// 
/// This contains the necessary data types on what makes a token a token. Also contains a 
/// simple toString() method when printed as a string.
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

/// Tokens List Variable
/// 
/// This is a global variable that contains all processed and identified tokens.
/// Essesntially the collection of all tokens that was created from a string.
List<Token> tokens = [];

/// The Main Method
/// 
/// Uses an args parser for a CLI frontend. This also outputs
/// the tokens that was processed and identified.
void main(List<String> arguments) {
  ArgParser parser = ArgParser();
  
  parser.addOption('string', abbr: 's', defaultsTo: "Hello, world!");
  parser.addOption('preprocess', abbr: 'p', defaultsTo: 'true');
  parser.addOption('usingfile', abbr: 'f', defaultsTo: 'false');
  parser.addOption('filename', abbr: 'n', defaultsTo: '');
 
  ArgResults results = parser.parse(arguments);

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

/// Extract
/// 
/// This extracts the tokens from the string through a for loop method. It loops every character
/// checking for a delimiter or an end line. And collects it in the currentToken variable.
/// Once a delimiter is found, the currentToken is then recorded, trimmed, and create a new token upon
/// its value. Then the new token is put on the list to be then outputted. Note that the tokens are 
/// not yet identified.
List<Token> extract(String string, {bool preprocess = true, bool usingFile = false}) {
  List<Token> rawTokens = [];
  String currentToken = "";
  int currentRow = 0;
  int currentCol = 0;

  for (int rune in string.runes) {
    String char = String.fromCharCode(rune);
    
    if (char == "\n") {
      rawTokens.add(
        Token("eol", TokenType.eol, currentRow, currentCol)
      );
      currentRow = 0;
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

/// Identify
/// 
/// This loops through the entire token list that was provided as an argument.
/// And uses other methods to check whether or not they're a certain token or not.
/// If they are, they are classified as is. The loop is a bit faster now considering 
/// it only loops the tokens, and not every character. Making it an efficient way of 
/// identification.
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

/// changeType
/// 
/// This is a utility method that enables a one liner statement for the identification method.
bool changeType(bool condition, Token token, TokenType type) {
  if (condition) {
    token.type = type;
    return true;
  }
  return false;
}

/// isNumeric
/// 
/// Checks whether the string provided is a number or not based on the given regex.
bool isNumeric(String s) {
  final regex = RegExp(r'^-?(([0-9]*)|(([0-9]*)\.([0-9]*)))$');
  return regex.hasMatch(s);
}

/// isAlphabetical
/// 
/// Checks whether the string provided is a word or word with punctuation based on the given regex.
bool isAlphabetical(String s) {
  final wordAlone = RegExp(r'^[a-zA-Z]+$');
  final withPunctuation = RegExp(r"(?<=\s|^|\b)(?:[-'.%$#&\/]\b|\b[-'.%$#&\/]|[A-Za-z0-9]|\([A-Za-z0-9]+\))+(?=\s|$|\b)");
  return wordAlone.hasMatch(s) || withPunctuation.hasMatch(s);
}

/// isPhrase
/// 
/// Checks whether the string is a phrase or not if it contains a lot of spaces or not.
bool isPhrase(String s) {
  final regex = RegExp(r"\s\b|\b\s");
  return regex.hasMatch(s);
}

/// isPunctuation
/// 
/// Checks whether it the string is a punctation or not.
bool isPunctuation(String s) {
  final regex = RegExp(r'[^\w\s]+');
  return regex.hasMatch(s);
}

/// isUnknown
/// 
/// If all else fails, it will be identified as unknown.
bool isUnknown(String s) {
  return !(isNumeric(s) && isAlphabetical(s) && isPhrase(s) && isPunctuation(s));
}
