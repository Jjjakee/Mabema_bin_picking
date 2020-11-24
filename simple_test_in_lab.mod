MODULE Module1

    PERS tooldata tGripper :=[TRUE,[[0.000000001,0.000000002,100],[0.970381172,-0.000136996,0.001173549,-0.241576042]],[20,[0,0,400],[1,0,0,0],0,0,0]];
    
    CONST robtarget Home:=[[524.584,1228.139,1077.999],[0,1,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget Drop:=[[50,50,0],[0,1,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget Pickup:=[[-789,-280,921],[0.072,-0.0013,0.99,0.018],[-1,0,1,0],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];

    PROC main()
        !Use this function when connected to Mabema to get coordinates of scanned pieces
        GetCoordinates_And_Pick_Parts;
        
        ! For testing that Pick_Part -function works correctly
        !VAR pose poseBp:=[[9.70406,203.768,444.562],[-0.015035,0.706118,0.699947,-0.106047]];
        !Pick_Part(poseBp);
        !poseBp:=[[211,20,921],[0.072,-0.0013,0.99,0.018]];
        !Pick_Part(poseBp);
        !MoveJ Home,v500,z100,tGripper\WObj:=wobj0;
        
        
        
    ENDPROC

    PROC GetCoordinates_And_Pick_Parts()
        VAR SensActiveCom comBp;
        VAR string sBpIp := "203.0.113.1:7689";  
        VAR pose poseBp;
        
        IF (SensActiveInit(comBp)=TRUE AND SensActiveOpen(comBp,sBpIp,\nTimeout:=6)) THEN

            ! Check if the BP system is running.
            ! If it is stop it so we can change model
            IF (BpIsRunning(comBp) = TRUE) THEN
                IF (BpStop(comBp) = FALSE) THEN
                    TPWrite "Failed to stop BP system";
                    Stop;
                ENDIF
            ENDIF

            ! Set modelset
            IF (BpSetModelSet(comBp, "hylsycylinder") = FALSE) THEN   !TODO
                TPWrite "Failed to set modelset";
                Stop;
            ENDIF

            ! Start BP
            IF (BpStart(comBp) = FALSE) THEN
                TPWrite "Failed to start BP system";
                Stop;
            ENDIF
            
            !TODO Add delay here so the scan results work?
            
            ! Wait for scan to finish and then check if we found anything
            ! If we did. Go pick it up.
            IF BpIsScanFinished(comBp\WaitForResults\nTimeout:=60) THEN
                !
                WHILE BpObjectReady(comBp) DO
                    IF BpGetPick(comBp, poseBp) THEN

                        ! Advance the BP queue
                        IF BpNextPick(comBp) = FALSE THEN
                            TPWrite "Failed to advance the BP parts queue";
                            Stop;
                        ENDIF
                        
                        Stop;
                        ! Go pick up the found part
                        Pick_Part(poseBp);
                        
                    ENDIF
                ENDWHILE
                MoveJ Home,v500,z100,tGripper\WObj:=wobj0;
            ELSE
                TPWrite "Timeout while waiting for scan to finish";
                Stop;
            ENDIF
            
        ENDIF
        SensActiveClose comBp;
ENDPROC
    
    PROC Pick_Part(pose poseBp)

        ! Adjust the pickup location according to the pose from Mabema
        ! Add -1000 and -300 to the coordinates for the sake of not crashing if coordinates from mabema are failing
        Pickup.trans.x := poseBp.trans.x-1000;
        Pickup.trans.y := poseBp.trans.y-300;
        Pickup.trans.z := poseBp.trans.z;
        Pickup.rot := poseBp.rot;
        
        ! Move the robot to pickup the scanned part and drop it to the drop point
        MoveJ Home,v500,z100,tGripper\WObj:=wobj0;
        MoveJ Offs(Pickup,0,0,300),v500,fine,tGripper\WObj:=Workobject_6;
        MoveJ Pickup,v100,fine,tGripper\WObj:=Workobject_6;
        MoveJ Offs(Pickup,0,0,300),v100,fine,tGripper\WObj:=Workobject_6;
        MoveJ Offs(Drop,0,0,300),v500,fine,tGripper\WObj:=Workobject_4;
        MoveJ Drop,v100,fine,tGripper\WObj:=Workobject_4;
        MoveJ Offs(Drop,0,0,100),v100,fine,tGripper\WObj:=Workobject_4;

    ENDPROC
ENDMODULE