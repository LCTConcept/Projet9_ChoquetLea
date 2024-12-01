public class AccountHelper {
    
    // Méthode pour calculer le montant net d'une commande avant mise à jour
    public static void calculateOrderNetAmountBeforeUpdate(List<Order> ordersToUpdate) {
    for (Order ord : ordersToUpdate) {
        // Vérifier si ShipmentCost__c est null, et le remplacer par 0 si nécessaire
        Decimal shipmentCost;
        if (ord.ShipmentCost__c != null) {
            shipmentCost = ord.ShipmentCost__c;
        } else {
            shipmentCost = 0;
        }

        // Calcul du montant net de la commande (NetAmount__c)
        ord.NetAmount__c = ord.TotalAmount - shipmentCost;
    }
}


    // Méthode pour mettre à jour le chiffre d'affaire du compte après la mise à jour de la commande
    public static void updateAccountRevenueAfterUpdate(List<Order> ordersToUpdate) {
        Set<Id> accountIds = new Set<Id>();
        
        // Collecte des comptes liés aux commandes mises à jour
        for (Order ord : ordersToUpdate) {
            if (ord.Status == 'Activated') {
                accountIds.add(ord.AccountId);
            }
        }
        
        // Si aucun compte n'est trouvé, rien à faire
        if (accountIds.isEmpty()) {
            return;
        }
        
        // Récupérer toutes les commandes activées associées aux comptes
        List<OrderItem> orderItems = [
            SELECT OrderId, Quantity, UnitPrice, Order.AccountId 
            FROM OrderItem 
            WHERE OrderId IN (SELECT Id FROM Order WHERE AccountId IN :accountIds AND Status = 'Activated')
        ];

        
        // Calculer le chiffre d'affaire pour chaque compte
        Map<Id, Decimal> accountRevenueMap = new Map<Id, Decimal>();
        
        for (OrderItem oi : orderItems) {
            
            // Récupérer l'ID du compte associé à l'OrderItem
   			Id accountOrderId = oi.Order.AccountId;
            
            // Calculer le montant de l'OrderItem
    		Decimal orderItemAmount = oi.Quantity * oi.UnitPrice;
            
            // Initialiser le chiffre d'affaires du compte s'il n'existe pas déjà dans la map
            if (!accountRevenueMap.containsKey(accountOrderId)) {
                accountRevenueMap.put(accountOrderId, 0); 
            }
            // Ajouter le montant de l'OrderItem au chiffre d'affaires existant du compte
            accountRevenueMap.put(accountOrderId, accountRevenueMap.get(accountOrderId) + orderItemAmount);
        }
        
        // Mettre à jour le chiffre d'affaires de chaque compte
		List<Account> accountsToUpdate = new List<Account>();

        for (Id accountId : accountRevenueMap.keySet()) {
            
        	// Récupérer le chiffre d'affaires calculé pour le compte
            Decimal updatedRevenue = accountRevenueMap.get(accountId);

            // Créer une instance de l'objet Account avec l'ID et le chiffre d'affaires mis à jour
            Account acc = new Account(
                Id = accountId,
                Chiffre_d_affaire__c = updatedRevenue
            );

            // Ajouter le compte à la liste des comptes à mettre à jour
            accountsToUpdate.add(acc);
        }

        
        // Mettre à jour les comptes
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}