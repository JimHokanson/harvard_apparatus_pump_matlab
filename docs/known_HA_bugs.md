# Known Bugs in Harvard Apparatus programs

1. If the PHD 2000 is set to the Model 22 language, an incorrect command follows the Model 44 response format. The response starts with a LF instead of CR, and the pump address is returned. (JAH: 2017-08-07)