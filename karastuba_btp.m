function xy = karatsuba(x, y, base)
if (x <= base && y <= base) || x == 0 || y == 0
    xy = x .* y;
    return;
else
 
    m = ceil(log2(max(noDigits(x, base), noDigits(y, base))));
    splitpoint = base.^(2^m/2);
    xl = floor(x ./ splitpoint);
    xr = x - xl.*splitpoint;
    yl = floor(y ./ splitpoint);
    yr = y - yl.*splitpoint;
    
    zl = karatsuba(xl,yl,base);
    zr = karatsuba(xr,yr,base);
    zmiddle = karatsuba( xl+xr , yl+yr, base);
    xy = splitpoint^2.*zl +  splitpoint.*(zmiddle - zl - zr) + zr;
end
end
function d = noDigits(n,base)
d = floor(log10(n) / log10(base)) + 1;
end