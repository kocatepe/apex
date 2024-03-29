@isTest
global class ToolingCalloutMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);

        if(request.getEndpoint().contains('DelegateGroupMember')){
            response.setBody('{"records":[{"UserOrGroupId":"0058e000000000TEST"}]}');
        } else {
            response.setBody('{"records":[{"Id":"02f8e000000000TEST"}]}');
        }

        return response;
    }
}
