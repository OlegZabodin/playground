@isTest

public class ChildAuditorControllerTest {

    public ChildAuditorControllerTest() {

    }

    @testSetup static void initializeData() {
        Account ac = new Account(Name = 'testAccount');
        insert ac;
        List<WorkOrder> woList = new List<WorkOrder>();
        for (Integer i = 0; i < 10; i++) {
            WorkOrder wo = new WorkOrder();
            wo.AccountId = ac.Id;
            woList.add(wo);
        }
        insert woList;

        Account ac2 = new Account(Name = 'noChildAcc');
        insert ac2;
    }

    @isTest static void testGetData() {
        Account testObj = [SELECT Id FROM Account WHERE Name = 'testAccount'];
        ChildAuditorController.ChildAuditorWrapper result = ChildAuditorController.getData(testObj.Id);

        List<WorkOrder> actualWorkOrderList= [SELECT Id FROM WorkOrder WHERE AccountId =: testObj.Id];

        Map<String, Object> childObjectResult = result.dataList.get(0);

        System.assert(childObjectResult.get('name') == 'Work Orders');
        System.assert(childObjectResult.get('value') == actualWorkOrderList.size());
    }

    @isTest static void testGetDataNoResult() {
        Account testObj = [SELECT Id FROM Account WHERE Name = 'noChildAcc'];
        ChildAuditorController.ChildAuditorWrapper result = ChildAuditorController.getData(testObj.Id);

        System.assert(result.dataList.size() == 0);
    }

    @isTest static void testGetDataWrongParam() {
        ChildAuditorController.ChildAuditorWrapper result = ChildAuditorController.getData('');

        System.assert(result.dataList.size() == 0);
    }
}
