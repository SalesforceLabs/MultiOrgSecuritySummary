@isTest
public with sharing class SecurityHealthCheckServiceMockFactory implements HttpCalloutMock {
  protected List<HttpResponse> orderedResponses = new List<HttpResponse>();

  public SecurityHealthCheckServiceMockFactory(Integer code, String status, String bodyAsString, Map<String, String> headers) {
    HttpResponse res = new HttpResponse();
    res.setStatusCode(code);
    res.setStatus(status);
    res.setBody(bodyAsString);
    for (String headerKey : headers.keySet()) {
      res.setHeader(headerKey, headers.get(headerKey));
    }
    this.orderedResponses.add(res);
  }

  public SecurityHealthCheckServiceMockFactory(List<HttpResponse> orderedResponses) {
    this.orderedResponses = orderedResponses;
  }

  public HttpResponse respond(HttpRequest req) {
    return this.orderedResponses.remove(0);
  }
}
