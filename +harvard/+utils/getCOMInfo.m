function varargout = getCOMInfo()
%
%   s = harvard.utils.getCOMInfo()
%
%   Output
%   ------
%   
%
%   Improvements
%   ------------
%   This doesn't handle stale info ... (USB unplugged)

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


lines = harvard.sl.str.getLines(list);

% temp = regexp(list,'(HKEY_LOCAL_MACHINE[^s]*)\s+FriendlyName\s+REG_SZ\s+([^\n]*)','tokens'); 
% temp2 = regexp(list,'REG_SZ\s+(COM\d+)','tokens');

%                   
%
%
%
%                                                                               .*? (match chars until next REG_SZ)
temp = regexp(list,'(HKEY_LOCAL_MACHINE[^s]*)\s+FriendlyName\s+REG_SZ\s+([^\n]*).*?REG_SZ\s+(COM\d+)','tokens');

temp2 = vertcat(temp{:});

s = cell2struct(vertcat(temp{:}),{'reg','friendly_name','name'},2);

if nargout
    varargout{1} = s;
else
    for i = 1:length(s)
        disp(s(i))
    end
end

%TODO: Extract root type
%=> value following Enum in reg entry

end