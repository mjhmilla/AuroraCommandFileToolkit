function [value,valueStr]=convertToAuroraFloatingPointFormat600A(...
                                valueIn,typeIn,unitIn,isRelative, auroraConfig)

order = floor(log10(valueIn));

valueStr='';
value=nan;


if(strcmp(unitIn,'string'))
  valueStr=valueIn;
  value=nan;
else
  switch typeIn

    case 'time'

      leadingDigits = nan;
      followingDigits=nan;

      switch unitIn
        case 'ms'
          if(order < 0)
            leadingDigits = 1;
            followingDigits=1;
          else
            leadingDigits = order+1;
            followingDigits = 1;
          end

        case 's'
          if(order < 0)
            leadingDigits = 1;
            followingDigits=auroraConfig.numberOfDigits;
          else
            leadingDigits = order+1;
            followingDigits = auroraConfig.numberOfDigits-leadingDigits;
          end

        otherwise
            assert(0,'Error: time must be in units of ms or s');
      end

      assert(leadingDigits <= auroraConfig.numberOfDigits, ...
         ['Error: The Aurora 600A might have problems displaying ',...
         sprintf('%f',valueIn),': because it cannot be expressed',...
         ' in ',num2str(auroraConfig.numberOfDigits),' digits']);

      assert(followingDigits >= 0, ...
             ['Error: The Aurora 600A might have problems displaying ',...
             sprintf('%f',valueIn),': because it cannot be expressed',...
             ' in ',num2str(auroraConfig.numberOfDigits),' digits']);


      formatStr = sprintf('%i.%i',leadingDigits,followingDigits);
      formatStr = ['%',formatStr,'f'];
      valueStr = sprintf(formatStr,valueIn);

    case 'bool'
      valueStr = sprintf('%i',valueIn);  

    case 'integer'
      valueStr = sprintf('%i',valueIn);  


    otherwise

      leadingDigits = nan;
      followingDigits=nan;

      if(order < 0)
          leadingDigits = 1;
          followingDigits=auroraConfig.numberOfDigits;
      else
          leadingDigits = order+1;
          followingDigits=auroraConfig.numberOfDigits-leadingDigits;
      end

      assert(leadingDigits <= auroraConfig.numberOfDigits, ...
             ['Error: The Aurora 600A might have problems displaying ',...
             sprintf('%f',valueIn),': because it cannot be expressed',...
             ' in ',num2str(auroraConfig.numberOfDigits),' digits']);

      assert(followingDigits >= 0, ...
             ['Error: The Aurora 600A might have problems displaying ',...
             sprintf('%f',valueIn),': because it cannot be expressed',...
             ' in ',num2str(auroraConfig.numberOfDigits),' digits']);


      formatStr = sprintf('%i.%i',leadingDigits,followingDigits);
      formatStr = ['%',formatStr,'f'];
      valueStr = sprintf(formatStr,valueIn);      
  end


  if(~isnan(isRelative))
    if(isRelative==1)
      assert(strcmp(typeIn,'length') || strcmp(typeIn,'force'),...
             'Error: isRelative can only be applied to length or force');
      if(valueIn > 0)
        valueStr = ['+',valueStr];
      end
    end
  end
  value = str2double(valueStr);
end

