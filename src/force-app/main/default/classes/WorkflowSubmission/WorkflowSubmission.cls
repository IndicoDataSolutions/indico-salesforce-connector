global with sharing class WorkflowSubmission {
    global class Params {
        @InvocableVariable(required=true)
        public Integer WorkflowId;

        @InvocableVariable(required=true)
        public Id DocumentVersionId;
    }

    @InvocableMethod(label='Submit workflow' description='Submit workflow' category= 'Indico')
    public static List<string> submit(List<Params> params) {
        List<string> outputs = new List<string>();
        
        for (Params p:params) {
            String output = submitSingle(p);
            outputs.add(output);
        }

        return outputs;
    }

    public static String submitSingle(Params param)
    {
        ContentVersion toSend = [SELECT VersionData, Title, FileType, FileExtension FROM ContentVersion WHERE Id = :param.DocumentVersionId][0];
        String response = send(toSend, param.WorkflowId);

        return response;
    }

    private static String send(ContentVersion file, Integer workflowId) {
        String contentBase64 = EncodingUtil.base64Encode(file.VersionData);
        String fileName = file.Title + '.' + file.FileExtension;
        String contentType = getContentType(file.FileExtension);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:IndicoToken/Submissions?workflowId=' + workflowId);
        req.setHeader('Content-Type','multipart/form-data; boundary=-----------------------------153501500631101');
        req.setMethod('POST');

        System.debug('Sending file ' + fileName + ' to workflowId ' + workflowId);

        String body = '-------------------------------153501500631101\r\n';
        body = body + 'Content-Disposition: form-data; name="document"; filename="' + fileName + '"\r\n';
        body = body + 'Content-Type: ' + contentType + '\r\n';
        body = body + 'Content-transfer-encoding: base64\r\n\r\n';
        body = body + contentBase64 + '\r\n';
        body = body + '-------------------------------153501500631101--\r\n';

        req.setBody(body);
        req.setTimeout(60*1000);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new WorkflowSubmissionException(res.getBody());
        }

        String responseBody = res.getBody();
        System.debug(responseBody);

        return responseBody;
    }

    private static Map<String, String> extensionToContentTypeMap = new Map<String, String> { 
        'png' => 'image/png', 
        'jpeg' => 'image/jpeg', 
        'jpg' => 'image/jpg',
        'txt' => 'text/plain',
        'csv' => 'text/csv'
    };

    private static string getContentType(String extension) {
        extension = extension.toLowerCase();
        String contentType = extensionToContentTypeMap.get(extension);

        if (contentType == null) {
            contentType = 'application/' + extension;
        }

        return contentType;
    }

    private class WorkflowSubmissionException extends Exception { }
}
