function [value,valueStr]=convertToAuroraFloatingPointFormat600A(valueIn)

order = floor(log10(valueIn));

leadingDigits = nan;
followingDigits=nan;

if(order < 0)
    leadingDigits = 1;
    followingDigits=6;
else
    leadingDigits = order+1;
    followingDigits=6-leadingDigits;
end

formatStr = sprintf('%i.%i',leadingDigits,followingDigits];
formatStr = ['%',formatStr,'f'];
valueStr = sprintf(formatStr,valueIn);
value = str2double(valueStr);