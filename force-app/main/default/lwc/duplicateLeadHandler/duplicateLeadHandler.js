import { LightningElement, track } from 'lwc';
import getPotentialDuplicateLeads from '@salesforce/apex/DuplicateLeadHandler.getPotentialDuplicateLeads';
import updateLeadRecords from '@salesforce/apex/DuplicateLeadHandler.updateLeadRecords'; // Apex method to update records

export default class HandleDuplicateLeads extends LightningElement {
    @track duplicates = [];
    @track modalOpen = false;
    selectedLead = {};
    lastName = '';
    industry = '';
    
    columns = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Industry', fieldName: 'Industry' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Edit', name: 'edit', iconName: 'utility:edit' }
                ]
            }
        }
    ];

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleIndustryChange(event) {
        this.industry = event.target.value;
    }

    handleSearch() {
        getPotentialDuplicateLeads({ lastName: this.lastName, industry: this.industry })
            .then(result => {
                this.duplicates = result;
                console.log('Duplicates found: ', result); // Debug log
                if (this.duplicates.length === 0) {
                    alert('No duplicates found.');
                }
            })
            .catch(error => {
                console.error('Error fetching duplicates:', error);
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('Row action clicked:', actionName); // Debug log

        if (actionName === 'edit') {
            console.log('Editing row:', row); // Debug log
            this.selectedLead = { ...row }; // Copy the row data into selectedLead
            this.modalOpen = true; // Open the modal
        }
    }

    handleModalClose() {
        this.modalOpen = false; // Close the modal
    }

    handleInputChange(event) {
        const field = event.target.name;
        this.selectedLead[field] = event.target.value;
    }

    handleSave() {
        const updatedLeads = [this.selectedLead]; // Prepare the updated lead

        updateLeadRecords({ updatedLeads })
            .then(result => {
                console.log('Updated records:', result);
                this.handleModalClose(); // Close the modal after save
                this.handleSearch(); // Refresh the data
            })
            .catch(error => {
                console.error('Error saving updated leads:', error);
            });
    }
}
