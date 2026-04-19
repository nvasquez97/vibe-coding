// Schedule the Nightly Risk Assessment job at 2 AM every day
// Safe to re-run: aborts existing job before scheduling a new one

RiskAssessmentSchedulable.scheduleNightly();

List<CronTrigger> jobs = [
    SELECT Id, CronExpression, State, NextFireTime
    FROM CronTrigger
    WHERE CronJobDetail.Name = 'Nightly Risk Assessment'
    AND State NOT IN ('DELETED', 'COMPLETE', 'ERROR')
];

if (!jobs.isEmpty()) {
    System.debug('SUCCESS: Nightly Risk Assessment scheduled.');
    System.debug('Cron Expression: ' + jobs[0].CronExpression);
    System.debug('State: ' + jobs[0].State);
    System.debug('Next Fire Time: ' + jobs[0].NextFireTime);
} else {
    System.debug('WARNING: Job not found after scheduling.');
}
