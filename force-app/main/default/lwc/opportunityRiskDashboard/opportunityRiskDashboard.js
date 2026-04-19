import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLatestAssessment from '@salesforce/apex/RiskAssessmentController.getLatestAssessment';
import requestManualAssessment from '@salesforce/apex/RiskAssessmentController.requestManualAssessment';
import hasManualAssessmentPermission from '@salesforce/apex/RiskAssessmentController.hasManualAssessmentPermission';
import LABEL_TIMEOUT from '@salesforce/label/c.Risk_Callout_Timeout';
import LABEL_LOW_RISK from '@salesforce/label/c.Risk_Low_Recommendation';
import LABEL_HIGH_RISK from '@salesforce/label/c.Risk_High_Recommendation';
import LABEL_PENDING from '@salesforce/label/c.Risk_Assessment_Pending';
import LABEL_NO_ASSESS from '@salesforce/label/c.Risk_No_Assessment';
import OPP_NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import OPP_AMOUNT_FIELD from '@salesforce/schema/Opportunity.Amount';

const POLL_INTERVAL_MS = 5000;
const RISK_LEVEL_CSS = {
    Low: 'slds-badge risk-badge risk-badge_low',
    Medium: 'slds-badge risk-badge risk-badge_medium',
    High: 'slds-badge risk-badge risk-badge_high',
    Critical: 'slds-badge risk-badge risk-badge_critical'
};
const SCORE_COLOR = {
    Low: '#4bca81',
    Medium: '#ffb75d',
    High: '#fe9339',
    Critical: '#c23934'
};

export default class OpportunityRiskDashboard extends LightningElement {
    @api recordId;

    @track assessment = null;
    @track isLoading = true;
    @track errorMessage = null;
    @track hasManualPermission = false;
    @track isRequestingAssessment = false;

    labelPending = LABEL_PENDING;
    labelNoAssessment = LABEL_NO_ASSESS;
    labelTimeout = LABEL_TIMEOUT;
    labelLowRisk = LABEL_LOW_RISK;
    labelHighRisk = LABEL_HIGH_RISK;

    _pollTimer = null;

    @wire(getRecord, { recordId: '$recordId', fields: [OPP_NAME_FIELD, OPP_AMOUNT_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data || error) {
            this.fetchAssessment();
        }
    }

    connectedCallback() {
        this.loadPermission();
        this.fetchAssessment();
    }

    disconnectedCallback() {
        this.stopPolling();
    }

    async loadPermission() {
        try {
            this.hasManualPermission = await hasManualAssessmentPermission();
        } catch (e) {
            this.hasManualPermission = false;
        }
    }

    async fetchAssessment() {
        try {
            const result = await getLatestAssessment({ opportunityId: this.recordId });
            this.assessment = result;
            this.errorMessage = null;

            if (result && result.Status__c === 'Pending') {
                this.startPolling();
            } else {
                this.stopPolling();
            }
        } catch (e) {
            this.errorMessage = e.body ? e.body.message : LABEL_TIMEOUT;
            this.stopPolling();
        } finally {
            this.isLoading = false;
        }
    }

    startPolling() {
        if (this._pollTimer) return;
        this._pollTimer = setInterval(() => {
            this.fetchAssessment();
        }, POLL_INTERVAL_MS);
    }

    stopPolling() {
        if (this._pollTimer) {
            clearInterval(this._pollTimer);
            this._pollTimer = null;
        }
    }

    async handleRequestAssessment() {
        this.isRequestingAssessment = true;
        try {
            await requestManualAssessment({ opportunityId: this.recordId });
            this.assessment = { Status__c: 'Pending' };
            this.startPolling();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Assessment Requested',
                message: 'A new risk assessment has been queued.',
                variant: 'success'
            }));
        } catch (e) {
            const msg = (e.body && e.body.message) ? e.body.message : 'Failed to request assessment.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error'
            }));
        } finally {
            this.isRequestingAssessment = false;
        }
    }

    get isError() {
        return !this.isLoading && !!this.errorMessage;
    }

    get isNoAssessment() {
        return !this.isLoading && !this.errorMessage && !this.assessment;
    }

    get isPending() {
        return !this.isLoading && !this.errorMessage && this.assessment && this.assessment.Status__c === 'Pending';
    }

    get isCompleted() {
        return !this.isLoading && !this.errorMessage && this.assessment && this.assessment.Status__c === 'Completed';
    }

    get riskLevelClass() {
        if (!this.assessment || !this.assessment.Risk_Level__c) return 'slds-badge risk-badge';
        return RISK_LEVEL_CSS[this.assessment.Risk_Level__c] || 'slds-badge risk-badge';
    }

    get scoreBarStyle() {
        if (!this.assessment) return 'width: 0%; background-color: #4bca81;';
        const score = this.assessment.Risk_Score__c || 0;
        const color = SCORE_COLOR[this.assessment.Risk_Level__c] || '#4bca81';
        return `width: ${score}%; background-color: ${color};`;
    }

    get headlines() {
        if (!this.assessment || !this.assessment.Recommendation__c) return [];
        const rec = this.assessment.Recommendation__c;
        const match = rec.match(/Recent headlines: (.+)/);
        if (!match) return [];
        return match[1].split(' | ').filter(h => h.trim().length > 0);
    }

    get hasArticles() {
        return this.headlines && this.headlines.length > 0;
    }
}
