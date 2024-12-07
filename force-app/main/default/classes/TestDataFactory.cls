@isTest
public class TestDataFactory {

    // Créer un compte
    public static Account createAccount(Boolean doInsert) {
        return createAccount('Test Account', doInsert);
    }

    public static Account createAccount(String name, Boolean doInsert) {
        Account acc = new Account(Name = name);
        if (doInsert) {
            insert acc;
        }
        return acc;
    }

    // Créer un produit
    public static Product2 createProduct(Boolean doInsert) {
        Product2 product = new Product2(Name = 'Chemise Verte longue XYX', IsActive = true, Family = 'Chemise');
        if (doInsert) {
            insert product;
        }
        return product;
    }

    // Créer une entrée de prix dans le Pricebook standard
    public static PricebookEntry createPricebookEntry(Product2 product, Boolean doInsert) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,  
            IsActive = true
        );
        if (doInsert) {
            insert pbe;
        }
        return pbe;
    }

    // Créer une commande
    public static Order createOrder(Id accountId, Boolean doInsert) {
        Order ord = new Order(
            AccountId = accountId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()  // Utilise le Pricebook standard
        );
        if (doInsert) {
            insert ord;
        }
        return ord;
    }

    // Créer un OrderItem
    public static OrderItem createOrderItem(Order order, PricebookEntry pbe, Integer quantity, Boolean doInsert) {
        OrderItem oi = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pbe.Id,
            Quantity = quantity,
            UnitPrice = pbe.UnitPrice
        );
        if (doInsert) {
            insert oi;
        }
        return oi;
    }

    // Créer des commandes
    public static List<Order> createOrders(Id accountId, Integer numOrders, PricebookEntry pbe, Boolean doInsert) {
        List<Order> orders = new List<Order>();

        for (Integer i = 1; i <= numOrders; i++) {
            // Créer une commande
            Order ord = createOrder(accountId, false);
            
            // Créer des OrderItems pour chaque commande
            OrderItem oi1 = createOrderItem(ord, pbe, 10, false); // 10 articles pour chaque OrderItem
            OrderItem oi2 = createOrderItem(ord, pbe, 20, false); // 20 articles pour chaque OrderItem

            orders.add(ord);
        }

        // Insérer les commandes et leurs items si nécessaire
        if (doInsert && !orders.isEmpty()) {
            insert orders;
        }

        return orders;
    }
}