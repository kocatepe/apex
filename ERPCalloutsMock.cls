@isTest
global class ERPCalloutsMock implements HttpCalloutMock {
    global Integer numCallouts = 0;
    global HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        numCallouts++;
        //Assert.areEqual(1, Limits.getCallouts());
        return response;
    }
}