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
        if (!Schema.sObjectType.Lead.isMergeable()) {
            throw new AuraHandledException('Insufficient permissions to merge leads');
        }

        try {
            // Query all leads with necessary fields
            List<Lead> allLeads = [
                SELECT Id, FirstName, LastName, Industry, Email, Phone, Description,
                       Company, Status, Rating, Title
                FROM Lead 
                WHERE Id = :masterRecordId OR Id IN :duplicateRecordIds];

            // Identify master record and duplicates
            Lead masterRecord = null;
            List<Lead> duplicateRecords = new List<Lead>();
            for (Lead lead : allLeads) {
                if (lead.Id == masterRecordId) {
                    masterRecord = lead;
                } else {
                    duplicateRecords.add(lead);
                }
            }

            if (masterRecord == null) {
                throw new AuraHandledException('Master record not found');
            }

            // Build combined description
            String combinedDescription = '';
            if (String.isNotBlank(masterRecord.Description)) {
                combinedDescription = 'Master Record Description:\n' + masterRecord.Description + '\n\n';
            }
            
            for (Lead dupe : duplicateRecords) {
                if (String.isNotBlank(dupe.Description)) {
                    combinedDescription += 'Merged from ' + dupe.FirstName + ' ' + dupe.LastName + ':\n' 
                        + dupe.Description + '\n\n';
                }
            }
            
            // Apply field selections
            for (String fieldName : fieldSelections.keySet()) {
                Id selectedLeadId = fieldSelections.get(fieldName);
                if (selectedLeadId != masterRecord.Id) {
                    for (Lead lead : duplicateRecords) {
                        if (lead.Id == selectedLeadId) {
                            masterRecord.put(fieldName, lead.get(fieldName));
                            break;
                        }
                    }
                }
            }

            // Set the combined description
            if (String.isNotBlank(combinedDescription)) {
                masterRecord.Description = combinedDescription.trim();
            }

            // Perform the merge
            Database.merge(masterRecord, duplicateRecordIds, false);

        } catch (Exception e) {
            throw new AuraHandledException('Error merging leads: ' + e.getMessage());
        }
    }
}
