/**
 * @description       : 
 * @author            : jamesperram@gmail.com
 * @group             : 
 * @last modified on  : 03-01-2025
 * @last modified by  : jamesperram@gmail.com
**/
public with sharing class DuplicateLeadHandler {
    
    @AuraEnabled(cacheable=true)
    public static List<Lead> getPotentialDuplicateLeads(String lastName, String industry) {
        // Check for read access to the Lead object
        if (!Schema.sObjectType.Lead.isAccessible()) {
            throw new SecurityException('User does not have read access to Lead records.');
        }

        // Normalize the input and add wildcards
        String searchLastName = '%' + (lastName != null ? lastName.trim() : '') + '%';
        String searchIndustry = '%' + (industry != null ? industry.trim() : '') + '%';

        // Query only matching LastName field
        return [
            SELECT Id, FirstName, LastName, Industry, CreatedDate, Email, Phone
            FROM Lead
            WHERE LastName LIKE :searchLastName
            AND Industry LIKE :searchIndustry
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static List<Lead> updateLeadRecords(List<Lead> updatedLeads) {
        // Validate CRUD permissions for the Lead object
        if (!Schema.sObjectType.Lead.isUpdateable()) {
            throw new SecurityException('User does not have update access to Lead records.');
        }
        
        // Check if the required fields are populated (e.g., 'FirstName', 'LastName', 'Industry')
        for (Lead lead : updatedLeads) {
            if (String.isEmpty(lead.FirstName) || String.isEmpty(lead.LastName) || String.isEmpty(lead.Industry)) {
                throw new AuraHandledException('Required fields are missing: FirstName, LastName, and/or Industry.');
            }
        }

        try {
            // Perform the update operation
            update updatedLeads; 
            return updatedLeads; // Return the updated leads
        } catch (DmlException e) {
            // Catch DML exceptions and log the error message
            String errorMessage = 'Error updating records: ' + e.getMessage();
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        } catch (Exception e) {
            // Catch any other unexpected exceptions
            String errorMessage = 'Unexpected error: ' + e.getMessage();
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        }
    }

    @AuraEnabled
    public static void mergeLeads(Id masterRecordId, List<Id> duplicateRecordIds, Map<String, Id> fieldSelections) {
        // Validate permissions
        if (!Schema.sObjectType.Lead.isMergeable()) {
            throw new AuraHandledException('Insufficient permissions to merge leads');
        }

        try {
            // Query for all leads involved in the merge
            List<Lead> allLeads = [
                SELECT Id, Description 
                FROM Lead 
                WHERE Id = :masterRecordId 
                OR Id IN :duplicateRecordIds
            ];

            // Prepare the concatenated description
            String masterDescription = '';
            for (Lead lead : allLeads) {
                if (lead.Description != null) {
                    if (lead.Id == masterRecordId) {
                        // Put master record description first
                        masterDescription = lead.Description + '\n\n';
                    } else {
                        // Add merged record descriptions
                        masterDescription += 'Merged from ' + lead.Id + ':\n' + 
                                          lead.Description + '\n\n';
                    }
                }
            }

            // Update master record with concatenated description
            Lead masterLead = new Lead(
                Id = masterRecordId,
                Description = masterDescription.trim()
            );
            update masterLead;

            // Perform the merge
            merge masterLead duplicateRecordIds;

        } catch (Exception e) {
            String errorMessage = 'Error during merge: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, errorMessage);
            throw new AuraHandledException(errorMessage);
        }
    }
}
