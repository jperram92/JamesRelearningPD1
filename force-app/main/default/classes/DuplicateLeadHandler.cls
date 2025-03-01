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

        // Normalize the input (make it case-insensitive and remove leading/trailing spaces)
        String normalizedLastName = lastName != null ? lastName.trim().toLowerCase() : '';
        String normalizedIndustry = industry != null ? industry.trim().toLowerCase() : '';

        // Query Leads that have the same last name and industry (case-sensitive, to be compared in Apex)
        List<Lead> leads = [
            SELECT Id, FirstName, LastName, Industry, CreatedDate
            FROM Lead
            WHERE LastName != null
                AND Industry != null
                AND LastName != ''
                AND Industry != ''
            LIMIT 100
        ];

        // Prepare the list for duplicate leads
        List<Lead> duplicateLeads = new List<Lead>();

        // Check for potential duplicates by comparing the fields in Apex (case-insensitive)
        for (Lead l : leads) {
            if (l.LastName != null && l.Industry != null) {
                // Normalize the lead's LastName and Industry to lowercase for case-insensitive comparison
                String leadLastName = l.LastName.trim().toLowerCase();
                String leadIndustry = l.Industry.trim().toLowerCase();

                // Compare the normalized values (checking if either lastName or industry matches)
                if (leadLastName == normalizedLastName || leadIndustry == normalizedIndustry) {
                    duplicateLeads.add(l);
                }
            }
        }

        // Return the potential duplicate leads
        return duplicateLeads;
    }

    @AuraEnabled
    public static List<Lead> updateLeadRecords(List<Lead> updatedLeads) {
        // Validate CRUD permissions for the Lead object
        if (!Schema.sObjectType.Lead.isUpdateable()) {
            throw new SecurityException('User does not have update access to Lead records.');
        }

        try {
            update updatedLeads; // Perform the update operation
            return updatedLeads; // Return the updated leads
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }
}
