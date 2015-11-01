%%  gausConv(x,fi,mu1,sigma1,mu2,sigma2) - combined base Gauss distribution convolution
%
%
function y = gauss_distribution2(x,fi,mu1,sigma1,mu2,sigma2)
    if (sigma1==0) || (sigma2==0),
        error('The sigma value must be non-zero.');
    end

    c1Index=(x<=mu1);
    c2Index=(x>=mu2);
    y1 = gauss_distribution(x,fi,mu1,sigma1).*c1Index + (1-c1Index);
    y2 = gauss_distribution(x,fi,mu2,sigma2).*c2Index + (1-c2Index);

    y = y1.*y2;
end