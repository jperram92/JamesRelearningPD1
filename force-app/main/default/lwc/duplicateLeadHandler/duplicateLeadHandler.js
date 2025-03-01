import { LightningElement, track } from 'lwc';
import getPotentialDuplicateLeads from '@salesforce/apex/DuplicateLeadHandler.getPotentialDuplicateLeads';

export default class HandleDuplicateLeads extends LightningElement {
    @track duplicates = [];
    lastName = '';
    industry = '';

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
}
