function distance = crowding_distance(particle, population)
    % 修改ismember调用方式
    N = size(population,1);
    distance = 0;
    
    for i = 1:size(population,2)
        [sorted, idx] = sort(population(:,i));
        % 替换原来的ismember调用
        pos = find(ismember(population, particle, 'rows'), 1); % 添加',1'确保返回单个值
        if isempty(pos)
            pos = 1;
        end
        
        if pos == 1 || pos == N
            distance = distance + Inf;
        else
            distance = distance + (sorted(pos+1) - sorted(pos-1)) / (max(population(:,i)) - min(population(:,i)));
        end
    end
end