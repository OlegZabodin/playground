public with sharing class ChildAuditorController {

    public static final String MAIN_TEMPLATE = 'SELECT ID, {0} FROM {1} WHERE Id=\'\'{2}\'\' LIMIT 1';
    public static final String INNER_TEMPLATE = '(SELECT ID FROM {0} LIMIT 2000)';
    public static final String COMMA = ',';
    public static final String EMPTY_STR = '';
    public static final String VALUE_STR = 'value';
    public static final String NAME_STR = 'name';

    public static final Integer CHILD_FIELD_LIMIT = 18;


    public ChildAuditorController() {

    }
    
    @AuraEnabled
    public static ChildAuditorWrapper getData(String recordId) {
        ChildAuditorWrapper wrapper = new ChildAuditorWrapper();
        if(String.isNotBlank(recordId)) {
            String targetSObjectName = getTargetObjectName(recordId);
            List<String> relatedChildNames = getRelatedChildNames(recordId);
            List<String> queriesList = buildQueriesList(targetSObjectName, relatedChildNames, recordId);
            List<SObject> resultList = retriveData(queriesList);
            wrapper = new ChildAuditorWrapper(resultList, relatedChildNames, targetSObjectName);
            return wrapper;
        } else return wrapper;
    }

    public static List<SObject> retriveData(List<String> queriesList) {
        List<SObject> resultList  = new List<SObject>();
        if (queriesList.size() > 0) {
            for (String query : queriesList) {
                resultList.addAll(Database.query(query));
            }
        }
        return resultList;
    }

    public static String getTargetObjectName(String recordId) {
        SObjectType sType = Id.valueOf(recordId).getSobjectType();
        Schema.DescribeSObjectResult dResult = sType.getDescribe();
        return dResult.getName();
    }

    public static List<String> getRelatedChildNames(String recordId) {
        List<String> relatedChildNames = new List<String>();
        SObjectType sType = Id.valueOf(recordId).getSobjectType();
        Schema.DescribeSObjectResult dResult = sType.getDescribe();
        List<ChildRelationship> childs = dResult.getChildRelationships();
        for(ChildRelationship cR : childs) {
            String name = cR.getRelationshipName();
            if (String.isNotBlank(name)) {
                relatedChildNames.add(name);
            }
        }
        return relatedChildNames;
    }

    public static List<String> buildQueriesList(String sOType, List<String> relatedFieldTypes, String recordId) {
        List<String> queriesList = new List<String>();
        List<List<String>> splitedFields = splitChildFields(relatedFieldTypes);
        for (List<String> fields : splitedFields) {
            String innerPart = buildInnerQuery(fields);
            String query = String.format(MAIN_TEMPLATE, new List<String> {innerPart, sOType, recordId}); 
            queriesList.add(query);
        }
        return queriesList;
    }

    public static List<List<String>> splitChildFields(List<String> fields) {
        List<List<String>> childFieldsList = new List<List<String>>();
        for (Integer index = 0; index < fields.size(); index += CHILD_FIELD_LIMIT) {
            List<String> splitedPart = new List<String>();
            for(Integer innerIndex1 = 0, innerIndex2 = index; innerIndex1 < CHILD_FIELD_LIMIT; innerIndex1++) {
                if (innerIndex2 < fields.size()) {
                    splitedPart.add(fields.get(innerIndex2));
                }
                innerIndex2++;
            }
            childFieldsList.add(splitedPart);
        }
        return childFieldsList;
    } 

    public static String buildInnerQuery(List<String> relatedFieldTypes) {
        String innerPart = '';
        for (Integer index = 0; index < relatedFieldTypes.size(); index++) {
            String typeQueryPart = String.format(INNER_TEMPLATE, new List<String> {relatedFieldTypes.get(index)});
            innerPart += typeQueryPart + (index + 1 == relatedFieldTypes.size() ? EMPTY_STR : COMMA);
        }
        return innerPart;
    }

    public class ChildAuditorWrapper {
        @AuraEnabled
        public List<Map<String, Object>> dataList = new List<Map<String, Object>>();
        
        public ChildAuditorWrapper(){}
        
        public ChildAuditorWrapper(List<SObject> data, List<String> fields, String objectTypeName) {
            for (String field : fields) {
                Map<String, Object> entry = new Map<String, Object>();
                for (SObject record : data) {
                    if (hasSObjectsField(field, record)) {
                        Object objField = record.getSObjects(field);
                        List<SObject> records = (List<SObject>) objField;
                        String regularFieldName = getPopularFieldName(field, objectTypeName);
                        entry.put(NAME_STR, regularFieldName);
                        entry.put(VALUE_STR, records.size());
                    }
                }
                if (!entry.isEmpty()) {
                    dataList.add(entry);
                }
            }
        }
    }

    public static boolean hasSObjectsField(String field, SObject sObj){
        Boolean hasSObjectsField = false;
        Map<String, Object> populatedListMap = sObj.getPopulatedFieldsAsMap(); 
        for (String key : populatedListMap.keySet()) {
            if (key == field) {
                hasSObjectsField = true;
            }
        }
        return hasSObjectsField;
    }

    public static String getPopularFieldName(String apiFieldName, String objectTypeName) {
        String name = apiFieldName;
        SObjectType sType = Schema.getGlobalDescribe().get(objectTypeName);
        List<ChildRelationship> cRelationships = sType.getDescribe().getChildRelationships();
        for (ChildRelationship cR : cRelationships) {
            if (cR.getRelationshipName() == apiFieldName) {
                name = cR.getChildSObject().getDescribe().getLabelPlural();
            }
        }
        return name;
    }
}
