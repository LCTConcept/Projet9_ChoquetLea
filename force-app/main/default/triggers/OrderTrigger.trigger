trigger OrderTrigger on Order (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountHelper.calculateOrderNetAmountBeforeUpdate(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountHelper.updateAccountRevenueAfterUpdate(Trigger.new);
    }
}