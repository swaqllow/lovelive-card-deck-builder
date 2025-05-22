enum Rarity {
  n,      // Normal
  r,      // Rare
  rplus,   // Rare Plus
  p,       // Parallel
  pplus,   // Parallel Plus
  sre,    // Super Rare Energy
  pe,   // Parallel Energy
  peplus, // Parallel Energy Plus
  l,      // Live
  lle,   // love Live Energy
  sec,   // Specret
  secpls, // Specret Plus
  sece,   // Specret Energy
  pr,    // PR
  sd;     // Structured Deck
 
  
  // レアリティの数値を取得
  int get value {
    switch (this) {
      case Rarity.n:
        return 1;
      case Rarity.r:
        return 2;
      case Rarity.rplus:
        return 3;
      case Rarity.p:
        return 4;
      case Rarity.pplus:
        return 5; 
      case Rarity.sre:
        return 6; // Rと同等
      case Rarity.pe:
        return 7; 
      case Rarity.peplus:
        return 8; 
      case Rarity.l:
        return 9;
      case Rarity.lle:
        return 10; // Rと同等
      case Rarity.sec:
        return 11; // Rと同等
      case Rarity.secpls:
        return 12; // Rと同等
      case Rarity.sece:
        return 13; // Rと同等     
      case Rarity.pr:
        return 14; // Rと同等
      case Rarity.sd:
        return 15; // Rと同等 
    }
  }
}

extension RarityExtension on Rarity {
  String get displayName {
    switch (this) {
      case Rarity.n:
        return 'N';
      case Rarity.r:
        return 'R';
      case Rarity.rplus:
        return 'R+';
      case Rarity.p:
        return 'P';
      case Rarity.pplus:
        return 'P+';
      case Rarity.sre:
        return 'SR-E';
      case Rarity.pe:
        return 'P-E';
      case Rarity.peplus:
        return 'P-E+'; 
      case Rarity.l:
        return 'L';  
      case Rarity.lle:
        return 'L-E';
      case Rarity.sec:
        return 'SEC';
      case Rarity.secpls:
        return 'SEC+';            
      case Rarity.sece:
        return 'SEC-E';
      case Rarity.pr:
        return 'PR';
      case Rarity.sd:
        return 'SD';      
    }
  }
  
  String get fullName {
    switch (this) {
      case Rarity.n:
        return 'Normal';
      case Rarity.r:
        return 'Rare';
      case Rarity.rplus:
        return 'Rare Plus';  
      case Rarity.p:
        return 'Parallel';
      case Rarity.pplus:
        return 'Parallel Plus';
      case Rarity.sre:
        return 'Super Rare Energy';
      case Rarity.pe:
        return 'Parallel Energy';
      case Rarity.peplus:
        return 'Parallel Energy Plus';    
      case Rarity.l:
        return 'Live';
      case Rarity.lle:
        return 'Love Live Energy';
      case Rarity.sec:
        return 'Secret';
      case Rarity.secpls:
        return 'Secret Plus';
      case Rarity.sece:
        return 'Secret Energy';
      case Rarity.pr:
        return 'PR';
      case Rarity.sd:
        return 'Structured Deck';
    }
  }
  
  
  // 文字列からRarityを取得するstaticメソッド
  static Rarity fromString(String rarityStr) {
    switch (rarityStr.toUpperCase()) {
      case 'N':
        return Rarity.n;
      case 'R':
        return Rarity.r;
      case 'R+':
        return Rarity.rplus;  
      case 'P':
        return Rarity.p;
      case 'P+':
        return Rarity.pplus;
      case 'SR-E':
        return Rarity.sre;
      case 'P-E':
        return Rarity.pe;
      case 'P-E+':
        return Rarity.peplus;
      case 'L':
        return Rarity.l;
      case 'L-E':
        return Rarity.lle;
      case 'SEC':
        return Rarity.sec;
      case 'SEC+':
        return Rarity.secpls;
      case 'SEC-E': 
        return Rarity.sece;
      case 'PR':
        return Rarity.pr; 
      case 'SD':
        return Rarity.sd;
      default:
        return Rarity.n; // デフォルト値
    }
  }
}