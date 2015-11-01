%%  gausConv(x,fi,mu,sigma) - base Gaus distribution convolution
%
%
function t = gauss_distribution(x,fi,mu,sigma)
    t = fi * exp(- (x-mu).^2/(2*sigma^2));
end