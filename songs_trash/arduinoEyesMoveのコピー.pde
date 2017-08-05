/*
 * Arduino - Processingシリアル通信
 * Firmataを使用
 * Processing側
 */

////////processing-arduino通信////////
import processing.serial.*;
import cc.arduino.*;
Arduino arduino;
///////////////////////////////////////////

////////analogread////////
int analog0 = 0;
int analog1 = 0;
int pastAnalog0 = 0;
int pastAnalog1 = 0;
///////////////////////////////////////////


////////画像処理////////
PImage img;
float radian;
float degrees=0;
float pot0Step = 3.516525;
///////////////////////////////////////////

int input0 = 0;
int input1 = 1;

ArrayList<Eye> eyes = new ArrayList<Eye>(); //array to hold the eyes
static final int minsize = 50, maxsize = 400, density = 1000; //minsize and maxsize are thr minimum and maximum sizes for the eyes, density is how many times the program will try to find a place for a new eye before it gives up
static final float distance = 1; // 1 = no distance; 0 = infinite distance;

void setup() {
  //size(640, 360);
  fullScreen(P2D); //works well on pc
  smooth(8);
  noStroke();
  int f = 0;
  while (f < density){
    int x = (int)random(width), y = (int)random(height); //random x an y
    int size = min(maxsize, min(x, width - x), min(y, height - y)); //size is the biggest size you can fit in the eye's place
    for (int i = 0; i < eyes.size(); i++){
      int d = (int)sqrt(pow((eyes.get(i).x - x), 2) + pow((eyes.get(i).y - y), 2)) - eyes.get(i).size/2; //checks every other eye position to find the biggest size possible
      size = min(size, d);
    }
    
    if (size >= minsize){ //if the eye is bigger then the minimum size
      eyes.add(new Eye(x, y, (int)(2*distance*size), color(random(255), random(255), random(255))));
    }else{f++;}
  }
  //port番号に注意
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[9], 57600);
}

void draw() {
  analog0 = arduino.analogRead(input0);
  analog1 = arduino.analogRead(input1);
  float theta = radians(3600 * analog0 / 1024);
  mouseX= (int)(1000 * cos(theta));
  mouseY= (int)(1000 * sin(theta));
  
  background(0);
  
  for (int i = 0;   i < eyes.size(); i++){
    eyes.get(i).update(mouseX, mouseY);
  }
  
  for (int i = 0; i < eyes.size(); i++){
    eyes.get(i).display(mouseX, mouseY);
  }
  
}

class Eye {
  int x, y;
  int size;
  float angle = 0.0;
  color c;
  
  Eye(int tx, int ty, int ts, color tc) {
    x = tx;
    y = ty;
    size = ts;
    c = tc;
 }

  void update(int mx, int my) {
    angle = atan2(my-y, mx-x);
  }
  
  void display(int mx, int my) {
    pushMatrix();
    translate(x, y);
    fill(255);
    ellipse(0, 0, size, size);
    if (sqrt(pow((mx-x), 2)+pow((my-y), 2)) > size/2 - size/4) {
      rotate(angle);
      fill(c);
      ellipse(size/4, 0, size/2, size/2);
    }else{ //in case the mouse is over the eye
      fill(c);
      ellipse(mx - x, my - y, size/2, size/2);
    }
    popMatrix();
  }
}