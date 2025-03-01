/**
 * @description       : 
 * @author            : jamesperram@gmail.com
 * @group             : 
 * @last modified on  : 03-01-2025
 * @last modified by  : jamesperram@gmail.com
**/
// Create a list of Lead records to insert
List<Lead> testLeads = new List<Lead>();

// Valid Leads
testLeads.add(new Lead(
    FirstName = 'John',
    LastName = 'Doe',
    Industry = 'Technology',
    Email = 'john.doe@example.com',
    Phone = '123-456-7890',
    Description = 'Lead for technology industry'
));

testLeads.add(new Lead(
    FirstName = 'Jane',
    LastName = 'Smith',
    Industry = 'Finance',
    Email = 'jane.smith@example.com',
    Phone = '123-456-7891',
    Description = 'Lead for finance industry'
));

testLeads.add(new Lead(
    FirstName = 'Alice',
    LastName = 'Johnson',
    Industry = 'Technology',
    Email = 'alice.johnson@example.com',
    Phone = '123-456-7892',
    Description = 'Lead for technology industry'
));

// Duplicate Leads
testLeads.add(new Lead(
    FirstName = 'John',
    LastName = 'Doe',
    Industry = 'Technology',
    Email = 'john.doe.duplicate@example.com',
    Phone = '123-456-7893',
    Description = 'Duplicate of John Doe, same industry'
));

testLeads.add(new Lead(
    FirstName = 'John',
    LastName = 'Doe',
    Industry = 'Technology',
    Email = 'john.doe2@example.com',
    Phone = '123-456-7894',
    Description = 'Another duplicate of John Doe'
));

// Leads with Missing Required Fields (to simulate errors)
testLeads.add(new Lead(
    FirstName = '',
    LastName = 'MissingFirstName', // LastName added here
    Industry = 'Healthcare',
    Email = 'missing.firstname@example.com',
    Phone = '123-456-7895',
    Description = 'Missing first name'
));

testLeads.add(new Lead(
    FirstName = 'Incomplete',
    LastName = 'LastName', // LastName added here
    Industry = 'Retail',
    Email = 'incomplete.last@example.com',
    Phone = '123-456-7896',
    Description = 'Missing last name'
));

// Leads with null values for parameters (to simulate null parameters)
testLeads.add(new Lead(
    FirstName = null,
    LastName = 'NullLastName', // LastName added here
    Industry = null,
    Email = 'null.param@example.com',
    Phone = '123-456-7897',
    Description = 'Null parameters test'
));

// Insert the Leads into Salesforce
insert testLeads;

// Output confirmation in debug log
System.debug('Test Leads inserted successfully!');
