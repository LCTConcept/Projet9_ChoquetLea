@isTest
public class MyTeamOrdersControllerTest {
    
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
    
    @isTest
    static void testSumOrders() {
       
        // Récupérer les comptes créés dans le setup
        Account accountA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];
        Account accountB = [SELECT Id FROM Account WHERE Name = 'Test Account B' LIMIT 1];
        
        // Récupérer les commandes de chaque compte et les mettre à jour avec le statut 'Ordered'
        List<Order> ordersA = [SELECT Id, Status FROM Order WHERE AccountId = :accountA.Id];
        List<Order> ordersB = [SELECT Id, Status FROM Order WHERE AccountId = :accountB.Id];
        
        for (Order order : ordersA) {
            order.Status = 'Ordered';
        }
        update ordersA;
        
       
        // Calculer le chiffre d'affaires du compte A
        Decimal expectedRevenueA = 0;
        List<OrderItem> orderItemsA = [SELECT Quantity, UnitPrice FROM OrderItem WHERE Order.AccountId = :accountA.Id];
        for (OrderItem oi : orderItemsA) {
            expectedRevenueA += (oi.Quantity * oi.UnitPrice);
        }
        
        // Vérifier que le chiffre d'affaires du compte a été mis à jour
        Test.startTest();
        MyTeamOrdersController controller = new MyTeamOrdersController();
        Decimal total = controller.SumOrders;
        Test.stopTest();
        
        // Verif que le chiffre d'affaires est correctement mis à jour
        System.debug('Chiffre d\'affaire attendu des commandes Ordered : ' + expectedRevenueA);
        System.debug('Chiffre d\'affaire affiché  : ' + total);
        System.assertEquals(expectedRevenueA, total, 'La somme des commandes "Ordered" devrait être correcte');
        

    }
}