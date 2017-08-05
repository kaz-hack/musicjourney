/*
 * Arduino - Processingシリアル通信
 * Firmataを使用
 * Processing側
 */

////////mp3ファイル制御/////////
import ddf.minim.*;  // minimライブラリのインポート
Minim minim;         // Minim型変数であるminimの宣言
AudioPlayer player;  // サウンドデータ格納用の変数
///////////////////////////

////////processing-arduino通信////////
import processing.serial.*;
import cc.arduino.*;
Arduino arduino;
///////////////////////////////////////////

////////analogread////////
//Arduinoポート番号
final int portNum = 15;
//port番号
int analogPort0 = 0;
int analogPort1 = 1;
int analogPort2 = 2;
//読み出した値
int analog0 = 0;
int analog1 = 0;
int analog1Back1 = 0;
int analog1Back2 = 0;
int analog1Back3 = 0;
int analog2 = 0;
int pastAnalog0 = 0;
int pastAnalog1 = 0;
int pastAnalog2 = 0;
///////////////////////////////////////////

////////描画・再生変数////////
//レコード盤の回転
int hrzRcdAngVal = 0;
float recordDeg = 0;
float recordRad = 0;
float recordDegreeStep = 3.5; //rad/レコード盤の回転信号
//針の回転数
int verNdlAngVal = 0;
float needleDeg = 0;
float needleRad = 0;
float needleDegreeStep = 0.254; //rad/レコード針の回転信号
//針のON/OFF
int needleStatus = 0;
///////////////////////////////////////////

////////描画・再生定数////////
//山手線
int yamanoteLineDia;
color yamanoteLineCol;
int yamanoteLineAlpha = 255;

//総武線
color sobuLineCol;
int sobuLineAlpha = 255;

//丸ノ内線
float marunouchiLinePara1, marunouchiLinePara2, marunouchiLinePara3, 
  marunouchiLinePara4, marunouchiLinePara5, marunouchiLinePara6, 
  marunouchiLinePara7, marunouchiLinePara8, marunouchiLinePara9, 
  marunouchiLinePara10, marunouchiLinePara11, marunouchiLinePara12, 
  marunouchiLinePara13, marunouchiLinePara14, marunouchiLinePara15;
color marunouchiLineCol;
int marunouchiLineAlpha = 255;

//千代田線
float chiyodaLinePara1, chiyodaLinePara2, chiyodaLinePara3, 
  chiyodaLinePara4, chiyodaLinePara5, chiyodaLinePara6;
color chiyodaLineCol;
int chiyodaLineAlpha = 255;

//銀座線
float ginzaLinePara1, ginzaLinePara2, ginzaLinePara3, 
  ginzaLinePara4, ginzaLinePara5, ginzaLinePara6, 
  ginzaLinePara7;
color ginzaLineCol;
int ginzaLineAlpha = 255;

//東西線
float tozaiLinePara1, tozaiLinePara2, tozaiLinePara3, 
  tozaiLinePara4, tozaiLinePara5, tozaiLinePara6, 
  tozaiLineDia;
color tozaiLineCol;
int tozaiLineAlpha = 255;

//南北線
float nanbokuLinePara1, nanbokuLinePara2, nanbokuLinePara3, 
  nanbokuLinePara4, nanbokuLinePara5, nanbokuLinePara6;
color nanbokuLineCol;
int nanbokuLineAlpha = 255;

//路線色の指定
void setCol() {
  yamanoteLineCol = color(90, 65, 79);
  sobuLineCol = color(52, 80, 92);
  marunouchiLineCol = color(2, 89, 89);
  chiyodaLineCol = color(152, 99, 65);
  ginzaLineCol = color(41, 100, 95);
  tozaiLineCol = color(198, 99, 90);
  nanbokuLineCol = color(170, 100, 67);
}

//setAlpha用変数/////////////////////
int yamanoteTag, sobuTag, marunouchiTag, chiyodaTag, ginzaTag, tozaiTag, nanbokuTag;
int dim = 80;
///////////////////////////////////////////

/////stationクラス配列//////////
station[] Station = {};
int chosenNum;
///////////////////////////////

//////物理空間とpixelとの対応付け
//物理空間
float _recordDiameter = 30; //直径30cm
float _needleAxisX = 14.7; //針の軸は中心から右に14.7cm
float _needleAxisY = 7.5; //針の軸は中心から上に7.5cm
float _needleLength = 17; //針は17cm

//px単位
float needleAxisX, needleAxisY, needleTipX, needleTipY, rotNeedleTipX, rotNeedleTipY;
////////////////////////////////


void setup() {
  //size(640, 640);
  fullScreen(P2D); //works well on pc

  println(height+","+width);
  //ウィンドウ位置
  //surface.setLocation(1080,0);

  //色
  colorMode(HSB, 360, 100, 100);
  blendMode(ADD);
  background(0);

  //線
  strokeWeight(10);
  noFill();
  smooth(2);

  //数値計算
  setCol();
  calcParam();

  //Minim初期化
  minim = new Minim(this);

  //station配列作成
  makeStationArray();

  for (int i=0; i<Station.length; i++) {
    println("Station["+i+"]:("+Station[i].x+","+Station[i].y+")");
  }

  //最初は東京駅
  chosenNum = 0;
  //Station[0].choTag = 1;
  setTag(chosenNum);

  player = minim.loadFile(Station[0].songName);
  //player.play();

  
  //port番号に注意
   println(Arduino.list()[portNum]);
   arduino = new Arduino(this, Arduino.list()[portNum], 57600);
  
}

void draw() {
  background(0);
  
   //arduino値読み出し
   analog0 = arduino.analogRead(analogPort0);
   //println("analog0:"+analog0);
   analog1Back3 = analog1Back2;
   analog1Back2 = analog1Back1;
   analog1Back1 = analog1;
   int analog1tmp = arduino.analogRead(analogPort1);
   if(analog1tmp-analog1Back1>1||analog1tmp-analog1Back2<-1){
     analog1 = analog1tmp;
   }
   //println("analog1:"+analog1);
   analog2 = arduino.analogRead(analogPort2);
   //println("analog2:"+analog2);
   //角度の初期化
   if(keyPressed == true){
   if(key == 's'){
     println("set!");
     hrzRcdAngVal = analog1;
     verNdlAngVal = analog2;
     }
   }
   
   //レコード盤の回転角の取得
   recordDeg = recordDegreeStep * (analog1-hrzRcdAngVal);
   recordRad = radians(recordDeg);
   //println("recordDeg:"+recordDeg);
   
   //針の回転角の取得
   needleDeg = needleDegreeStep * (analog2-verNdlAngVal);
   needleRad = radians(needleDeg);
   //println("needleDeg"+needleDeg);
   
   //針のON/OFF
   if(analog0<950){
     needleStatus = 1;
   }else{
     needleStatus = 0;
   }
   //println("needleStatus:"+needleStatus);
  
  //recordDeg = mouseX;
  //needleDeg = mouseY;
  //recordRad = radians(recordDeg);
  //needleRad = radians(needleDeg);
  
  pushMatrix();
  translate(width/2, height/2);
  rotate(recordRad); // 座標軸を回転
  /*
  //キーボード→針とレコード盤の回転角を用いる
  if (keyPressed == true) {
    if (key == 'c') {
      println("pressed!");
      int tmpX = mouseX-width/2;
      int tmpY = mouseY-height/2;
      println(tmpX+","+tmpY);
      for (int i=0; i<Station.length; i++) {
        println("dist(tmp,"+i+"):"+dist(Station[i].x, Station[i].y, tmpX, tmpY));
        if (dist(Station[i].x, Station[i].y, tmpX, tmpY)<20) {
          //音楽ファイルの停止
          player.close();
          //選択インスタンスの切り替え
          chosenNum = i;
          //音楽ファイルの再生
          player = minim.loadFile(Station[i].songName);
          player.play();
        }
      }
    }
  }
  */
  setTag(chosenNum);
  //透過値を変更
  setAlpha();
  
  //レコード盤の描画
  ellipse(0,0,height,height);
  
  //地図の描画
  drawMap();
  //駅の描画
  stroke(255);
  for (int i=0; i<Station.length; i++) {
    Station[i].drawMe();
  }

  //レコード針の位置計算
  calcNeedlePx();
  
  /*
  stroke(0,100,100);
  ellipse(needleAxisX, needleAxisY, 10, 10);
  stroke(120,100,100);
  ellipse(needleTipX, needleTipY, 10, 10);
  */
  //レコードの先端部分の描画
  stroke(240,100,100);
  ellipse(rotNeedleTipX, rotNeedleTipY, 10, 10);
  
  //音楽ファイルの再生
  if(needleStatus == 1){
    //println("rotNeedleTip):"+rotNeedleTipX+","+rotNeedleTipY);
    for (int i=0; i<Station.length; i++) {
      if (dist(Station[i].x, Station[i].y, rotNeedleTipX, rotNeedleTipY)<40) {
        println("play music!"+analog0);
        int chosenNumTmp = i;
        if(chosenNum != chosenNumTmp){
          //音楽ファイルの停止
          player.close();
          //選択インスタンスの切り替え
          chosenNum = i;
          //音楽ファイルの再生
          player = minim.loadFile(Station[i].songName);
          player.play();
        }
      }
    }
  }
          
  popMatrix();
}

void drawMap() {
  //山手線描画
  stroke(yamanoteLineCol, yamanoteLineAlpha);
  ellipse(0, 0, yamanoteLineDia, yamanoteLineDia);

  //総武線描画
  stroke(sobuLineCol, sobuLineAlpha);
  line(-width/2, 0, width/2, 0);

  //丸ノ内線描画
  stroke(marunouchiLineCol, marunouchiLineAlpha);
  line(-marunouchiLinePara1, 10, -marunouchiLinePara2, 10); //値は決め打ち
  arc(0, 0, marunouchiLinePara9, marunouchiLinePara9, HALF_PI, PI-radians(8));
  line(0, marunouchiLinePara2, 0, marunouchiLinePara3);
  line(0, marunouchiLinePara3, marunouchiLinePara4, marunouchiLinePara3);
  arc(marunouchiLinePara4, marunouchiLinePara5, marunouchiLinePara6, marunouchiLinePara6, -HALF_PI, HALF_PI);
  line(marunouchiLinePara4, marunouchiLinePara7, marunouchiLinePara2, marunouchiLinePara7);
  line(marunouchiLinePara2, marunouchiLinePara7, marunouchiLinePara2, -marunouchiLinePara15);
  arc(marunouchiLinePara13, marunouchiLinePara14, marunouchiLinePara2, marunouchiLinePara2, -HALF_PI, 0);
  line(marunouchiLinePara12, -marunouchiLinePara10, -marunouchiLinePara10, -marunouchiLinePara10);

  //千代田線描画
  stroke(chiyodaLineCol, chiyodaLineAlpha);
  line(-width/2, chiyodaLinePara1, chiyodaLinePara4, chiyodaLinePara1);
  arc(chiyodaLinePara4, chiyodaLinePara2, chiyodaLinePara5, chiyodaLinePara5, -HALF_PI, HALF_PI);
  line(chiyodaLinePara4, chiyodaLinePara3, chiyodaLinePara6, chiyodaLinePara3);
  line(chiyodaLinePara6, chiyodaLinePara3, chiyodaLinePara6, -height/2);

  //銀座線描画
  stroke(ginzaLineCol, ginzaLineAlpha);
  line(-ginzaLinePara1, ginzaLinePara1, ginzaLinePara2, ginzaLinePara1);
  arc(ginzaLinePara2, marunouchiLinePara5, ginzaLinePara3, ginzaLinePara3, -HALF_PI, HALF_PI);
  arc(ginzaLinePara2, ginzaLinePara5, ginzaLinePara6, ginzaLinePara6, HALF_PI, 3*PI/2);
  line(ginzaLinePara2, ginzaLinePara7, width/2, ginzaLinePara7);

  //東西線描画
  stroke(tozaiLineCol, tozaiLineAlpha);
  line(-width/2, -tozaiLinePara1, 0, -tozaiLinePara1);
  arc(0, 0, tozaiLinePara2, tozaiLinePara2, -HALF_PI, 0);
  arc(tozaiLinePara3, 0, tozaiLineDia, tozaiLineDia, HALF_PI, PI);
  line(tozaiLinePara3, tozaiLinePara4, width/2, tozaiLinePara4);

  //南北線描画
  stroke(nanbokuLineCol, nanbokuLineAlpha);
  line(0, -height/2, 0, -nanbokuLinePara1);
  arc(0, 0, nanbokuLinePara2, nanbokuLinePara2, HALF_PI, 3*HALF_PI);
  line(0, nanbokuLinePara1, nanbokuLinePara3, nanbokuLinePara1);
  line(nanbokuLinePara3, nanbokuLinePara1, nanbokuLinePara3, nanbokuLinePara4);
  arc(0, nanbokuLinePara4, nanbokuLinePara5, nanbokuLinePara5, 0, HALF_PI);
  line(0, nanbokuLinePara6, -120, nanbokuLinePara6);
}

void calcParam() {
  yamanoteLineDia = 3*height/4;

  //丸ノ内線
  marunouchiLinePara1 = yamanoteLineDia/2;
  marunouchiLinePara2 = 2*yamanoteLineDia/9;
  marunouchiLinePara3 = 3*yamanoteLineDia/10;
  marunouchiLinePara7 = yamanoteLineDia/12;
  marunouchiLinePara10 = sqrt(2)*yamanoteLineDia/4;

  marunouchiLinePara4 = sqrt(35)*marunouchiLinePara7;
  marunouchiLinePara5 = (marunouchiLinePara3+marunouchiLinePara7)/2;
  marunouchiLinePara6 = marunouchiLinePara3-marunouchiLinePara7;
  marunouchiLinePara8 = sqrt(yamanoteLineDia*yamanoteLineDia/4-marunouchiLinePara2*marunouchiLinePara2);
  marunouchiLinePara9 = marunouchiLinePara2*2;
  marunouchiLinePara11 = marunouchiLinePara10*2;
  marunouchiLinePara12 = marunouchiLinePara2/2;
  marunouchiLinePara13 = marunouchiLinePara2 - marunouchiLinePara12;
  marunouchiLinePara14 = -marunouchiLinePara10 + marunouchiLinePara12;
  marunouchiLinePara15 = marunouchiLinePara10 - marunouchiLinePara12;

  //千代田線
  chiyodaLinePara1 = yamanoteLineDia/4;
  chiyodaLinePara3 = yamanoteLineDia/12+20;

  chiyodaLinePara4 = sqrt(3)*chiyodaLinePara1;
  chiyodaLinePara2 = (chiyodaLinePara1+chiyodaLinePara3)/2;
  chiyodaLinePara5 = chiyodaLinePara1-chiyodaLinePara3;
  chiyodaLinePara6 = chiyodaLinePara1+20;

  //銀座線
  ginzaLinePara1 = sqrt(2)*yamanoteLineDia/4;

  ginzaLinePara2 = marunouchiLinePara4 - ginzaLinePara1 + marunouchiLinePara3+10;
  ginzaLinePara3 = (ginzaLinePara1 - marunouchiLinePara5)*2;
  ginzaLinePara4 = marunouchiLinePara5 - ginzaLinePara3/2;
  ginzaLinePara5 = (ginzaLinePara4 -marunouchiLinePara2)/2;
  ginzaLinePara6 = ginzaLinePara4 + marunouchiLinePara2;
  ginzaLinePara7 = ginzaLinePara5- ginzaLinePara6/2;

  //東西線
  tozaiLinePara1 = yamanoteLineDia/5;
  tozaiLineDia = 60; 

  tozaiLinePara2 = tozaiLinePara1 * 2;
  tozaiLinePara3 = tozaiLinePara1+tozaiLineDia/2;
  tozaiLinePara4 = tozaiLineDia/2;

  //南北線
  nanbokuLinePara1 = yamanoteLineDia/5-10;
  nanbokuLinePara3 = 40;
  nanbokuLinePara4 = sqrt(2)*yamanoteLineDia/4;

  nanbokuLinePara2 = nanbokuLinePara1*2;
  nanbokuLinePara5 = nanbokuLinePara3*2;
  nanbokuLinePara6 = nanbokuLinePara4 + nanbokuLinePara3;
}

void readArduino() {
  analog0 = arduino.analogRead(analogPort0);
  analog1 = arduino.analogRead(analogPort1);
  analog2 = arduino.analogRead(analogPort2);
  /*
  println("analog0:"+analog0);
   println("analog1:"+analog1);
   println("analog2:"+analog2);
   */
}

void makeStationArray() {
  //東京駅
  station tokyo = new station(marunouchiLinePara4, marunouchiLinePara7, 
    1, 0, 1, 0, 0, 0, 0, 
    "tokyo.mp3");
  station akihabara = new station(yamanoteLineDia/2, 0, 
    1, 1, 0, 0, 0, 0, 0, 
    "akihabara.mp3");
  station ikebukuro = new station(-marunouchiLinePara10, -marunouchiLinePara10, 
    1, 0, 1, 0, 0, 0, 0, 
    "ikebukuro.mp3");
  station shinjuku = new station(-yamanoteLineDia/2, 0, 
    1, 1, 1, 0, 0, 0, 0, 
    "shinjuku.mp3");
  station harajuku = new station(-chiyodaLinePara4, chiyodaLinePara1, 
    1, 0, 0, 1, 0, 0, 0, 
    "harajuku.mp3");
  station shibuya = new station(-ginzaLinePara1, ginzaLinePara1, 
    1, 0, 0, 0, 1, 0, 0, 
    "shibuya.mp3");
  station ochanomizu = new station(chiyodaLinePara1, 0, 
    0, 1, 1, 1, 0, 0, 0, 
    "ochanomizu.mp3");
  station asagaya = new station((-yamanoteLineDia/2)-50, 0, 
    0, 1, 0, 0, 0, 0, 0, 
    "asagaya.mp3");
  station ginza = new station(marunouchiLinePara4+marunouchiLinePara6/2, marunouchiLinePara5, 
    0, 0, 1, 0, 1, 0, 0, 
    "ginza.mp3");
  station nogizaka = new station(-chiyodaLinePara4+50, chiyodaLinePara1, 
    0, 0, 0, 1, 0, 0, 0, 
    "nogizaka.mp3");
  station omotesandou = new station(-chiyodaLinePara4+100, chiyodaLinePara1, 
    0, 0, 0, 1, 1, 0, 0, 
    "omotesandou.mp3");
  station asakusa = new station(width/2-50, ginzaLinePara7, 
    0, 0, 0, 0, 1, 0, 0, 
    "asakusa.mp3");
  Station = (station[])append(Station, tokyo);
  Station = (station[])append(Station, akihabara);
  Station = (station[])append(Station, ikebukuro);
  Station = (station[])append(Station, shinjuku);
  Station = (station[])append(Station, harajuku);
  Station = (station[])append(Station, shibuya);
  Station = (station[])append(Station, ochanomizu);
  Station = (station[])append(Station, asagaya);
  Station = (station[])append(Station, ginza);
  Station = (station[])append(Station, nogizaka);
  Station = (station[])append(Station, omotesandou);
  Station = (station[])append(Station, asakusa);
}

void setTag(int stationNum) {
  yamanoteTag = Station[stationNum].yTag;
  sobuTag = Station[stationNum].sTag;
  marunouchiTag = Station[stationNum].mTag;
  chiyodaTag = Station[stationNum].cTag;
  ginzaTag = Station[stationNum].gTag;
  tozaiTag = Station[stationNum].tTag;
  nanbokuTag = Station[stationNum].nTag;
}

void setAlpha() {
  if (yamanoteTag == 1) {
    yamanoteLineAlpha = 255;
  } else {
    yamanoteLineAlpha = dim;
  }
  if (sobuTag == 1) {
    sobuLineAlpha = 255;
  } else {
    sobuLineAlpha = dim;
  }
  if (marunouchiTag == 1) {
    marunouchiLineAlpha = 255;
  } else {
    marunouchiLineAlpha = dim;
  }
  if (chiyodaTag == 1) {
    chiyodaLineAlpha = 255;
  } else {
    chiyodaLineAlpha = dim;
  }
  if (ginzaTag == 1) {
    ginzaLineAlpha = 255;
  } else {
    ginzaLineAlpha = dim;
  }
  if (tozaiTag == 1) {
    tozaiLineAlpha = 255;
  } else {
    tozaiLineAlpha = dim;
  }
  if (nanbokuTag == 1) {
    nanbokuLineAlpha = 255;
  } else {
    nanbokuLineAlpha = dim;
  }
}

void calcNeedlePx() {
  //heightがレコード盤の直径と一致しているという仮定
  /*
  _recordDiameter
   _needleAxisX
   _needleAxisY
   _needleLength
   needleAxisX, needleAxisY, needleTipX, needleTipY, rotNeedleTipX, rotNeedleTipY;
   */

  needleAxisX = height * _needleAxisX / _recordDiameter;
  needleAxisY = -(height * _needleAxisY / _recordDiameter);
  needleTipX = needleAxisX - (17 * sin(-needleRad) / 30) * height;
  needleTipY = needleAxisY + (17 * cos(-needleRad) / 30) * height;
  rotNeedleTipX = cos(-recordRad) * needleTipX - sin(-recordRad) * needleTipY;
  rotNeedleTipY = sin(-recordRad) * needleTipX + cos(-recordRad) * needleTipY;
  /*
  println("needleAxisX:"+needleAxisX);
  println("needleAxisY:"+needleAxisY);
  println("needleTipX:"+needleTipX);
  println("needleTipY:"+needleTipY);
  println("rotNeedleTipX:"+rotNeedleTipX);
  println("rotNeedleTipY:"+rotNeedleTipY);
  */
}

class station {
  float x, y;
  int yTag, sTag, mTag, cTag, gTag, tTag, nTag;
  String songName; 

  //public int choTag;

  station(float _x, float _y, 
    int _yTag, int _sTag, int _mTag, int _cTag, int _gTag, int _tTag, int _nTag, 
    String _songName) {
    x = _x;
    y = _y;
    yTag = _yTag;
    sTag = _sTag;
    mTag = _mTag;
    cTag = _cTag;
    gTag = _gTag;
    tTag = _tTag;
    nTag = _nTag;
    songName = _songName;
    //choTag = 0;
  }

  void drawMe() {
    if ((yamanoteTag == 1 && yTag == 1) || (sobuTag == 1 && sTag == 1) ||
      (marunouchiTag == 1 && mTag == 1) || (chiyodaTag == 1 && cTag == 1) ||
      (ginzaTag == 1 && gTag == 1) || (tozaiTag == 1 && tTag == 1) ||
      (nanbokuTag == 1 && nTag == 1)) {
      ellipse(x, y, 30, 30);
    }
  }
}