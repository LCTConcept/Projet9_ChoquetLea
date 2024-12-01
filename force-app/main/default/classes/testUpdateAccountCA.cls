@isTest
private class TestUpdateAccountCA {
    
    //PREVOIR UN TEST SETUP
    
    @isTest //TEST USE CASE #1
    static void updateAccountRevenueOnOrderStatusChange() {
        // Créer les données nécessaires pour l'Order
        Account acc = TestDataFactory.createAccount(true);
        Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, true);
        
        // Créer une commande avec le Pricebook standard
        Order ord = TestDataFactory.createOrder(acc.Id, true);
        //ord.ShipmentCost__c = 50;  // Coût d'expédition pour tester le calcul du montant net
        System.debug('Frais de port : ' + ord.ShipmentCost__c);
        
        // Mettre à jour la commande pour que le trigger soit exécuté
        update ord;
        
        // Créer les OrderItems
        OrderItem oi1 = TestDataFactory.createOrderItem(ord, pbe, 10, true);
        OrderItem oi2 = TestDataFactory.createOrderItem(ord, pbe, 20, true);
        
        // Passage de la commande au statut 'Activated'
        ord.Status = 'Activated';
        update ord;
        
        // Vérifier que le chiffre d'affaires du compte a été mis à jour
        Test.startTest();
        Account updatedAcc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        Test.stopTest();
        
        // Calcul du chiffre d'affaire attendu
        Decimal expectedRevenue = (oi1.Quantity * oi1.UnitPrice) + (oi2.Quantity * oi2.UnitPrice) ;
        System.debug('Chiffre d\'affaire attendu : ' + expectedRevenue);
        System.debug('Chiffre d\'affaire du compte après mise à jour : ' + updatedAcc.Chiffre_d_affaire__c);
        
        // Assert pour vérifier que le chiffre d'affaire est correct
        System.assertEquals(expectedRevenue, updatedAcc.Chiffre_d_affaire__c, 'Le chiffre d\'affaire du compte ne correspond pas après activation de la commande.');
    }
    
    @isTest //TEST USE CASE #2
    static void testNoUpdateOnNonActivatedOrder() {
        
        // Créer les données nécessaires pour l'Order
        Account acc = TestDataFactory.createAccount(true);
        Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, true);
        
        // Créer une commande avec le Pricebook standard
        Order ord1 = TestDataFactory.createOrder(acc.Id, true);
        ord1.ShipmentCost__c = 50;  // Coût d'expédition pour tester le calcul du montant net
        
        // Mettre à jour la commande pour que le trigger soit exécuté
        update ord1;
        
        // Créer un OrderItem avec la quantité 10
        OrderItem oi1 = TestDataFactory.createOrderItem(ord1, pbe, 10, true);
        OrderItem oi2 = TestDataFactory.createOrderItem(ord1, pbe, 20, true);
        
        // Capture du chiffre d'affaires avant la mise à jour
        Decimal initialRevenue = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id].Chiffre_d_affaire__c;
        System.debug('Chiffre d\'affaire avant la mise à jour : ' + initialRevenue);
        
        // Modification du statut de la commande sans le passer à 'Activated'
        Test.startTest();
        ord1.Status = 'Shipped'; 
        update ord1;
        Test.stopTest();
        
        // Vérification que le chiffre d'affaires n'a pas changé
        Decimal finalRevenue = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id].Chiffre_d_affaire__c;
        System.debug('Chiffre d\'affaire après mise à jour : ' + finalRevenue);
        
        // S'assurer que le chiffre d'affaires reste inchangé
        System.assertEquals(initialRevenue, finalRevenue, 'Le chiffre d\'affaire du compte ne doit pas être mis à jour si la commande n\'est pas activée.');
    }
    
       
    @isTest //TEST USE CASE #3
    static void updateAccountRevenueWithHundredOrders() {
        // Créer les données nécessaires pour l'Account
        Account acc = TestDataFactory.createAccount(true);
        Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, true);
        
        System.debug('DML statements avant exécution : ' + Limits.getDmlStatements());
        
        // Créer une liste pour stocker les commandes et les OrderItems
        List<Order> orders = new List<Order>();
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 0; i < 100; i++) {
            Order ord = TestDataFactory.createOrder(acc.Id, false);
            orders.add(ord);
        }
        insert orders;
        
        System.debug(orders.size());
        System.debug('DML statements après exécution : ' + Limits.getDmlStatements());
        
        // Ajouter un OrderItem pour chaque commande
        for (Integer i = 0; i < orders.size(); i++) {
            Order ord = orders[i];
            OrderItem oi = TestDataFactory.createOrderItem(ord, pbe, 10 + i, false); // Crée l'OrderItem
            orderItems.add(oi); // Ajoute l'OrderItem à la liste
        }
        insert orderItems; // Insère tous les OrderItems en une seule opération DML
        
        System.debug('Nombre d\'OrderItems insérés : ' + orderItems.size());
        System.debug('DML statements après insertion des OrderItems : ' + Limits.getDmlStatements());
        
        
        // Passage des commandes au statut 'Activated'
        for (Order ord : orders) {
            ord.Status = 'Activated';
        }
        update orders;
        System.debug('DML statements après la mise à jour du statut : ' + Limits.getDmlStatements());
        
        // Vérifier que le chiffre d'affaires du compte a été mis à jour
        Test.startTest();
        Account updatedAcc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        Test.stopTest();
        
        // Calcul du chiffre d'affaire attendu pour les 100 commandes
        Decimal expectedRevenue = 0;
        for (OrderItem oi : orderItems) {
            expectedRevenue += (oi.Quantity * oi.UnitPrice);
        }
        
        System.debug('Chiffre d\'affaire attendu : ' + expectedRevenue);
        System.debug('Chiffre d\'affaire du compte après mise à jour : ' + updatedAcc.Chiffre_d_affaire__c);
        
        // Assert pour vérifier que le chiffre d'affaire est correct
        System.assertEquals(expectedRevenue, updatedAcc.Chiffre_d_affaire__c, 'Le chiffre d\'affaire du compte ne correspond pas après activation des commandes.');
        
            }
    

    
}