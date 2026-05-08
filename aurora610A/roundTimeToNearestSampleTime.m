function timeRounded = roundTimeToNearestSampleTime(time, auroraConfig)

timeRounded = round(time*auroraConfig.analogToDigitalSampleRateHz)...
                    /auroraConfig.analogToDigitalSampleRateHz;
