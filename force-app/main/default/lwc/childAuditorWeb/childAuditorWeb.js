import { LightningElement, api, track} from 'lwc';

import getData from '@salesforce/apex/ChildAuditorController.getData';

export default class ChildAuditorWeb extends LightningElement {
    @api recordId;
    @track dataList;
    @track error;

    renderedCallback() {
        this.refrashDataGrid();
    }

    refrashDataGrid() {
        getData({ recordId: this.recordId })
            .then(result => {
                this.dataList = result.dataList;
            })
            .catch(error => {
                this.error = error;
                console.log(error);
            })
    }
}