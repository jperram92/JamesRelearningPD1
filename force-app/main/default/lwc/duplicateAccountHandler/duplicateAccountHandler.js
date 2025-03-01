import { LightningElement, track, wire } from 'lwc';
import getPotentialDuplicates from '@salesforce/apex/DuplicateAccountHandler.getPotentialDuplicates';

export default class HandleDuplicateAccounts extends LightningElement {
    @track duplicates = [];
    accountName = '';
    accountEmail = '';

    handleNameChange(event) {
        this.accountName = event.target.value;
    }

    handleEmailChange(event) {
        this.accountEmail = event.target.value;
    }

    handleSearch() {
        getPotentialDuplicates({ accountName: this.accountName, accountEmail: this.accountEmail })
            .then(result => {
                if (result.length > 0) {
                    // Map the results to handle them
                    this.duplicates = result[0].DuplicateRecords;
                } else {
                    this.duplicates = [];
                    alert('No duplicates found!');
                }
            })
            .catch(error => {
                console.error('Error fetching duplicates:', error);
            });
    }

    handleMerge(event) {
        // Logic to merge the records if needed
        alert('Merging functionality would be implemented here.');
    }

    handleDismiss(event) {
        // Logic to dismiss the duplicate
        alert('Dismissing duplicate functionality would be implemented here.');
    }
}
