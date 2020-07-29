/* Used to convert the response from the Health Check API Call */
public class SecurityHealthCheckJSONParser {
  public Integer size { get; set; }
  public Integer totalSize { get; set; }
  public Boolean done { get; set; }
  public Object queryLocator { get; set; }
  public String entityTypeName { get; set; }
  public List<Records> records { get; set; }

  public SecurityHealthCheckJSONParser(JSONParser parser) {
    while (parser.nextToken() != System.JSONToken.END_OBJECT) {
      if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
        String text = parser.getText();
        if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
          if (text == 'size') {
            size = parser.getIntegerValue();
          } else if (text == 'totalSize') {
            totalSize = parser.getIntegerValue();
          } else if (text == 'done') {
            done = parser.getBooleanValue();
          } else if (text == 'queryLocator') {
            queryLocator = parser.readValueAs(Object.class);
          } else if (text == 'entityTypeName') {
            entityTypeName = parser.getText();
          } else if (text == 'records') {
            records = arrayOfRecords(parser);
          } else {
            consumeObject(parser);
          }
        }
      }
    }
  }

  public class Attributes {
    public String type_Z { get; set; } // in json: type
    public String url { get; set; }

    public Attributes(JSONParser parser) {
      while (parser.nextToken() != System.JSONToken.END_OBJECT) {
        if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
          String text = parser.getText();
          if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
            if (text == 'type') {
              type_Z = parser.getText();
            } else if (text == 'url') {
              url = parser.getText();
            } else {
              consumeObject(parser);
            }
          }
        }
      }
    }
  }

  public class Records {
    public Attributes attributes { get; set; }
    public String CustomBaselineId { get; set; }
    public String DurableId { get; set; }
    public String Score { get; set; }

    public Records(JSONParser parser) {
      while (parser.nextToken() != System.JSONToken.END_OBJECT) {
        if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
          String text = parser.getText();
          if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
            if (text == 'attributes') {
              attributes = new Attributes(parser);
            } else if (text == 'CustomBaselineId') {
              CustomBaselineId = parser.getText();
            } else if (text == 'DurableId') {
              DurableId = parser.getText();
            } else if (text == 'Score') {
              Score = parser.getText();
            } else {
              consumeObject(parser);
            }
          }
        }
      }
    }
  }

  public static SecurityHealthCheckJSONParser parse(String json) {
    System.JSONParser parser = System.JSON.createParser(json);
    return new SecurityHealthCheckJSONParser(parser);
  }

  public static void consumeObject(System.JSONParser parser) {
    Integer depth = 0;
    do {
      System.JSONToken curr = parser.getCurrentToken();
      if (curr == System.JSONToken.START_OBJECT || curr == System.JSONToken.START_ARRAY) {
        depth++;
      } else if (curr == System.JSONToken.END_OBJECT || curr == System.JSONToken.END_ARRAY) {
        depth--;
      }
    } while (depth > 0 && parser.nextToken() != null);
  }

  private static List<Records> arrayOfRecords(System.JSONParser p) {
    List<Records> res = new List<Records>();
    if (p.getCurrentToken() == null)
      p.nextToken();
    while (p.nextToken() != System.JSONToken.END_ARRAY) {
      res.add(new Records(p));
    }
    return res;
  }

  // Sample Payload
  /* {
 "size" : 1,
 "totalSize" : 1,
 "done" : true,
 "queryLocator" : null,
 "entityTypeName" : "SecurityHealthCheck",
 "records" : [ {
   "attributes" : {
     "type" : "SecurityHealthCheck",
     "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheck/0"
   },
   "CustomBaselineId" : "0",
   "DurableId" : "0",
   "Score" : "61"
 } ]
} */
}
