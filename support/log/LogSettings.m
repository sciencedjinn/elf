classdef LogSettings < handle
	properties 
        Level(1,1) LogLevel = LogLevel.INFO;
        Dest(1,1) = 1; % Output destination, can be 1 (standard out), a file handle or a uieditfield handle
	end
end