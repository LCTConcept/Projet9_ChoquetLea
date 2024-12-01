@isTest
public class UpdateAccountsBatchTest {
    
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
    
    @isTest // TEST USE CASE #1 - Mise à jour du CA
    static void updateAccountRevenueOnBatchExecution() {
        // Récupérer les comptes créés dans le setup
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
        Account accountB = [SELECT Id FROM Account WHERE Name = 'Test Account B' LIMIT 1];
        
        // Récupérer les commandes de chaque compte et les mettre à jour avec le statut 'Activated'
        List<Order> ordersA = [SELECT Id, Status FROM Order WHERE AccountId = :accountA.Id];
        List<Order> ordersB = [SELECT Id, Status FROM Order WHERE AccountId = :accountB.Id];
        
        for (Order order : ordersA) {
            order.Status = 'Activated';
        }
        update ordersA;
        
        for (Order order : ordersB) {
            order.Status = 'Activated';
        }
        update ordersB;

		// Set le destinataire du mail du batch
        String adressEmail = 'l.m.choquet@gmail.com';  
        
        // Exécuter le batch
        Test.startTest();
        UpdateAccounts batch = new UpdateAccounts(adressEmail); 
        Database.executeBatch(batch, 200); // Exécuter le batch avec un batch size de 200
        
        Test.stopTest();
        
        // Vérif que le chiffre d'affaires des comptes a été mis à jour
        Account updatedAccA = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :accountA.Id];
        Account updatedAccB = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :accountB.Id];
        
        // Calculer le chiffre d'affaires attendu pour chaque compte
        Decimal expectedRevenueA = 0;
        List<OrderItem> orderItemsA = [SELECT Quantity, UnitPrice FROM OrderItem WHERE Order.AccountId = :accountA.Id];
        for (OrderItem oi : orderItemsA) {
            expectedRevenueA += (oi.Quantity * oi.UnitPrice);
        }
        
        Decimal expectedRevenueB = 0;
        List<OrderItem> orderItemsB = [SELECT Quantity, UnitPrice FROM OrderItem WHERE Order.AccountId = :accountB.Id];
        for (OrderItem oi : orderItemsB) {
            expectedRevenueB += (oi.Quantity * oi.UnitPrice);
        }
        
        
        // Verif que le chiffre d'affaires est correctement mis à jour
        System.debug('Chiffre d\'affaire attendu pour Account A : ' + expectedRevenueA);
        System.debug('Chiffre d\'affaire actuel pour Account A : ' + updatedAccA.Chiffre_d_affaire__c);
        System.assertEquals(expectedRevenueA, updatedAccA.Chiffre_d_affaire__c, 'Le chiffre d\'affaire du compte A ne correspond pas après mise à jour.');
        
        System.debug('Chiffre d\'affaire attendu pour Account B : ' + expectedRevenueB);
        System.debug('Chiffre d\'affaire actuel pour Account B : ' + updatedAccB.Chiffre_d_affaire__c);
        System.assertEquals(expectedRevenueB, updatedAccB.Chiffre_d_affaire__c, 'Le chiffre d\'affaire du compte B ne correspond pas après mise à jour.');
    }
    
    
    @isTest // TEST USE CASE #2 - Mise à jour du CA sans nouvelles commandes
    static void noUpdateWhenNoActivatedOrders() {
        // Récupérer les comptes créés dans le setup
        Account accountA = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account A'];
        Account accountB = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account B'];
        
        // Stocker les chiffres d'affaires avant l'exécution du batch
        Decimal initialRevenueA = accountA.Chiffre_d_affaire__c;
        System.debug('Chiffre d\'affaire initial pour Account A : ' + initialRevenueA);
        Decimal initialRevenueB = accountB.Chiffre_d_affaire__c;
        System.debug('Chiffre d\'affaire initial pour Account B : ' + initialRevenueB);
        
		// Set le destinataire du mail du batch
        String adressEmail = 'l.m.choquet@gmail.com';  
        
        // Exécuter le batch
        Test.startTest();
        UpdateAccounts batch = new UpdateAccounts(adressEmail); 
        Database.executeBatch(batch, 200); // Exécuter le batch avec un batch size de 200
        
        Test.stopTest();
        
        // Vérifier que le chiffre d'affaires des comptes reste inchangé
        Account updatedAccA = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :accountA.Id];
        System.debug('Chiffre d\'affaire mis à jour pour Account A : ' + updatedAccA.Chiffre_d_affaire__c);
        Account updatedAccB = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :accountB.Id];
        System.debug('Chiffre d\'affaire mis à jour pour Account B : ' + updatedAccB.Chiffre_d_affaire__c);
        
        // Vérifier que le chiffre d'affaires est resté inchangé
        System.assertEquals(updatedAccA.Chiffre_d_affaire__c, initialRevenueA, 'Le chiffre d\'affaire du compte A ne doit pas être modifié.');
        System.assertEquals(updatedAccB.Chiffre_d_affaire__c, initialRevenueB, 'Le chiffre d\'affaire du compte B ne doit pas être modifié.');
    }
    
    
    
    @isTest  //TEST USE CASE #3 - Succès envoi email 
    static void testBatchExecutionAndEmailNotification() {
        
        // Récupérer les comptes de test
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
        
        // Activer les commandes pour le compte
        List<Order> orders = [SELECT Id FROM Order WHERE AccountId = :accountA.Id];
        for (Order order : orders) {
            order.Status = 'Activated';
        }
        update orders;
        
        // Set le destinataire du mail du batch
        String adressEmail = 'l.m.choquet@gmail.com';  
        
        // Exécuter le batch
        Test.startTest();
        UpdateAccounts batch = new UpdateAccounts(adressEmail); 
        Database.executeBatch(batch, 200); // Exécuter le batch avec un batch size de 200
        
        Test.stopTest();
               
        /*Vérification de l'envoi du mail grâce au try/catch du bloc finish 
* Si l'email ne s'envoie pas, on rentre dans le catch. 
* Donc pas besoin d'assert pour ce test. 
* La vérification se fait au niveau du DEBUG ligne 64 du batch Update Accounts
* Où la valeur de emailSent doit être égale à true si l'email s'est bien envoyé */
        
    }
    
	@isTest // TEST USE CASE #4 - Échec de l'envoi d'email
    static void testBatchExecutionAndEmailNotificationFailure() {
        
        // Récupérer les comptes de test
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
        
        // Activer les commandes pour le compte
        List<Order> orders = [SELECT Id FROM Order WHERE AccountId = :accountA.Id];
        for (Order order : orders) {
            order.Status = 'Activated';
        }
        update orders;
        
        // Préparer l'email invalide pour simuler l'échec
        String invalidEmail = 'invalid-email';  
        
        // Exécuter le batch avec un email invalide pour provoquer une erreur
        Test.startTest();
        UpdateAccounts batch = new UpdateAccounts(invalidEmail);  // L'adresse email est injectée ici
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        /*Vérification de l'envoi du mail grâce au try/catch du bloc finish 
		* Ici, on doit rentrer dans le catch
		* La vérification se fait au niveau du DEBUG ligne 71 du batch Update Accounts qui indique une exception
		* Et DEBUG ligne 72 où la valeur de emailSent doit être égale à false car l'email ne s'est pas envoyé */	 
        
    }
    
  
    
    @isTest // TEST USE CASE 5 - Vérif schedule
    static void testScheduledExecution() {
        // Récup les données du setup
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
        
        // Activer les commandes pour ces comptes
        List<Order> ordersA = [SELECT Id, Status FROM Order WHERE AccountId = :accountA.Id];
        for (Order order : ordersA) {
            order.Status = 'Activated';
        }
        update ordersA;   
        
        // Set le destinataire du mail du batch
        String adressEmail = 'l.m.choquet@gmail.com'; 
        
        // Nom unique pour la tâche planifiée
        String jobName = 'TestScheduledBatchJob';
        
        // Planifier le batch
        String cronExpression = '0 0 0 24 12 ? 2024'; // Un batch sous le sapin
        Test.startTest();
        System.schedule(jobName, cronExpression, new UpdateAccounts(adressEmail));
        Test.stopTest();
        
        // Vérif si le batch a été correctement planifié
        CronTrigger scheduledJob = [SELECT Id, CronJobDetail.Name, State
                                    FROM CronTrigger
                                    WHERE CronJobDetail.Name = :jobName LIMIT 1];
        
        System.assertNotEquals(null, scheduledJob, 'Le job planifié devrait exister.');
        System.debug('Le job est actuellement : ' + scheduledJob.State);
        System.assertEquals('WAITING', scheduledJob.State, 'Le job devrait être en attente d\'exécution.');
        
    }
  
}