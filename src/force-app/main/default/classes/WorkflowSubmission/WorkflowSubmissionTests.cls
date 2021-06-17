@isTest
private class WorkflowSubmissionTests {
    private static Integer workflowId = 14;

    @isTest static void submit_shouldSendCorrectCreateSubmission() {
        // Arrange
        String fileName = 'test file';
        String fileExtension = '.txt';
        Test.setMock(HttpCalloutMock.class, new MockWorkflowSubmissionResponseGenerator(workflowId, fileName + fileExtension, 'text/plain'));

        WorkflowSubmission.Params params = new WorkflowSubmission.Params();
        params.DocumentVersionId = createDocumentVersion(fileName, fileName + fileExtension);
        params.WorkflowId = workflowId;

        // Act
        Test.startTest();
        String output = WorkflowSubmission.submit(new List<WorkflowSubmission.Params> { params })[0];
        Test.stopTest();

        // Assert
        Integer submissionId = Integer.valueOf(output);
        System.assert(submissionId > 0, 'Cannot create workflow submission.');
    }
    
    @isTest static void submit_shouldCorrectlyMapContentType() {
        // Arrange
        Map<String, String> extensionToContentTypeMap = new Map<String, String> { 
            'png' => 'image/png', 
            'jpeg' => 'image/jpeg', 
            'jpg' => 'image/jpg',
            'pdf' => 'application/pdf',
            'txt' => 'text/plain',
            'csv' => 'text/csv'
        };
        String fileName = 'test';
        Map<Id, String> verIdToExtensionMap = new Map<Id, String>();

        for (String fileExtension : extensionToContentTypeMap.keySet()) {
            verIdToExtensionMap.put(createDocumentVersion(fileName, fileName + '.' + fileExtension), fileExtension);
        }

        // Act
        Test.startTest();
        for (Id contentVersionId : verIdToExtensionMap.keySet()) {
            String fileExtension = verIdToExtensionMap.get(contentVersionId);
            String expectedContentType = extensionToContentTypeMap.get(fileExtension);
            WorkflowSubmission.Params params = new WorkflowSubmission.Params();
            params.DocumentVersionId = contentVersionId;
            params.WorkflowId = workflowId;
            
            Test.setMock(HttpCalloutMock.class, new MockWorkflowSubmissionResponseGenerator(workflowId, fileName + '.' + fileExtension, expectedContentType));

            String submissionId = WorkflowSubmission.submit(new List<WorkflowSubmission.Params> { params })[0];
            
            // Assert
            // mock is verifying content type
        }

        Test.stopTest();
    }

    private static Id createDocumentVersion(String title, String pathOnClient) {
        ContentVersion ver = new ContentVersion();
        ver.ContentLocation = 'S';
        ver.PathOnClient = pathOnClient;
        ver.Title = title;
        ver.VersionData = Blob.valueof('File content.');

        insert ver;
        
        return ver.Id;
    }
}
