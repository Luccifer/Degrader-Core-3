bins = -10:380;

reds    = [315.0, 345.0, 15.0,   45.0];
yellows = [15.0,  45.0, 75.0,  105.0];
greens  = [75.0, 105.0, 135.0, 165.0];
cyans   = [135.0, 165.0, 195.0, 225.0];
blues   = [195.0, 225.0, 255.0, 285.0];
magenta = [255.0, 285.0, 315.0, 345.0];

colors = ['r' 'y' 'g', 'c', 'b', 'm'];

circle = [reds', yellows', greens', cyans', blues', magenta']';

f = figure(1);
clf(f)
grid on;
hold on;

i=1;
for r = circle'
    n=hsvHueOverlap(bins,r,1.0); p = plot(bins,n,colors(i));
    i=i+1;
end

axis([-10, 360, 0, 1])
