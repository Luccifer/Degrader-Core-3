%% mix(x,y,a) - GLSL/Metal Language Shading
% Returns the linear blend of x and y implemented as: x + (y ? x ) * a.
% a must be a value in the range 0.0 ... 1.0. If a is not in the range 0.0 ... 1.0, the return values are undefined.
%
function y = mix (x, y, a) 
    y = (x + (y - x) * a);
end