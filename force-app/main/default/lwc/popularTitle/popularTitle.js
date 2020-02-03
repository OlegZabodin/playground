import { LightningElement, track } from 'lwc';

export default class PopularTitle extends LightningElement {
    @track handledTitle;

    set title(item) {
        if (item && item.value > 1) {
            this.handledTitle = ' records';
        } else this.handledTitle = ' record';
    }

}