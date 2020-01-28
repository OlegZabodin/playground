({
    initComponent : function(component, event, helper) {
        var action = component.get('c.getData')
        action.setParams({
            'recordId': component.get('v.recordId')
        });
        action.setCallback(this, (response) => {
            var state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var wrapper = response.getReturnValue();
                component.set('v.dataList', wrapper.dataList);
            } else {
                console.debug('------ error -----');
            }
        });
        $A.enqueueAction(action);
    }
})
