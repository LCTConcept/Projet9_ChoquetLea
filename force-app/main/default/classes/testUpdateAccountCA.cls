@isTest
private class TestUpdateAccountCA {
    
    // Méthode pour initialiser les données de test
    @testSetup
    static void setup() {
        // Créer les comptes de test
        Account accountA = TestDataFactory.createAccount('Test Account A', true);
        Account accountB = TestDataFactory.createAccount('Test Account B', true);
        
        // Créer un produit et une entrée de prix pour les commandes
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, true);
        
        // Créer des commandes pour Test Account A
        List<Order> ordersA = TestDataFactory.createOrders(accountA.Id, 3, pbe, true);
        // Créer des OrderItems pour chaque commande de Test Account A
        for (Order order : ordersA) {
            TestDataFactory.createOrderItem(order, pbe, 15, true);  // Ajouter un OrderItem avec 15 articles
            TestDataFactory.createOrderItem(order, pbe, 25, true);  // Ajouter un autre OrderItem avec 25 articles
        }
        
        // Créer des commandes pour Test Account B
        List<Order> ordersB = TestDataFactory.createOrders(accountB.Id, 2, pbe, true);
        // Créer des OrderItems pour chaque commande de Test Account B
        for (Order order : ordersB) {
            TestDataFactory.createOrderItem(order, pbe, 10, true);  // Ajouter un OrderItem avec 10 articles
            TestDataFactory.createOrderItem(order, pbe, 20, true);  // Ajouter un autre OrderItem avec 20 articles
        }
        
    }
    
    @isTest //TEST USE CASE #1
    static void updateAccountRevenueOnOrderStatusChange() {
        
        // Récup les données du setup
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
        List<Order> ordersA = [SELECT Id, Status FROM Order WHERE AccountId = :accountA.Id];
        Order ordA1 = ordersA[0];
        System.debug('Before update : ' + ordA1.Status);
        
        // Récupérer les OrderItems associés à la commande
        List<OrderItem> orderItems = [SELECT Quantity, UnitPrice FROM OrderItem WHERE OrderId = :ordA1.Id];
        OrderItem oi1 = orderItems[0]; 
        OrderItem oi2 = orderItems[1]; 
        
        // Passage de la commande au statut 'Ordered'
        ordA1.Status = 'Ordered';
        update ordA1;
        System.debug('After update : ' + ordA1.Status);
        
        // Vérifier que le chiffre d'affaires du compte a été mis à jour
        Test.startTest();
        Account updatedAcc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :accountA.Id];
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
        
        // Récup les données du setup
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
        List<Order> ordersA = [SELECT Id, Status FROM Order WHERE AccountId = :accountA.Id];
        Order ordA1 = ordersA[0];
        ordA1.ShipmentCost__c = 50;  // Coût d'expédition pour tester le calcul du montant net
        System.debug('Before update : ' + ordA1.Status);
        System.debug('Shipment Cost : ' + ordA1.ShipmentCost__c);
        
        // Récupérer les OrderItems associés à la commande
        List<OrderItem> orderItems = [SELECT Quantity, UnitPrice FROM OrderItem WHERE OrderId = :ordA1.Id];
        OrderItem oi1 = orderItems[0]; 
        OrderItem oi2 = orderItems[1]; 
        

        // Capture du chiffre d'affaires avant la mise à jour
        Decimal initialRevenue = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accountA.Id].Chiffre_d_affaire__c;
        System.debug('Chiffre d\'affaire avant la mise à jour : ' + initialRevenue);
        
        // Modification du statut de la commande sans le passer à 'Ordered'
        Test.startTest();
        ordA1.Status = 'Shipped'; 
        System.debug('After update : ' + ordA1.Status);
        update ordA1;
        Test.stopTest();
        
        
        // Vérification que le chiffre d'affaires n'a pas changé
        Decimal finalRevenue = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accountA.Id].Chiffre_d_affaire__c;
        System.debug('Chiffre d\'affaire après mise à jour : ' + finalRevenue);
        
        // S'assurer que le chiffre d'affaires reste inchangé
        System.assertEquals(initialRevenue, finalRevenue, 'Le chiffre d\'affaire du compte ne doit pas être mis à jour si la commande n\'est pas activée.');
    }
    
    
    @isTest //TEST USE CASE #3
    static void updateAccountRevenueWithHundredOrders() {
        // Récup les données nécessaires pour l'Account
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
      	Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, true);
        
        System.debug('DML statements avant exécution : ' + Limits.getDmlStatements());
        
        // Créer une liste pour stocker les commandes et les OrderItems
        List<Order> orders = new List<Order>();
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 0; i < 100; i++) {
            Order ord = TestDataFactory.createOrder(accountA.Id, false);
            orders.add(ord);
        }
        insert orders;
        
        System.debug('Nombre de commandes insérées : ' + orders.size());
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
        
        
        // Passage des commandes au statut 'Ordered'
        for (Order ord : orders) {
            ord.Status = 'Ordered';
        }
        update orders;
        System.debug('DML statements après la mise à jour du statut : ' + Limits.getDmlStatements());
        
        // Vérifier que le chiffre d'affaires du compte a été mis à jour
        Test.startTest();
        Account updatedAcc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :accountA.Id];
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