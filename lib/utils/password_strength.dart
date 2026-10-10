/// Kriteria kekuatan password: minimal 8 karakter, mengandung huruf besar,
/// huruf kecil, angka, DAN karakter spesial (bukan huruf/angka).
final RegExp _upperReg = RegExp(r'[A-Z]');
final RegExp _lowerReg = RegExp(r'[a-z]');
final RegExp _digitReg = RegExp(r'[0-9]');
final RegExp _specialReg = RegExp(r'[^A-Za-z0-9]');

bool isStrongPassword(String password) {
  return password.length >= 8 &&
      _upperReg.hasMatch(password) &&
      _lowerReg.hasMatch(password) &&
      _digitReg.hasMatch(password) &&
      _specialReg.hasMatch(password);
}