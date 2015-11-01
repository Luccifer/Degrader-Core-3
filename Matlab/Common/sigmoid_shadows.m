%%
%

function y = sigmoid_shadows(x, weight, width, ascent)
    y = weight./exp((x.*ascent)/width ).*width;
end
