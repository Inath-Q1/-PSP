function [fronts, ranks] = non_dominated_sorting(population, fitness)
    % 非支配排序实现
    N = size(population,1);
    dominated = cell(N,1);
    domination_count = zeros(N,1);
    ranks = zeros(N,1);
    
    for i = 1:N
        for j = 1:N
            if i ~= j
                % 检查支配关系
                if all(fitness(i,:) <= fitness(j,:)) && any(fitness(i,:) < fitness(j,:))
                    dominated{i} = [dominated{i}, j]; % 使用逗号连接
                elseif all(fitness(j,:) <= fitness(i,:)) && any(fitness(j,:) < fitness(i,:))
                    domination_count(i) = domination_count(i) + 1;
                end
            end
        end
    end
    
    current_front = find(domination_count == 0);
    current_rank = 1;
    fronts = cell(1,1);
    
    while ~isempty(current_front)
        fronts{current_rank} = current_front;
        next_front = [];
        
        for i = 1:length(current_front)
            idx = current_front(i);
            ranks(idx) = current_rank;
            
            if ~isempty(dominated{idx})
                for j = 1:length(dominated{idx})
                    dominated_idx = dominated{idx}(j);
                    domination_count(dominated_idx) = domination_count(dominated_idx) - 1;
                    if domination_count(dominated_idx) == 0
                        next_front = [next_front, dominated_idx];
                    end
                end
            end
        end
        
        current_front = next_front;
        current_rank = current_rank + 1;
    end
end