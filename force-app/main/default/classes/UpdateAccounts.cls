global class UpdateAccounts implements Database.Batchable<sObject>, Schedulable  {
    
    // Constructeur pour permettre l'injection de l'adresse email
    private String emailAddress;
    public UpdateAccounts(String emailAddress) {
        this.emailAddress = emailAddress;
    }
    
    global Database.QueryLocator start(Database.BatchableContext info) {
        // Sélectionner tous les comptes ayant au moins une commande activée
        return Database.getQueryLocator([
            SELECT Id FROM Account 
            WHERE Id IN (SELECT AccountId FROM Order WHERE Status = 'Activated')
        ]);
    }
    
    global void execute(Database.BatchableContext info, List<Account> scope) {
        
        // Requête de la liste des commandes avec statut "Activated"
        List<Order> listOrders = [
            SELECT Id, TotalAmount, AccountId, Status
            FROM Order
            WHERE AccountId IN :scope
            AND Status = 'Activated'
        ];
        
        // Mise à jour
        AccountHelper.updateAccountRevenueAfterUpdate(listOrders);
    }
    
    global void finish(Database.BatchableContext info) {
        
               
        // Récupérer les informations sur le batch via AsyncApexJob
        AsyncApexJob job = [SELECT Id, ApexClassId, TotalJobItems, NumberOfErrors, CreatedDate, CompletedDate, JobItemsProcessed
                            FROM AsyncApexJob
                            WHERE Id = :info.getJobId() LIMIT 1];
        
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob];
        System.debug('Jobs disponibles : ' + jobs);
        
        
        // Construire le corps de l'email
        String emailBody = 'Le batch a terminé son exécution.\n\n';
        emailBody += 'Nom de la classe : ' + job.ApexClassId + '\n';
        emailBody += 'Nombre total d\'éléments : ' + job.TotalJobItems + '\n';
        emailBody += 'Nombre d\'éléments traités : ' + job.JobItemsProcessed + '\n';
        emailBody += 'Nombre d\'erreurs : ' + job.NumberOfErrors + '\n';
        emailBody += 'Date de début : ' + job.CreatedDate + '\n';
        emailBody += 'Date de fin : ' + job.CompletedDate + '\n';
        
        // Envoi de l'email avec l'adresse modifiable
        Boolean emailSent = false;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { emailAddress }); // Utilisation de l'adresse email dynamique
        mail.setSubject('Rapport d\'exécution du batch');
        mail.setPlainTextBody(emailBody);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Destinataires : ' + mail.getToAddresses());
            System.debug('Sujet : ' + mail.getSubject());
            System.debug('Corps : ' + mail.getPlainTextBody());
            
            emailSent = true;
            System.debug('Succès de l\'envoi de l\'email : ' + emailSent);
        } catch (Exception e) {
            System.debug('Échec de l\'envoi de l\'email : ' + e.getMessage());
            System.debug('Succès de l\'envoi de l\'email : ' + emailSent);
           
        }
              
    }
    
    
    // Implémentation de la méthode de l'interface Schedulable
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateAccounts(this.emailAddress), 200); // Passer l'adresse email dans le batch
    }
    
}