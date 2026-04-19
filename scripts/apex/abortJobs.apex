List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = '08eg8000003bvow'];
for (CronTrigger ct : jobs) {
    System.abortJob(ct.Id);
    System.debug('Aborted scheduled job: ' + ct.CronJobDetail.Name);
}
List<AsyncApexJob> queueJobs = [SELECT Id, Status FROM AsyncApexJob WHERE Id = '707g8000009djNv'];
for (AsyncApexJob j : queueJobs) {
    System.debug('Queueable job status: ' + j.Status + ' (Id: ' + j.Id + ')');
}
System.debug('Done');
