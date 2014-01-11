import 'dart:html';

TextAreaElement plaintextArea; // Where we type our plaintext
TextAreaElement ciphertextArea; // Where we type our ciphertext
InputElement cipherKey; // Where we type our cipherKey
Square square; // Our Square object

/**
 * Set our event listeners and textarea placeholders
 */
void main() {
  plaintextArea = (querySelector("#plaintextArea") as TextAreaElement)
      ..placeholder = "Put your plaintext to be encrypted here"
      ..onKeyUp.listen(preCrypt);
  
  ciphertextArea = (querySelector("#ciphertextArea") as TextAreaElement)
      ..placeholder = "Put your ciphertext to be decrypted here"
      ..onKeyUp.listen(preCrypt);
  
  cipherKey = (querySelector("#cipherKey") as InputElement)
      ..placeholder = "Playfair Key here"
      ..onKeyUp.listen(changeKey)
      ..onBlur.listen(upperCaseKey);
  
  square = new Square("");
}

/**
 * Event-triggered encryption, the event listener for both plaintext and
 * ciphertext.
 * Only parameter is an event handler, which is used to decide what direction we're going.
 */
void preCrypt(Event e){
  bool encrypt;
  TextAreaElement targetArea;
  TextAreaElement originalArea;
  
  if(e.target == querySelector("#plaintextArea")){
    // This is done when we're typing in the plaintext area
    originalArea = querySelector("#plaintextArea");
    targetArea = querySelector("#ciphertextArea");
    encrypt = true;
  } else {
    // This is done when we're typing in the ciphertext area
    originalArea = querySelector("#ciphertextArea");
    targetArea = querySelector("#plaintextArea");
    encrypt = false;
  }
  
  // Force the typed-in area to be all-caps
  originalArea.value = originalArea.value.toUpperCase();
  crypt(originalArea, targetArea, encrypt);
}

/**
 * Does our actual encryption/decryption.
 * @param TextAreaElement originalArea - Where we take our original text from
 * @param TextAreaElement targetArea - Where our processed text goes to
 * @param bool encrypt - This tells us whether we're encrypting or decrypting from original to target
 */
void crypt(TextAreaElement originalArea, TextAreaElement targetArea, bool encrypt){
  if(originalArea == querySelector("#ciphertextArea") && (originalArea.value.length % 2 == 1)){
    // Do nothing if we're typing in the ciphertext area and we've got an odd number of characters
  } else if(!originalArea.value.isEmpty){
    // Sanitize! Alphabetical characters only!
    var original = originalArea.value.toUpperCase().replaceAll(new RegExp(r"[^a-zA-Z]*"), '');
    String targetStr = '';

    // Loop for the length of the string, incrementing by two
    for(var i = 0; i < original.length; i = i + 2){
      // If our second letter is nonexistant, our original is odd-length
      if(i + 2 > original.length){
        original = original + "Z"; // So we stick a Z at the end
      }
      String firstLetter = original[i];
      String secondLetter = original[i + 1];
      
      if(firstLetter == secondLetter){ // If this digraph's letters match, insert an X
        original = original.substring(0, i + 1) + "X" + original.substring(i+1);
      }
      // Encrypt/decrypt our pair
      targetStr = targetStr + square.cryptPair(original[i] + original[i + 1], encrypt);
    }
    targetArea.value = targetStr;
  } else {
    // This is to allow for empty input fields to be updated
    targetArea.value = "";
  }
}

/**
 * Event-triggered change of the playfair key 
 */
void changeKey(Event e){
  square = new Square(cipherKey.value);
  crypt(querySelector("#plaintextArea"),querySelector("#ciphertextArea"),true);
}

/**
 * Event-triggered change of the key field to uppercase on-blur
 */
void upperCaseKey(Event e){
  (e.target as InputElement).value = (e.target as InputElement).value.toUpperCase();
}

/**
 * Class that manages the Playfair encryption-square
 */
class Square {
  List alphabet = new List();
  List columns = new List();
  List rows = new List();
  
  /**
   * Creates the columns and rows of the square
   * @param String key The key for the newly-generated square. This allows you to call new Square("newkey")
   */
  Square(String key){
    for(var i = 0; i < 5; i++){
      columns.add(new List());
      rows.add(new List());
    }
    this.generate(key);
  }
  
  /**
   * Generates the string anew. Call this anytime the key is changed
   * @param String key The key we're generating a square from
   */
  void generate(String key){
    String newKey = key.toUpperCase();
    var playfairKey = newKey.replaceAll(new RegExp(r'j'),'i').replaceAll(new RegExp(r'J'), 'I') + "ABCDEFGHIKLMNOPQRSTUVWXYZ";
    print("Key is " + newKey);
    this.alphabet = new List();
    for(var i = 0; i < playfairKey.length; i++){
      if(!this.alphabet.contains(playfairKey[i])){
        this.alphabet.add(playfairKey[i]);
      }
    }
    
    int count = 0;
    for(var j = 0; j < this.alphabet.length; j++){
      if(((j/5) % 1) == 0.0){
        count++;
      }
      columns[j % 5].add(this.alphabet[j]);
      rows[count - 1].add(this.alphabet[j]);
    }
  }
  
  /**
   * Encrypts or decrypts a pair of characters using the generated square
   */
  String cryptPair(String pair, bool encrypt){
    int direction = (encrypt) ? 1 : -1 ;
    String letter1 = pair[0];
    String letter2 = pair[1];
    int l1Row = this.getRow(letter1);
    int l1Col = this.getColumn(letter1);
    int l2Row = this.getRow(letter2);
    int l2Col = this.getColumn(letter2);
    String newLetter1;
    String newLetter2;
    
    if(l1Row == l2Row){
      newLetter1 = this.getLetterAt(l1Row,(5 + (l1Col + direction)) % 5);
      newLetter2 = this.getLetterAt(l2Row, (5 + (l2Col + direction)) % 5);
    } else if(l1Col == l2Col) {
      newLetter1 = this.getLetterAt((5 +(l1Row + direction)) % 5, l1Col);
      newLetter2 = this.getLetterAt((5 +(l2Row + direction)) % 5, l2Col);
    } else {
      newLetter1 = this.getLetterAt(l1Row, l2Col);
      newLetter2 = this.getLetterAt(l2Row, l1Col);
    }
    return newLetter1 + newLetter2;
  }
  
  /**
   * Get the row of a particular letter in the generated square
   */
  int getRow(String letter){
    int letterpos = -1;
    int count = 0;
    do{
      letterpos = (this.rows[count] as List).contains(letter) ? count : -1;
      count++;
    } while(letterpos < 0);
    return letterpos;
  }

  /**
   * Get the columns of a particular letter in the generated square
   */
  int getColumn(String letter){
    int letterpos = -1;
    int count = 0;
    do{
      letterpos = (this.columns[count] as List).contains(letter) ? count : -1;
      count++;
    } while(letterpos < 0);
    return letterpos;
  }
  
  /**
   * Retrieves the letter at a position in the square
   */
  String getLetterAt(int row, int column){
    return this.rows[row][column];
  }
}