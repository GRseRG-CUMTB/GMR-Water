function groups = CP_combination(cell_bands)

    suffixes = unique(cellfun(@(x) x(2:end), cell_bands, 'UniformOutput', false));
    groups = {};
    
    for i = 1:length(suffixes)
        suffix = suffixes{i};
        group = cell_bands(endsWith(cell_bands, suffix) & ...
                         (startsWith(cell_bands, 'L') | startsWith(cell_bands, 'C')));

        if numel(group) == 2
            groups{end+1} = group;
        end
    end
end
