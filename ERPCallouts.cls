public with sharing class ERPCallouts {
    public static void handleInsert(Map<Id, Contract> newMap){
        sendDataToCIA(newMap.keySet());
    }

    public static void handleUpdate(List<Contract> newContracts, Map<Id, Contract> oldMap){
        Set<Id> contractIds = new Set<Id>();

        for(Contract con : newContracts){
            //Maturity__c veya DebitMemoMaturityDay__c field'leri değişmişse:
            if((con.Maturity__c != oldMap.get(con.Id).Maturity__c) || (con.DebitMemoMaturityDay__c != oldMap.get(con.Id).DebitMemoMaturityDay__c)){
                contractIds.add(con.Id);
            }
        }

        if(!contractIds.isEmpty()){
            sendDataToCIA(contractIds);
        }
    }

    // CIA ERP'ye veri gönderen metod
    @future(callout=true)
    public static void sendDataToCIA(Set<Id> contractIds) {
        // HTTP isteği oluştur
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint('https://ilgarcardpreprod.solmaz.com/swagger-ui/');
        request.setMethod('PUT'); //upsert
        
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Basic bWF0dXJpdHl1c2VyOm10ckRyZDIxIS4=');

        ILGARContract jsonContract = new ILGARContract(contractIds);
        System.debug('jsonContract: ' + jsonContract);
        // Veriyi JSON formatına dönüştür
        String requestBody = JSON.serialize(jsonContract);
        System.debug('requestBody: ' + requestBody);
        request.setBody(requestBody);

        // İsteği gönder ve yanıtı kontrol et
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                System.debug('Contracts sent to CIA ERP successfully: ' + response.getBody());
            } else {
                System.debug('Failed to send contracts to CIA ERP: ' + response.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error sending contracts to CIA ERP: ' + e.getMessage());
        }
    }

    public class ILGARContract {
        //Aşağıdaki dördü parent Acc field'leri:
        public String ilgarCompId;
        public String ifsCompId;
        public String crmCompId;
        public String ciaCompId;

        public List<IlgarMaturity> ilgarMaturity;

        public ILGARContract(Set<Id> contractIds){
            List<Contract> contracts = [SELECT Id, ServiceType__c, Maturity__c, DebitMemoMaturityDay__c, LastModifiedBy.Name,
                                        AccountId, Account.IlgarId__c, Account.IFSId__c, Account.CIAID__c
                                        FROM Contract
                                        WHERE Id IN :contractIds];

            this.ilgarMaturity = new List<IlgarMaturity>();

            for(Contract con : contracts){
                //Önce parent Acc field'leri populate ediliyor:
                this.ilgarCompId = con.Account.IlgarId__c;
                this.ifsCompId = con.Account.IFSId__c;
                this.crmCompId = con.AccountId;
                this.ciaCompId = con.Account.CIAID__c;

                //IlgarMaturity field'leri:
                IlgarMaturity contractData = new IlgarMaturity();
                contractData.maturityCode = con.ServiceType__c;
                contractData.maturityDay = String.valueOf(con.Maturity__c);
                contractData.debitMemoMaturityDay = String.valueOf(con.DebitMemoMaturityDay__c);
                contractData.modifiedUser = con.LastModifiedBy.Name;
                this.ilgarMaturity.add(contractData);
            }
        }
    }

    public class IlgarMaturity {
        public String maturityCode;
        public String maturityDay;
        public String debitMemoMaturityDay;
        public String modifiedUser;
    }
}