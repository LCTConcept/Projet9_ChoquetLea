@isTest
public class TestDataFactoryTest {

    @isTest
    public static void testCreateAccount() {
        // Tester la création d'un compte sans insertion
        Account acc = TestDataFactory.createAccount(false);
        System.assertNotEquals(null, acc, 'Le compte ne doit pas être nul');
        
        // Tester la création et l'insertion d'un compte
        Account accInserted = TestDataFactory.createAccount(true);
        System.assertNotEquals(null, accInserted.Id, 'Le compte doit être inséré et avoir un identifiant');
    }

    @isTest
    public static void testCreateProduct() {
        // Tester la création d'un produit sans insertion
        Product2 prod = TestDataFactory.createProduct(false);
        System.assertNotEquals(null, prod, 'Le produit ne doit pas être nul');
        
        // Tester la création et l'insertion d'un produit
        Product2 prodInserted = TestDataFactory.createProduct(true);
        System.assertNotEquals(null, prodInserted.Id, 'Le produit doit être inséré et avoir un identifiant');
    }

    @isTest
    public static void testCreatePricebookEntry() {
        // Créer un produit pour tester l'entrée de pricebook
        Product2 prod = TestDataFactory.createProduct(true);
        
        // Tester la création d'une entrée de Pricebook sans insertion
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, false);
        System.assertNotEquals(null, pbe, 'L\'entrée de Pricebook ne doit pas être nulle');
        
        // Tester la création et l'insertion d'une entrée de Pricebook
        PricebookEntry pbeInserted = TestDataFactory.createPricebookEntry(prod, true);
        System.assertNotEquals(null, pbeInserted.Id, 'L\'entrée de Pricebook doit être insérée et avoir un identifiant');
    }

    @isTest
    public static void testCreateOrder() {
        // Créer un compte pour tester la commande
        Account acc = TestDataFactory.createAccount(true);
        
        // Tester la création d'une commande sans insertion
        Order ord = TestDataFactory.createOrder(acc.Id, false);
        System.assertNotEquals(null, ord, 'La commande ne doit pas être nulle');
        
        // Tester la création et l'insertion d'une commande
        Order ordInserted = TestDataFactory.createOrder(acc.Id, true);
        System.assertNotEquals(null, ordInserted.Id, 'La commande doit être insérée et avoir un identifiant');
    }

    @isTest
    public static void testCreateOrderItem() {
        // Créer les données nécessaires pour l'Order
        Account acc = TestDataFactory.createAccount(true);
        Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, true);
    
        // Créer une commande avec le Pricebook standard
        Order ord = TestDataFactory.createOrder(acc.Id, true);
        ord.ShipmentCost__c = 50;  // Coût d'expédition pour tester le calcul du montant net
    
        // Mettre à jour la commande pour que le trigger soit exécuté
        update ord;
    
        // Créer un OrderItem avec la quantité 10
        OrderItem oi = TestDataFactory.createOrderItem(ord, pbe, 10, true);
    
        // Vérifier que l'OrderItem a bien été inséré
        System.assertNotEquals(null, oi.Id, 'L\'OrderItem doit être inséré et avoir un identifiant');
        System.assertEquals(oi.Quantity, 10, 'La quantité de l\'OrderItem doit être 10');
        System.assertEquals(oi.UnitPrice, pbe.UnitPrice, 'Le prix unitaire de l\'OrderItem doit correspondre au prix de l\'entrée de Pricebook');
        
        // Vérifier que le TotalAmount de la commande est mis à jour (TotalAmount devrait être mis à jour automatiquement via Trigger)
        ord = [SELECT TotalAmount, NetAmount__c, ShipmentCost__c FROM Order WHERE Id = :ord.Id];
        System.assertNotEquals(ord.TotalAmount, 0, 'Le TotalAmount doit être mis à jour en fonction de l\'OrderItem');
    
        // Vérifier que le montant net de la commande a été calculé correctement
        Decimal expectedNetAmount = ord.TotalAmount - ord.ShipmentCost__c;
        System.assertEquals(ord.NetAmount__c, expectedNetAmount, 'Le montant net doit être égal à TotalAmount - ShipmentCost__c');
    }


	@isTest
	public static void testCreateOrders() {
        // Créer un compte et un produit pour tester les commandes
        Account acc = TestDataFactory.createAccount(true);
        Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, true);
        
        // Tester la création de plusieurs commandes sans insertion
        List<Order> orders = TestDataFactory.createOrders(acc.Id, 2, pbe, false);
        System.assertEquals(2, orders.size(), 'Il doit y avoir 2 commandes créées');
        
        // Tester la création et l'insertion de plusieurs commandes
        List<Order> ordersInserted = TestDataFactory.createOrders(acc.Id, 2, pbe, true);
        System.assertEquals(2, ordersInserted.size(), 'Il doit y avoir 2 commandes insérées');
    }
}