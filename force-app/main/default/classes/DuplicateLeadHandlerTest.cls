@isTest
private class DuplicateLeadHandlerTest {


@IsTest
    static void testGetPotentialDuplicateLeads() {
        // Create test data
        Lead lead1 = new Lead(
            LastName = 'Smith',
            Industry = 'Technology'
        );
        Lead lead2 = new Lead(
            LastName = 'Smith',
            Industry = 'Technology'
        );
        insert new List<Lead>{lead1, lead2};

        // Call the method
        Test.startTest();
        List<Lead> result = DuplicateLeadHandler.getPotentialDuplicateLeads('Smith', 'Technology');
        Test.stopTest();

        // Assert the results
        System.assertEquals(2, result.size(), 'Expected 2 leads');
        System.assertEquals('Smith', result[0].LastName, 'Unexpected LastName');
        System.assertEquals('Technology', result[0].Industry, 'Unexpected Industry');
    }


@IsTest
    static void testUpdateLeadRecordsSuccess() {
        // Create test data
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Industry = 'Technology'
        );
        insert lead;

        // Call the method
        Test.startTest();
        DuplicateLeadHandler.updateLeadRecords(new List<Lead>{lead});
        Test.stopTest();

        // Assert the result
        Lead updatedLead = [SELECT Id, FirstName, LastName, Industry FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('John', updatedLead.FirstName);
        System.assertEquals('Doe', updatedLead.LastName);
        System.assertEquals('Technology', updatedLead.Industry);
    }

@IsTest
    static void testMergeLeadsSuccess() {
        // Create test data
        Lead masterLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Description = 'Master Lead'
        );
        insert masterLead;

        List<Lead> duplicateLeads = new List<Lead>();
        for (Integer i = 1; i <= 3; i++) {
            duplicateLeads.add(new Lead(
                FirstName = 'John',
                LastName = 'Doe',
                Description = 'Duplicate Lead ' + i
            ));
        }
        insert duplicateLeads;

        // Create field selections
        Map<String, Id> fieldSelections = new Map<String, Id>();
        for (Schema.SObjectField field : Schema.SObjectType.Lead.fields.getMap().values()) {
            fieldSelections.put(field.getDescribe().getName(), masterLead.Id);
        }

        // Call the method
        Test.startTest();
        DuplicateLeadHandler.mergeLeads(masterLead.Id, new List<Id>(new Map<Id, Lead>(duplicateLeads).keySet()), fieldSelections);
        Test.stopTest();

        // Assert the result
        List<Lead> mergedLeads = [SELECT Id, FirstName, LastName, Description FROM Lead WHERE Id = :masterLead.Id];
        System.assertEquals(1, mergedLeads.size(), 'Merged leads size should be 1');
        System.assertEquals('John', mergedLeads[0].FirstName, 'Merged lead FirstName should be "John"');
        System.assertEquals('Doe', mergedLeads[0].LastName, 'Merged lead LastName should be "Doe"');
        System.assert(mergedLeads[0].Description.contains('Master Lead'), 'Merged lead Description should contain "Master Lead"');
        System.assert(mergedLeads[0].Description.contains('Duplicate Lead'), 'Merged lead Description should contain "Duplicate Lead"');
    }
}