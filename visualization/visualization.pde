import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.text.ParseException;
import java.text.SimpleDateFormat;

// resolution
int canvasW = 4800;
int canvasH = 600;

// data
ArrayList<Message> messages;
JSONArray messages_json_array;
String messages_file = "../output/texts_2015-03-31_2015-07-11.json";
int total_messages = 0;

ArrayList<Category> categories;
JSONArray categories_json_array;
String categories_file = "../data/categories.json";

// time
float total_seconds = 0;

// space
float message_proportion = 0.5;
float message_width = 0;
float message_height = 0.5 * canvasH;
float total_silence_width = 1.0 * canvasW * (1 - message_proportion);
float max_message_height = message_height;
float min_message_height = message_height * 0.2;
int max_message_length = 0;
int min_message_length = 999999;

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  background(10);
  smooth();
  noStroke();
  noFill();
  noLoop();
  
  // load category data
  categories = new ArrayList<Category>();
  categories_json_array = loadJSONArray(categories_file);
  for (int i = 0; i < categories_json_array.size(); i++) {
    JSONObject category_json = categories_json_array.getJSONObject(i);
    categories.add(new Category(category_json));
  }

  // load message data
  messages = new ArrayList<Message>();
  messages_json_array = loadJSONArray(messages_file);
  for (int i = 0; i < messages_json_array.size(); i++) {
    JSONObject message_json = messages_json_array.getJSONObject(i);
    messages.add(new Message(message_json, categories));
    max_message_length = max(max_message_length, messages.get(i).getLength());
    min_message_length = min(min_message_length, messages.get(i).getLength());
  }
  
  // time and space calculation
  total_messages = messages.size();
  message_width = message_proportion * canvasW / total_messages;
  total_seconds = messages.get(total_messages-1).timeSince(messages.get(0).getDate());
}

void draw(){
  float x = 0;
  
  for(int i=0; i<total_messages; i++) {
    Message m = messages.get(i);
    float y = message_height;
    float direction = 1;
    
    // move forward silence amount
    if (i > 0) {
      float seconds_since = m.timeSince(messages.get(i-1).getDate());
      x += seconds_since / total_seconds * total_silence_width;
    }
    
    
    
    // determine message height
    float amount = 1.0 * (m.getLength() - min_message_length) / (max_message_length - min_message_length);
    float total_h = lerp(min_message_height, max_message_height, amount);
    float y_step = total_h / m.getCategories().size();
    
    // check if 1st person
    if (m.getPerson() <= 1) {
      direction = -1;
      y -= y_step;
    }
    
    for(Category c : m.getCategories()) {
      fill(c.getColor());
      rect(x, y, message_width, y_step);
      y += (y_step * direction);
    }
    x += message_width;
    
    
  }

}

void mousePressed() {
  saveFrame("output.png");
  exit();
}

class Category
{
  String myName;
  color myColor;

  Category(JSONObject _category) {
    myName = _category.getString("name");
    String colorString = _category.getString("color");
    colorString = "FF" + colorString.substring(1);
    myColor = unhex(colorString);
  }
  
  color getColor() {
    return myColor;
  }
  
  boolean matches(String name) {
    return myName.equals(name);
  }

}

class Message
{
  Date myDate;
  String myBody;
  int myPerson;
  ArrayList<Category> myCategories;

  Message(JSONObject _message, ArrayList<Category> _categories) {
    myBody = _message.getString("body");
    myPerson = _message.getInt("person");
    
    SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.ENGLISH);
    String dateString = _message.getString("date");
    
    try{
      myDate = df.parse(dateString);
    } catch(ParseException e){
      println(e);
    }
    
    myCategories = new ArrayList<Category>();
    JSONArray _categories_json_array = _message.getJSONArray("categories");
    for (int i = 0; i < _categories_json_array.size(); i++) {
      String name = _categories_json_array.getString(i);
      for(Category c : _categories) {
        if (c.matches(name)) {
          myCategories.add(c);
          break; 
        }
      }
    }
  }
  
  ArrayList<Category> getCategories() {
    return myCategories; 
  }
  
  Date getDate() {
    return myDate;
  }
  
  int getLength() {
    return myBody.length();
  }
  
  int getPerson() {
    return myPerson;
  }
  
  float timeSince(Date d) {
    return 1.0 * (myDate.getTime() - d.getTime()) / 1000;
  }

}

