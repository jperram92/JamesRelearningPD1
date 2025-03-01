import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPotentialDuplicateLeads from '@salesforce/apex/DuplicateLeadHandler.getPotentialDuplicateLeads';
import updateLeadRecords from '@salesforce/apex/DuplicateLeadHandler.updateLeadRecords';
import mergeLeads from '@salesforce/apex/DuplicateLeadHandler.mergeLeads';

export default class HandleDuplicateLeads extends LightningElement {
    @track modalOpen = false;
    @track selectedLead = {};
    @track isLoading = false;
    @api recordId;
    
    @track selectedRows = [];
    @track masterRecord = null;
    @track showMergeModal = false;
    @track preparedRows = [];
    @track mergeFieldRows = [];
    @track mergeSelections = {};
    @track selectedMasterId;
    @track duplicates = [];

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
        { type: 'button-icon', typeAttributes: {
            iconName: 'utility:check',
            name: 'select',
            title: 'Select Record',
            variant: 'border-filled',
            alternativeText: 'Select'
        }},
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Industry', fieldName: 'Industry' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
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

        if (actionName === 'select') {
            const index = this.selectedRows.findIndex(selectedRow => selectedRow.Id === row.Id);
            
            if (index === -1) {
                // Add row if not already selected
                if (this.selectedRows.length < 3) {
                    this.selectedRows = [...this.selectedRows, row];
                    this.masterRecord = this.selectedRows[0]; // Set first selected as master
                    this.selectedMasterId = this.masterRecord.Id;
                    this.showToast('Success', 'Record selected for merge', 'success');
                } else {
                    this.showToast('Warning', 'You can only select up to 3 records for merging', 'warning');
                }
            } else {
                // Remove row if already selected
                this.selectedRows = this.selectedRows.filter(selectedRow => selectedRow.Id !== row.Id);
                if (this.selectedRows.length > 0) {
                    this.masterRecord = this.selectedRows[0];
                    this.selectedMasterId = this.masterRecord.Id;
                } else {
                    this.masterRecord = null;
                    this.selectedMasterId = null;
                }
            }
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

    // Add these getter methods
    get isMergeDisabled() {
        return !this.selectedRows || this.selectedRows.length < 2;
    }

    get isMergeConfirmDisabled() {
        return !this.masterRecord || this.selectedRows.length < 2;
    }

    get mergeFields() {
        return [
            { label: 'First Name', fieldName: 'FirstName' },
            { label: 'Last Name', fieldName: 'LastName' },
            { label: 'Industry', fieldName: 'Industry' },
            { label: 'Email', fieldName: 'Email' },
            { label: 'Phone', fieldName: 'Phone' }
        ];
    }

    // Add these methods to handle merge functionality
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    // Add this method to get field value
    getFieldValue(lead, fieldApiName) {
        return lead[fieldApiName] || '--None--';
    }

    // Modify handleMergeClick to prepare the radio options
    handleMergeClick() {
        if (this.selectedRows.length < 2) {
            this.showToast('Error', 'Please select at least 2 records to merge', 'error');
            return;
        }

        // Set the first selected record as master by default
        this.masterRecord = this.selectedRows[0];
        this.selectedMasterId = this.masterRecord.Id;

        // Prepare merge fields data
        this.mergeFieldRows = this.mergeFields.map(field => ({
            label: field.label,
            fieldName: field.fieldName,
            selectedValue: this.selectedMasterId,
            options: this.selectedRows.map(lead => ({
                label: `${lead.FirstName} ${lead.LastName}: ${this.getFieldValue(lead, field.fieldName)}`,
                value: lead.Id
            }))
        }));

        this.showMergeModal = true;
    }

    getOptionsForField(lead, fieldName) {
        return lead.options && lead.options[fieldName] ? lead.options[fieldName] : [];
    }

    handleMergeModalClose() {
        this.showMergeModal = false;
    }

    handleFieldSelection(event) {
        const selectedValue = event.detail.value;
        const fieldRow = this.mergeFieldRows.find(row => row.fieldName === event.target.name);
        if (fieldRow) {
            fieldRow.selectedValue = selectedValue;
        }
    }

    handleMergeConfirm() {
        const fieldSelections = {};
        this.mergeFieldRows.forEach(row => {
            fieldSelections[row.fieldName] = row.selectedValue;
        });

        this.isLoading = true;
        mergeLeads({
            masterRecordId: this.selectedMasterId,
            duplicateRecordIds: this.selectedRows
                .filter(row => row.Id !== this.selectedMasterId)
                .map(row => row.Id),
            fieldSelections
        })
        .then(() => {
            this.showToast('Success', 'Leads merged successfully', 'success');
            this.handleMergeModalClose();
            return this.handleSearch();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Error merging leads', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleClearSelection() {
        this.selectedRows = [];
        this.masterRecord = null;
        this.selectedMasterId = null;
    }

    get isClearDisabled() {
        return this.selectedRows.length === 0;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
