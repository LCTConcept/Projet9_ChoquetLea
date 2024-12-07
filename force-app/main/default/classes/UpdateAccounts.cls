global class UpdateAccounts implements Database.Batchable<sObject> {
    
    // Constructeur pour permettre l'injection de l'adresse email
    private String emailAddress;
    public UpdateAccounts(String emailAddress) {
        this.emailAddress = emailAddress;
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext info) {
        // Sélectionner tous les comptes ayant au moins une commande activée
        return Database.getQueryLocator([
            SELECT Id FROM Account 
            WHERE Id IN (SELECT AccountId FROM Order WHERE Status = 'Ordered')
        ]);
       

    }
    
    global void execute(Database.BatchableContext info, List<Account> scope) {
        
        // Requête de la liste des commandes avec statut "Ordered"
        List<Order> listOrders = [
            SELECT Id, TotalAmount, AccountId, Status
            FROM Order
            WHERE AccountId IN :scope
            AND Status = 'Ordered'
        ];
        
        // Mise à jour
        AccountHelper.updateAccountRevenueAfterUpdate(listOrders);
    }
    
    global void finish(Database.BatchableContext info) {
        
        
         // Appeler la classe  pour gérer la notification par email
        BatchEmailSender.sendBatchCompletionEmail(this.emailAddress, info.getJobId());
              
    }
    
    
}