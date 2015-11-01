%%
%

function [index,x] = histogram_weights(mu, sigma, denom)
    fi = 1.0/(sigma*sqrt(2*pi));
    centerx = mu;
    maxval = gauss_distribution(centerx,fi,mu,sigma);
    x = zeros(256,1);
    index = 1:256;
    for i = index
        xx = i/255;
        x(i) = gauss_distribution(xx,fi,mu,sigma)/maxval/denom;
        if x(i)>1.0
            x(i) = 1.0;
        end
    end
end