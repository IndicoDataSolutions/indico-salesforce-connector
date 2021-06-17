global class MockWorkflowSubmissionResponseGenerator implements HttpCalloutMock {
    private Integer workflowId;
    private String fileName;
    private String contentType;

    public MockWorkflowSubmissionResponseGenerator(Integer workflowId, String fileName, String contentType) {
        this.workflowId = workflowId;
        this.fileName = fileName;
        this.contentType = contentType;
    }

    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('callout:IndicoToken/Submissions?workflowId='+ this.workflowId, req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        String body = req.getBody();
        System.assert(0 < body.indexOf('Content-Disposition: form-data; name="document"; filename="' + this.fileName + '"'), 'Invalid Content-Disposition: ' + body);
        System.assert(0 < body.indexOf('Content-Type: ' + this.contentType), 'Invalid Content-Type: ' + body);

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('123');
        res.setStatusCode(200);
        return res;
    }
}
