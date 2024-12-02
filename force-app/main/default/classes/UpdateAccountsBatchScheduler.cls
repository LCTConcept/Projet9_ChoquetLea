global class UpdateAccountsBatchScheduler implements Schedulable {
    
    private String emailAddress;

    // Constructeur sans paramètre pour la planification via l'interface
    public UpdateAccountsBatchScheduler() {
        this.emailAddress = 'emailpardefault@email.com'; //Email par défaut, qui sera modifié grâce au setter
    }

    // Méthode setter pour modifier l'adresse mail 
    public void setEmailAddress(String email) {
        this.emailAddress = email;
    }

    global void execute(SchedulableContext sc) {
        // Exécution du batch
        Database.executeBatch(new UpdateAccounts(this.emailAddress), 200);
    }
 }