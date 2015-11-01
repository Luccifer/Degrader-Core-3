%% clamp(v,min,max) - GLSL/Metal Language Shading
%  Returns fmin(fmax(x, minval), maxval). Results are undefined if minval > maxval.
%

function y = clamp(v, minval, maxval)
    y = min(max(v, minval), maxval);
end
