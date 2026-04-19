// Verifies permission enforcement for the running admin user
// The running user must have Risk_Advisor_Manager permission set assigned

Boolean hasPermission = RiskAssessmentController.hasManualAssessmentPermission();

System.debug('=== Permission Enforcement Check ===');
System.debug('Running User: ' + UserInfo.getUserName());
System.debug('hasManualAssessmentPermission() = ' + hasPermission);

if (hasPermission) {
    System.debug('PASS: Admin user correctly has Can_Request_Manual_Assessment permission.');
} else {
    System.debug('FAIL: Admin user does NOT have Can_Request_Manual_Assessment permission.');
    System.debug('Ensure Risk_Advisor_Manager permission set is assigned to this user.');
    throw new IllegalArgumentException(
        'hasManualAssessmentPermission() returned false for ' + UserInfo.getUserName()
        + '. Assign Risk_Advisor_Manager permission set and retry.'
    );
}
