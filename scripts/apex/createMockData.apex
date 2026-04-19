// Creates demo Accounts and Opportunities for the Opportunity Risk Advisor feature.
// 10 real-company Accounts, 2 Opportunities each (20 total).
// Odd opps owned by running user; even opps owned by riskadvisor@secure-vibe-coding.com.
// Safe to re-run: checks existing records before inserting.

Id viewerUserId;
List<User> viewerUsers = [SELECT Id FROM User WHERE Username = 'riskadvisor@secure-vibe-coding.com' LIMIT 1];
if (!viewerUsers.isEmpty()) {
    viewerUserId = viewerUsers[0].Id;
} else {
    System.debug('WARNING: riskadvisor@secure-vibe-coding.com not found — all Opportunities will be owned by running user.');
    viewerUserId = UserInfo.getUserId();
}

// --- Accounts ---
List<String> accountNames = new List<String>{
    'Apple', 'Tesla', 'Amazon', 'Microsoft', 'Boeing',
    'Pfizer', 'Goldman Sachs', 'ExxonMobil', 'Meta', 'Walmart'
};

Map<String, Account> existingAccMap = new Map<String, Account>();
for (Account a : [SELECT Id, Name FROM Account WHERE Name IN :accountNames]) {
    existingAccMap.put(a.Name, a);
}

List<Account> toInsertAccs = new List<Account>();
for (String name : accountNames) {
    if (!existingAccMap.containsKey(name)) {
        toInsertAccs.add(new Account(Name = name));
    }
}
if (!toInsertAccs.isEmpty()) {
    insert toInsertAccs;
    for (Account a : toInsertAccs) {
        existingAccMap.put(a.Name, a);
    }
}
System.debug('Accounts ready: ' + existingAccMap.size());

// --- Opportunity definitions: 2 per account ---
// Each entry: accountName, oppSuffix, stage, amount, closeDays, ownerIndex (1=running user, 2=viewer)
List<List<Object>> oppDefs = new List<List<Object>>{
    new List<Object>{'Apple',        'Enterprise Software License 2026', 'Prospecting',          4500000, 90,  1},
    new List<Object>{'Apple',        'Retail Expansion Q3',              'Negotiation/Review',   1200000, 30,  2},
    new List<Object>{'Tesla',        'Fleet Charging Infrastructure',    'Value Proposition',    3200000, 75,  1},
    new List<Object>{'Tesla',        'Energy Storage Pilot',             'Needs Analysis',        850000, 45,  2},
    new List<Object>{'Amazon',       'Cloud Migration Contract',         'Proposal/Price Quote', 2100000, 60,  1},
    new List<Object>{'Amazon',       'Logistics Automation Deal',        'Qualification',         675000, 50,  2},
    new List<Object>{'Microsoft',    'Azure Integration Services',       'Closed Won',           5000000, 0,   1},
    new List<Object>{'Microsoft',    'Teams Platform Rollout',           'Value Proposition',     980000, 40,  2},
    new List<Object>{'Boeing',       'Avionics Software Suite',          'Needs Analysis',       1750000, 120, 1},
    new List<Object>{'Boeing',       'Maintenance Systems Upgrade',      'Prospecting',           420000, 80,  2},
    new List<Object>{'Pfizer',       'Clinical Data Platform',           'Proposal/Price Quote',  890000, 55,  1},
    new List<Object>{'Pfizer',       'Global Distribution Analytics',    'Qualification',         310000, 35,  2},
    new List<Object>{'Goldman Sachs','Trading Risk Analytics Suite',     'Negotiation/Review',   2800000, 20,  1},
    new List<Object>{'Goldman Sachs','Compliance Reporting Platform',    'Value Proposition',     560000, 65,  2},
    new List<Object>{'ExxonMobil',   'Pipeline Monitoring System',       'Needs Analysis',        740000, 100, 1},
    new List<Object>{'ExxonMobil',   'Refinery Operations Dashboard',    'Prospecting',           190000, 70,  2},
    new List<Object>{'Meta',         'AR Developer Platform License',    'Proposal/Price Quote',  620000, 45,  1},
    new List<Object>{'Meta',         'Data Center Optimization Tools',   'Qualification',         280000, 30,  2},
    new List<Object>{'Walmart',      'Supply Chain Visibility Suite',    'Closed Won',           1350000, 0,   1},
    new List<Object>{'Walmart',      'In-Store Analytics Platform',      'Negotiation/Review',    490000, 25,  2}
};

List<String> oppNames = new List<String>();
for (List<Object> def : oppDefs) {
    oppNames.add((String)def[0] + ' - ' + (String)def[1]);
}

Set<String> existingOppNames = new Set<String>();
for (Opportunity o : [SELECT Name FROM Opportunity WHERE Name IN :oppNames]) {
    existingOppNames.add(o.Name);
}

List<Opportunity> toInsertOpps = new List<Opportunity>();
for (List<Object> def : oppDefs) {
    String accName  = (String)  def[0];
    String suffix   = (String)  def[1];
    String stage    = (String)  def[2];
    Decimal amount  = (Decimal) def[3];
    Integer days    = (Integer) def[4];
    Integer owner   = (Integer) def[5];
    String oppName  = accName + ' - ' + suffix;

    if (!existingOppNames.contains(oppName)) {
        Id ownerId = (owner == 1) ? UserInfo.getUserId() : viewerUserId;
        Date cd = (days == 0) ? Date.today().addDays(-10) : Date.today().addDays(days);
        toInsertOpps.add(new Opportunity(
            Name      = oppName,
            AccountId = existingAccMap.get(accName).Id,
            StageName = stage,
            Amount    = amount,
            CloseDate = cd,
            OwnerId   = ownerId
        ));
    }
}

Integer created = 0;
Integer skipped = oppDefs.size() - toInsertOpps.size();
if (!toInsertOpps.isEmpty()) {
    insert toInsertOpps;
    created = toInsertOpps.size();
}

System.debug('=== Mock Data Summary ===');
System.debug('Accounts:      ' + existingAccMap.size());
System.debug('Opps created:  ' + created);
System.debug('Opps skipped (already existed): ' + skipped);

List<Opportunity> all = [
    SELECT Name, StageName, Amount, Account.Name, Owner.Username
    FROM Opportunity
    WHERE Name IN :oppNames
    ORDER BY Account.Name, Name
];
for (Opportunity o : all) {
    System.debug(o.Account.Name + ' | ' + o.Name + ' | ' + o.StageName + ' | $' + o.Amount + ' | ' + o.Owner.Username);
}
System.debug('Total Opportunities in org matching mock set: ' + all.size());
