function names = getSerialPortNames()
%
%   names = harvard.getSerialPortNames()

%TODO: Can we detect busy ports? Matlab can ...

%Wei TODO: clean this up

    serial_info = instrhwinfo('serial');

    %This is for when no COM port is detected (which should never happen)
    %or for when multiple ports are detected ...
    
    %===============================================
    %            ***** EDIT HERE *******
    %===============================================
    DEFAULT_COM_PORT_TO_USE = 'COM3';
    
    com_ports = serial_info.SerialPorts;
    

end