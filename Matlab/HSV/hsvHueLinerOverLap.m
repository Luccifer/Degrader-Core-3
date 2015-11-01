%%
%
%
function z = hsvHueLinerOverLap(x,ramp,width)
    z = zeros(length(x));
    for i=1:length(x);
        xx=x(i);
        z(i) = hsvHueLinerOverLapX(xx,ramp,width);
    end
end

function z = hsvHueLinerOverLapX(hue,ramp,width)
    z = 0;
       
    if (ramp(1)<=hue && hue<=ramp(4))
    
        s = (ramp(4)-ramp(1))/2.0;
        h = ramp(4)-hue;
        z = 1.0-abs(s-h)/s;
    
    else
        if ramp(4)<ramp(1)
            if (hue>=ramp(1) && hue<=360.0) % reds
                h = 360.0-hue;
                z = 1.0-h/(360.0-ramp(1));
            elseif (hue>=0.0 && hue<=ramp(4))
                z = 1.0-hue/ramp(4);          
            end               
        end
    end
    z=z/width;
end

