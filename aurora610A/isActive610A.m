function isActive = isActive610A(timeIn,programMetaData)

isActive=0;


if(~isempty(programMetaData.Stimulus_time))
  assert(size(programMetaData.Stimulus_time,2)==2);

  for i=1:1:size(programMetaData.Stimulus_time,1)

    assert(programMetaData.Stimulus_time(i,2) ...
         > programMetaData.Stimulus_time(i,1));

    if(timeIn >= programMetaData.Stimulus_time(i,1) ...
        && timeIn <= programMetaData.Stimulus_time(i,2))
      isActive=1;
    end

  end

end