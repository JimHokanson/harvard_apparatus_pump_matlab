classdef serial_port
    %
    %
    %   Not sure what I want here ....
    
    properties
        friendly_name
        connected
    end
    
    methods (Static)
        function getAll()
            
        end
    end
    
end

function h__getInfo()

%Based on:
%https://www.mathworks.com/matlabcentral/fileexchange/45675-identify-serial-com-devices-by-friendly-name-in-windows

if ~ispc()
    error('This part of the code is only supported on Windows OS')
end

[~,list] = system('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum /s /f COM /c /t REG_SZ');


%Why doesn't this work.
%%https://stackoverflow.com/questions/45512468/why-am-i-getting-so-many-results-from-a-windows-registry-query-using-value-name
%[~,list] = dos('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum /v FriendlyName /s /f "COM1" /t REG_SZ');



%TODO: I'm not sure how to tell if we don't have anything?

%list =>
% HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\ACPI\PNP0501\1
%     FriendlyName    REG_SZ    Communications Port (COM1)
% 
% HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\ACPI\PNP0501\1\Device Parameters
%     PortName    REG_SZ    COM1
% 
% HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_067B&PID_2303\5&212ac8fc&0&8
%     FriendlyName    REG_SZ    Prolific USB-to-Serial Comm Port (COM3)
% 
% HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_067B&PID_2303\5&212ac8fc&0&8\Device Parameters
%     PortName    REG_SZ    COM3


lines = sl.str.getLines(list);

% temp = regexp(list,'(HKEY_LOCAL_MACHINE[^s]*)\s+FriendlyName\s+REG_SZ\s+([^\n]*)','tokens'); 
% temp2 = regexp(list,'REG_SZ\s+(COM\d+)','tokens');

%                   
%
%
%
%                                                                               .*? (match chars until next REG_SZ)
temp = regexp(list,'(HKEY_LOCAL_MACHINE[^s]*)\s+FriendlyName\s+REG_SZ\s+([^\n]*).*?REG_SZ\s+(COM\d+)','tokens');






%---------------------------------------------------------------------
% % serial_registry_key = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
% % % Find connected serial devices and clean up the output
% % [~, list] = dos(['REG QUERY ' serial_registry_key]);
% % % HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM
% % %     \Device\ProlificSerial0    REG_SZ    COM3
% % %     \Device\Serial0    REG_SZ    COM1
% % 
% % list = strread(list,'%s','delimiter',' ');
% % coms = 0;
% % for i = 1:numel(list)
% %   if strcmp(list{i}(1:3),'COM')
% %       if ~iscell(coms)
% %           coms = list(i);
% %       else
% %           coms{end+1} = list{i};
% %       end
% %   end
% % end
%------------------------------------------------------------------------
% % % % % 
% % % % % s = serialInfo;
% % % % % coms = s.SerialPorts;
% % % % % 
% % % % % %reg query <KeyName> [{/v <ValueName> | /ve}] [/s] [/se <Separator>] [/f <Data>] [{/k | /d}] [/c] [/e] [/t <Type>]
% % % % % 
% % % % % %https://technet.microsoft.com/en-us/library/cc742028(v=ws.11).aspx
% % % % % 
% % % % % [~,list] = dos('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum /s /v "COM1" /t REG_SZ');
% % % % % 
% % % % % 
% % % % % [~,list] = dos('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum /s /f COM /c /t REG_SZ');
% % % % % 
% % % % % [~,list] = dos('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum /v FriendlyName /s /f "COM1" /t REG_SZ');
% % % % % 
% % % % % [~,list] = dos('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum /v FriendlyName /s /f "COM1" /c /e /t REG_SZ');
% % % % % 
% % % % % %Computer\HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM
% % % % % [~, list] = dos(['REG QUERY ' 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM ']);
% % % % % % HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM
% % % % % %     \Device\ProlificSerial0    REG_SZ    COM3
% % % % % %     \Device\Serial0    REG_SZ    COM1
% % % % % 
% % % % % %Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports
% % % % % %Computer\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\DOS Devices
% % % % % %Computer\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Enum\USB\VID_067B&PID_2303\5&212ac8fc&0&8
% % % % % %Computer\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Enum\ACPI\PNP0501\1
% % % % % 
% % % % % %--------------------------------------------------------------------------
% % % % % key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
% % % % % % Find all installed USB devices entries and clean up the output
% % % % % [~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
% % % % % %vals =>
% % % % % % HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_067B&PID_2303\5&212ac8fc&0&8
% % % % % %     FriendlyName    REG_SZ    Prolific USB-to-Serial Comm Port (COM3)
% % % % % % 
% % % % % % HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_1004&PID_61F9&MI_00\6&1496d3bc&1&0000
% % % % % %     FriendlyName    REG_SZ    LG Phoenix 2
% % % % % % 
% % % % % % HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_1004&PID_61F9&MI_01\6&1496d3bc&1&0001
% % % % % %     FriendlyName    REG_SZ    ADB Interface
% % % % % % 
% % % % % % End of search: 3 match(es) found.
% % % % % 
% % % % % 
% % % % % vals = textscan(vals,'%s','delimiter','\t');
% % % % % vals = cat(1,vals{:});
% % % % % out = 0;
% % % % % % Find all friendly name property entries
% % % % % for i = 1:numel(vals)
% % % % %   if strcmp(vals{i}(1:min(12,end)),'FriendlyName')
% % % % %       if ~iscell(out)
% % % % %           out = vals(i);
% % % % %       else
% % % % %           out{end+1} = vals{i};
% % % % %       end
% % % % %   end
% % % % % end
% % % % % %--------------------------------------------------------------------------
% % % % % 
% % % % % 
% % % % % % Compare friendly name entries with connected ports and generate output
% % % % % for i = 1:numel(coms)
% % % % %   match = strfind(out,[coms{i},')']);
% % % % %   ind = 0;
% % % % %   for j = 1:numel(match)
% % % % %       if ~isempty(match{j})
% % % % %           ind = j;
% % % % %       end
% % % % %   end
% % % % %   if ind ~= 0
% % % % %       com = str2double(coms{i}(4:end));
% % % % % % Trim the trailing ' (COM##)' from the friendly name - works on ports from 1 to 99
% % % % %       if com > 9
% % % % %           length = 8;
% % % % %       else
% % % % %           length = 7;
% % % % %       end
% % % % %       devs{i,1} = out{ind}(27:end-length);
% % % % %       devs{i,2} = com;
% % % % %   end
% % % % % end

end
