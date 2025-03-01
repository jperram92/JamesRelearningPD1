/**
 * @description       : 
 * @author            : jamesperram@gmail.com
 * @group             : 
 * @last modified on  : 03-01-2025
 * @last modified by  : jamesperram@gmail.com
**/
public with sharing class DuplicateAccountHandler {

    @AuraEnabled(cacheable=true)
    public static List<DuplicateRecordSet> getPotentialDuplicates(String accountName, String accountEmail) {
        // Query DuplicateRecordSet for the Account
        return [SELECT Id, Status, (SELECT Id, RecordId, DuplicateRuleId, ObjectName, CreatedDate
                                    FROM DuplicateRecords)
                FROM DuplicateRecordSet 
                WHERE ObjectName = 'Account'
                AND Status = 'Matching'
                AND RecordId IN (SELECT Id FROM Account WHERE Name = :accountName AND Email = :accountEmail)];
    }
}
