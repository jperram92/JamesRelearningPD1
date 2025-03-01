import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPotentialDuplicateLeads from '@salesforce/apex/DuplicateLeadHandler.getPotentialDuplicateLeads';
import updateLeadRecords from '@salesforce/apex/DuplicateLeadHandler.updateLeadRecords';

export default class HandleDuplicateLeads extends LightningElement {
    @track modalOpen = false;
    @track selectedLead = {};
    @track isLoading = false;
    @api recordId;
    
    wiredLeadsResult;
    lastName = '';
    industry = '';
    
    // Replace the duplicates track with wire
    @wire(getPotentialDuplicateLeads, { 
        lastName: '$lastName', 
        industry: '$industry' 
    })
    wiredLeads(result) {
        this.wiredLeadsResult = result;
        if (result.data) {
            this.duplicates = result.data;
        } else if (result.error) {
            this.handleSearchError(result.error);
        }
    }

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
        // Show spinner while loading
        this.dispatchEvent(new CustomEvent('loading'));
        
        getPotentialDuplicateLeads({ lastName: this.lastName, industry: this.industry })
            .then(result => {
                // Create new array reference
                this.duplicates = Array.isArray(result) ? [...result] : [];
                
                if (this.duplicates.length === 0) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Info',
                            message: 'No duplicates found',
                            variant: 'info'
                        })
                    );
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Error fetching duplicates',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
                console.error('Error fetching duplicates:', error);
            })
            .finally(() => {
                // Hide spinner
                this.dispatchEvent(new CustomEvent('doneloading'));
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
        this.selectedLead[field] = event.target.value; // Update selected lead with changes
    }

    handleSave() {
        if (!this.validateFields()) {
            return;
        }

        this.isLoading = true;
        const leadToUpdate = this.prepareLeadForUpdate();

        updateLeadRecords({ updatedLeads: [leadToUpdate] })
            .then(() => {
                this.handleSaveSuccess();
            })
            .catch(error => {
                this.handleSaveError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    validateFields() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        return allValid;
    }

    prepareLeadForUpdate() {
        return {
            Id: this.selectedLead.Id,
            FirstName: this.selectedLead.FirstName,
            LastName: this.selectedLead.LastName,
            Industry: this.selectedLead.Industry
        };
    }

    async handleSaveSuccess() {
        this.modalOpen = false;
        this.showToast('Success', 'Lead updated successfully', 'success');
        
        // Refresh the wired data
        await refreshApex(this.wiredLeadsResult);
        
        this.selectedLead = {};
    }

    handleSaveError(error) {
        this.showToast('Error', error.body?.message || 'Error updating lead', 'error', 'sticky');
        console.error('Error saving lead:', error);
    }

    handleSearchError(error) {
        this.showToast('Error', error.body?.message || 'Error fetching duplicates', 'error', 'sticky');
        console.error('Error fetching duplicates:', error);
    }
}
