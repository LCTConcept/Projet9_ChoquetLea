public class BatchEmailSender {

    public static void sendBatchCompletionEmail(String emailAddress, String jobId) {
        
            
            // Récupérer les informations sur le batch via AsyncApexJob
            AsyncApexJob job = [
                SELECT ApexClassId, TotalJobItems, NumberOfErrors, CreatedDate, CompletedDate, JobItemsProcessed
                FROM AsyncApexJob
                WHERE Id = :jobId
                LIMIT 1
            ];

            // Construire le corps de l'email
            String emailBody = 'Le batch a terminé son exécution.\n\n';
            emailBody += 'Nom de la classe : ' + job.ApexClassId + '\n';
            emailBody += 'Nombre total d\'éléments : ' + job.TotalJobItems + '\n';
            emailBody += 'Nombre d\'éléments traités : ' + job.JobItemsProcessed + '\n';
            emailBody += 'Nombre d\'erreurs : ' + job.NumberOfErrors + '\n';
            emailBody += 'Date de début : ' + job.CreatedDate + '\n';
            emailBody += 'Date de fin : ' + job.CompletedDate + '\n';

            // Préparer l'email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { emailAddress });
            mail.setSubject('Rapport d\'exécution du batch');
            mail.setPlainTextBody(emailBody);
            
            try {
            // Envoyer l'email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email envoyé avec succès à : ' + emailAddress);
         
        } catch (Exception e) {
            System.debug('Échec de l\'envoi de l\'email : ' + e.getMessage());

        }
        
    }

    // Exception personnalisée pour gérer les erreurs liées aux emails
    public class EmailException extends Exception {}
}