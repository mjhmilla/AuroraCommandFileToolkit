function unitType = getUnitType600A(unitName)

unitType = '';

if(length(unitName))
    switch unitName
        case 'um'
            unitType = 'length';
        case 'mm'
            unitType = 'length';
        case 'Lo'
            unitType = 'length';
        case 'Lf'
            unitType = 'length';
        case 'volts'
            unitType = 'volt';
        case 'mN'
            unitType = 'force';
        case 'N'
            unitType = 'force';
        case 'gm'
            unitType = 'force';
        case 'kg'
            unitType = 'force';
        case 'Fmax'
            unitType = 'force';            
        case 'Pa'
            unitType = 'pressure';            
        case 'kPa'
            unitType = 'pressure';            
        case 'ms'
            unitType = 'time';            
        case 's'
            unitType = 'time';            
        case 'Hz'
            unitType = 'frequency';            
        case 'sample'
            unitType = 'sample';
        case 'bool'
            unitType = 'bool';
        case 'pattern'
            unitType = 'pattern';
        case 'number'
            unitType='number';
        otherwise assert(0, ['Error: unrecognized unit: ',unitName]);
    end
end

