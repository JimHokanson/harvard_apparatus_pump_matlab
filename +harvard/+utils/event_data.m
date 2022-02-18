classdef (ConstructOnLoad) event_data < event.EventData
    %
    %   Class:
    %   harvad.utils.event_data
    %
    %   ???? ... 
    %
    %   This class is a valid input for a notify call. Apparently the data
    %   sent out for a notify call must inherit from the listed superclass
    %   and must be ConstructOnLoad. 
    %
    %   
    %   https://www.mathworks.com/help/matlab/matlab_oop/class-with-custom-event-data.html
    %
    %   See Also
    %   --------
    %   notify
    %   

    
   properties
      value
   end
   
   methods
      function obj = event_data(value)
         obj.value = value;
      end
   end
end