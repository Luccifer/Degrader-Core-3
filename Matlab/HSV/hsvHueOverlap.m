%%
%
%

function z = hsvHueOverlap(x,ramp,width)
    rx = ramp(1);
    ry = ramp(2);
    rz = ramp(3);
    rw = ramp(4);
    
    te = 1.0/360.0;
    denom = te*width;

    where = clamp(sign(rw-rx),0,1);
    sigma = mix((ry-360-rz)*denom, (rz-ry)*denom, where);
    mu = mix((rx-360+rw)*0.5, (rw+rx)*0.5, where);
    z = hsvHueOverlapNormal(x*te,mu*te,sigma,1,ramp);

%    sigma= (rz-ry);
%    mu   = (rw+rx)/2.0;
%     
%     if ry>rz 
%         sigma = (360.0-ry+rz);
%         %if x>180.0
%         %    mu    = (ry+rz);
%         %else
%          mu    = (ry+rz); %(360.0-ry-rz)/2.0;
%         
%         %end        
%     end
% 
%     z = hsvHueOverlapNormal(x,mu,sigma,1,ramp);
end

function z = hsvHueOverlapNormal(x,mu,sigma,denom,ramp)
    lenx = length(x);
    z = zeros(lenx);
    for i=1:lenx
        xx = x(i);
        mux = mix(mu, mu+1, clamp(sign(xx*360-ramp(4)*2),0,1));
        z(i) = clamp(gauss_distribution(xx,1,mux,sigma)/denom,0,1);
    end
end
