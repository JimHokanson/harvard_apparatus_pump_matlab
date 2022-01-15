# harvard_apparatus_pump_matlab #

Control of Harvard Apparatus pumps using MATLAB.

Currently only pumps that use the 'Model 44' protocol are supported. In particular this code has only been tested with a 'PHD 2000 Programmable' pump. I have not yet built-in support for complicated sequences to be run on the pump. I also have not yet built in support for controlling multiple pumps on the same serial connection.

## Usage

TODO: link to pump_connections.md

The following assumes you've followed the setup directions [found here](docs/pump_setup.md).

Additionally, you must add the repository folder to your path. Don't add the package folder ('+harvard') or any other sub-folders to your path, just the parent folder of the '+harvard' folder (i.e. this folder).

```matlab
p = harvard.pump.model_44('COM4');
p.setPumpDirection('infuse');
p.setPumpMode('pump');
p.setInfuseRate(1,'ml/min');	
p.start();
for i = 1:10
    pause(1)
    pumped_volume = p.volume_delivered_ml;
    fprintf('Volume Pumped: %g (ml)\n',pumped_volume);
end
p.stop();
```

## Dependencies



## Pump Models

* PHD 2000 - https://www.instechlabs.com/Support/manuals/PHD2000manual.pdf

