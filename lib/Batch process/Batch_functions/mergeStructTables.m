function mergedStruct = mergeStructTables(struct1, struct2)
    fields1 = fieldnames(struct1);
    fields2 = fieldnames(struct2);
    
    mergedStruct = struct();
    for i = 1:min(numel(fields1), numel(fields2))
        T1 = struct1.(fields1{i});
        T2 = struct2.(fields2{i});
        

        keyColumns = T1.Properties.VariableNames(1:4);
        mergedTable = outerjoin(T1, T2, 'Keys', keyColumns, 'MergeKeys', true);
        
        mergedStruct.(fields1{i}) = mergedTable;
    end
end
