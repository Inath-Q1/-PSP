function d = diversity_metric(particle)
    % 计算粒子多样性度量
    % 这里使用粒子各维度的标准差作为多样性度量
    d = std(particle);
end