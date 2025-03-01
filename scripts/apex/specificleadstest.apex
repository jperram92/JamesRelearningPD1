/**
 * @description       : 
 * @author            : jamesperram@gmail.com
 * @group             : 
 * @last modified on  : 03-01-2025
 * @last modified by  : jamesperram@gmail.com
**/
// Create a list of Lead records to insert
List<Lead> testLeads = new List<Lead>();

// Create leads with fields that match in some cases and differ in others
testLeads.add(new Lead(
    FirstName = 'John',
    LastName = 'Doe',
    Industry = 'Technology',
    Email = 'john.doe@example.com',
    Phone = '123-456-7890',
    Description = 'Lead for technology industry'
));

testLeads.add(new Lead(
    FirstName = 'John',
    LastName = 'Incomplete',  // Different Last Name to test merging
    Industry = 'Retail',      // Different Industry to test merging
    Email = 'incomplete.last@example.com',  // Different Email to test merging
    Phone = '123-456-7896',  // Different Phone to test merging
    Description = 'Incomplete data lead for testing'
));

testLeads.add(new Lead(
    FirstName = 'John',
    LastName = 'Doe',
    Industry = 'Technology', // Same Industry
    Email = 'john.doe.duplicate@example.com', // Different Email
    Phone = '123-456-7893', // Different Phone
    Description = 'Duplicate lead for testing'
));

testLeads.add(new Lead(
    FirstName = 'John',
    LastName = 'Doe',
    Industry = 'Technology', // Same Industry
    Email = 'john.doe@example.com',  // Same Email
    Phone = '123-456-7890',  // Same Phone
    Description = 'Master lead for merging'
));

// Insert the Leads into Salesforce
insert testLeads;

// Output confirmation in debug log
System.debug('Test Leads inserted successfully!');
