classdef pump_logger < handle
    %
    %   Class:
    %   harvard.pump.elite_11.pump_logger
    
    properties
        start_time
        cmd
        wait_duration
        cmd_duration
        time_at_wait_start
        time_at_cmd_start
        time_at_cmd_finish
        failed
        
        I = 0
        h_tics
    end
    
    methods (Static)
        %Singleton
        function obj = getInstance()
            %
            %   harvard.pump.elite_11.pump_logger.getInstance
            
            persistent instance
            
            if isempty(instance)
                instance = harvard.pump.elite_11.pump_logger();
            end
            obj = instance;
        end
    end
    
    methods (Access=private)
        function obj = pump_logger()
            n = 10000;
            obj.start_time = now*86400;
            obj.cmd = cell(1,n);
            obj.wait_duration = zeros(1,n);
            obj.cmd_duration = zeros(1,n);
            obj.time_at_wait_start = zeros(1,n);
            obj.time_at_cmd_start = zeros(1,n);
            obj.time_at_cmd_finish = zeros(1,n);
            obj.h_tics = zeros(1,n,'like',tic);
            obj.failed = true(1,n);
        end
    end
    methods
        function I2 = logWaitStart(obj,cmd)
            I2 = obj.I + 1;
            if I2 > 10000
                I2 = 1;
            end
            obj.I = I2;
            obj.cmd{I2} = cmd;
            obj.h_tics(I2) = tic;
            obj.time_at_wait_start(I2) = now()*86400 - obj.start_time;
        end
        function logCmdStart(obj,I2)
            obj.wait_duration(I2) = toc(obj.h_tics(I2));
            obj.time_at_cmd_start(I2) = now()*86400 - obj.start_time;
        end
        function logCmdStop(obj,I2)
            obj.cmd_duration(I2) = toc(obj.h_tics(I2));
            obj.time_at_cmd_finish(I2) = now()*86400 - obj.start_time;
            obj.failed(I2) = false;
        end
    end
end

